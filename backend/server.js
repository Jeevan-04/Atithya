// =============================================================================
// आतिथ्य — Royal Hospitality Platform  —  Backend API
// Author : Jeevan Naidu <jeevannaidu04@gmail.com>
// GitHub : https://github.com/Jeevan-04
// License: Proprietary © 2025-2026 Jeevan Naidu. All rights reserved.
// -----------------------------------------------------------------------------
// Express + MongoDB Atlas REST API.
// Roles: guest | elite | manager | gate_staff | desk_staff | admin | phantom
//   phantom — super-admin disguised as desk_staff; phone+PIN authenticated;
//            all admin routes accessible but UI sees role:'desk_staff'.
// =============================================================================
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const fetch = require('node-fetch');

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://127.0.0.1:11434';
const AI_MODEL   = process.env.AI_MODEL   || 'smollm2:1.7b';

const app = express();

// ── CORS — allow localhost dev + GitHub Pages production ─────────────────────
const allowedOrigins = [
    'http://localhost:8080',
    'http://localhost:3000',
    'http://127.0.0.1:8080',
    'https://jeevan-04.github.io',
];
app.use(cors({
    origin: (origin, cb) => {
        // Allow requests with no origin (mobile apps, curl, Postman)
        if (!origin) return cb(null, true);
        if (allowedOrigins.includes(origin)) return cb(null, true);
        // Allow any localhost port during dev
        if (/^http:\/\/localhost:\d+$/.test(origin) ||
            /^http:\/\/127\.0\.0\.1:\d+$/.test(origin)) return cb(null, true);
        cb(null, true); // also allow unknown origins (public API) — remove if you want strict mode
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// ── MongoDB Connection ────────────────────────────────────────────────────────
mongoose.connect(process.env.MONGO_URI)
    .then(async () => {
        console.log('✅ MongoDB Atlas connected');
        await _patchBadEstateImages();
    })
    .catch(err => console.error('❌ MongoDB error:', err));

// One-time startup migration: replace non-CORS-friendly heroImage URLs with
// reliable Unsplash CDN URLs so the Flutter web app can load them from any origin.
async function _patchBadEstateImages() {
    try {
        const Estate = mongoose.models.Estate;
        if (!Estate) return;
        const safeUnsplash = [
            'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900',
            'https://images.unsplash.com/photo-1524230572899-a752b3835840?w=900',
            'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900',
            'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900',
            'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=900',
            'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900',
            'https://images.unsplash.com/photo-1590381105924-c72589b9ef3f?w=900',
            'https://images.unsplash.com/photo-1455543986359-f01defe57a73?w=900',
            'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900',
            'https://images.unsplash.com/photo-1448375240586-882707db888b?w=900',
        ];
        const isBad = (u) => !u ||
            u.includes('google.com/url') ||
            u.includes('tripadvisor') ||
            u.includes('cntraveler.com') ||
            u.includes('boundlessexplorism.com') ||
            (!u.startsWith('https://images.unsplash.com') &&
             !u.startsWith('https://plus.unsplash.com') &&
             !u.startsWith('https://lh3.googleusercontent.com') &&
             !u.startsWith('https://lh4.googleusercontent.com') &&
             !u.startsWith('https://lh5.googleusercontent.com') &&
             !u.startsWith('data:'));
        const estates = await Estate.find({}).select('title heroImage images').lean();
        let patched = 0;
        for (const [i, estate] of estates.entries()) {
            const updates = {};
            if (isBad(estate.heroImage)) {
                updates.heroImage = safeUnsplash[i % safeUnsplash.length];
            }
            const imgs = estate.images || [];
            const cleaned = imgs.map((u, j) =>
                isBad(u) ? safeUnsplash[(i + j + 1) % safeUnsplash.length] : u);
            if (cleaned.some((u, j) => u !== imgs[j])) updates.images = cleaned;
            if (Object.keys(updates).length) {
                await Estate.updateOne({ _id: estate._id }, { $set: updates });
                patched++;
            }
        }
        if (patched > 0) console.log(`✅ Patched ${patched} estate(s) with bad image URLs`);
    } catch (e) {
        console.error('Image patch error:', e.message);
    }
}

// ══════════════════════════════════════════════════════════════════════════════
// SCHEMAS
// ══════════════════════════════════════════════════════════════════════════════

const UserSchema = new mongoose.Schema({
    phoneNumber: { type: String, required: true, unique: true },
    // Roles: guest | elite | manager | gate_staff | desk_staff | admin | phantom
    //   phantom = disguised super-admin (looks like desk_staff to client)
    role: {
        type: String,
        enum: ['guest', 'elite', 'manager', 'gate_staff', 'desk_staff', 'admin', 'phantom'],
        default: 'elite',
    },
    name: { type: String, default: '' },
    email: { type: String, default: '' },
    estateId: { type: mongoose.Schema.Types.ObjectId, ref: 'Estate' }, // For staff
    pin: String,        // 4-digit PIN for staff login
    isActive: { type: Boolean, default: true },
    loyaltyPoints: { type: Number, default: 0 },
    memberTier: { type: String, enum: ['Bronze', 'Silver', 'Gold', 'Platinum', 'Royal'], default: 'Bronze' },
    // OTP verification
    otp: { type: String },
    otpExpiry: { type: Date },
    isVerified: { type: Boolean, default: false },
    // Dietary preference
    foodPreference: {
        type: String,
        enum: ['Non-Vegetarian', 'Vegetarian', 'Jain', 'Vegan', 'Halal', 'Gluten-Free', ''],
        default: '',
    },
    // Language & region
    language: { type: String, default: 'English' },
    currency: { type: String, default: 'INR' },
    // Notification preferences
    notificationPrefs: {
        bookingConfirm:   { type: Boolean, default: true },
        checkinReminder:  { type: Boolean, default: true },
        offerAlerts:      { type: Boolean, default: false },
        conciergeMsg:     { type: Boolean, default: true },
        newProperties:    { type: Boolean, default: false },
        loyaltyUpdates:   { type: Boolean, default: true },
    },
    // Privacy settings
    privacySettings: {
        dataAnalytics:      { type: Boolean, default: true },
        locationServices:   { type: Boolean, default: true },
        marketingEmails:    { type: Boolean, default: false },
        thirdPartySharing:  { type: Boolean, default: false },
    },
}, { timestamps: true });
const User = mongoose.model('User', UserSchema);

// ── Notification Schema ───────────────────────────────────────────────────────
const NotificationSchema = new mongoose.Schema({
    user:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    title: { type: String, required: true },
    body:  { type: String, required: true },
    type:  { type: String, enum: ['booking', 'checkin', 'offer', 'loyalty', 'concierge', 'system'], default: 'system' },
    read:  { type: Boolean, default: false },
    data:  { type: Object, default: {} },
}, { timestamps: true });
const Notification = mongoose.model('Notification', NotificationSchema);

// Helper to create a notification silently
async function pushNotification(userId, title, body, type = 'system', data = {}) {
    try { await Notification.create({ user: userId, title, body, type, data }); } catch(_) {}
}

const EstateSchema = new mongoose.Schema({
    title: String,
    location: String,
    city: String,
    state: String,
    country: { type: String, default: 'India' },
    category: String,
    heroImage: String,
    images: [String],
    roomImages: { type: Map, of: [String] }, // roomType -> images[]
    story: String,
    privileges: [{ label: String, detail: String }],
    facilities: [String],
    roomTypes: [{ name: String, price: Number, capacity: Number, desc: String }],
    basePrice: Number,
    rating: Number,
    reviewCount: Number,
    distanceFromCity: String,
    coordinates: { lat: Number, lng: Number },
    featured: Boolean,
    panoramaImage: String,
    videoId360: String,
    availableRooms: Number,
    // Access control
    gateCode: String,      // Staff gate PIN
    liftFloors: [Number],  // Accessible floors for guests
    wingCode: String,      // Wing/section code
    wifiPwd: String,
    phone: String,
    checkInTime: { type: String, default: '14:00' },
    checkOutTime: { type: String, default: '12:00' },
}, { timestamps: true });
const Estate = mongoose.model('Estate', EstateSchema);

const BookingSchema = new mongoose.Schema({
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    estate: { type: mongoose.Schema.Types.ObjectId, ref: 'Estate', required: true },
    checkInDate: { type: Date, required: true },
    checkOutDate: Date,
    guests: { type: Number, default: 2 },
    roomType: { type: String, default: 'Deluxe' },
    roomNumber: String,
    floorNumber: Number,
    specialRequest: String,
    addOns: [{ label: String, price: Number }],
    totalAmount: Number,
    status: {
        type: String,
        enum: ['Confirmed', 'Checked In', 'Checked Out', 'Cancelled'],
        default: 'Confirmed',
    },
    paymentId: String,
    // QR & Access
    qrToken: { type: String, unique: true, sparse: true },
    qrData: String,   // JSON string encoded into QR
    accessLog: [{ action: String, by: String, at: { type: Date, default: Date.now }, location: String }],
    vehicleNumber: String,   // For drive-in
    driveInApproved: { type: Boolean, default: false },
    reminderSent: {
        checkin24h: { type: Boolean, default: false },
        checkin1h:  { type: Boolean, default: false },
        checkout3d: { type: Boolean, default: false },
    },
    // Pre-arrival digital check-in form
    preArrivalForm: {
        submitted:     { type: Boolean, default: false },
        submittedAt:   Date,
        guestNames:    [String],      // Each guest's full name
        idNumbers:     [String],      // Govt ID numbers
        estimatedETA:  String,        // e.g. "15:30"
        flightOrTrain: String,
        dietaryNotes:  String,
        celebrationNote: String,      // anniversary / birthday message
        vehicleNumber: String,
        additionalRequests: String,
    },
}, { timestamps: true });
const Booking = mongoose.model('Booking', BookingSchema);

// ── Review Schema ─────────────────────────────────────────────────────────────
const ReviewSchema = new mongoose.Schema({
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true, unique: true },
    user:    { type: mongoose.Schema.Types.ObjectId, ref: 'User',    required: true },
    estate:  { type: mongoose.Schema.Types.ObjectId, ref: 'Estate',  required: true },
    rating:  { type: Number, min: 1, max: 5, required: true },
    title:   { type: String, default: '' },
    body:    { type: String, default: '' },
    tags:    { type: [String], default: [] }, // e.g. ['Impeccable Service', 'Breathtaking Views']
    isPublic: { type: Boolean, default: true },
}, { timestamps: true });
const Review = mongoose.model('Review', ReviewSchema);

// ── Room Status Schema (housekeeping board) ───────────────────────────────────
const RoomStatusSchema = new mongoose.Schema({
    estate:      { type: mongoose.Schema.Types.ObjectId, ref: 'Estate', required: true },
    roomNumber:  { type: String, required: true },
    floor:       { type: Number, default: 1 },
    wing:        { type: String, default: '' },
    status: {
        type: String,
        enum: ['Vacant', 'Occupied', 'Cleaning', 'Ready', 'Maintenance', 'Blocked'],
        default: 'Vacant',
    },
    assignedTo:  { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
    notes:       { type: String, default: '' },
    lastUpdated: { type: Date, default: Date.now },
});
const RoomStatus = mongoose.model('RoomStatus', RoomStatusSchema);

// ── Availability Block-out Schema (admin managed) ─────────────────────────────
const BlockoutSchema = new mongoose.Schema({
    estate:    { type: mongoose.Schema.Types.ObjectId, ref: 'Estate', required: true },
    startDate: { type: Date, required: true },
    endDate:   { type: Date, required: true },
    reason:    { type: String, default: '' }, // 'Maintenance', 'Private Event', 'Renovation'
    createdBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
}, { timestamps: true });
const Blockout = mongoose.model('Blockout', BlockoutSchema);

// Food Menu Schema
const FoodMenuSchema = new mongoose.Schema({
    estate: { type: mongoose.Schema.Types.ObjectId, ref: 'Estate', required: true },
    categories: [{
        name: String,
        icon: String,
        items: [{
            name: String,
            desc: String,
            price: Number,
            isVeg: Boolean,
            isSignature: Boolean,
            prepTime: Number, // minutes
            allergens: [String],
            image: String,
        }],
    }],
});
const FoodMenu = mongoose.model('FoodMenu', FoodMenuSchema);

// Food Order Schema
const FoodOrderSchema = new mongoose.Schema({
    booking: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking', required: true },
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    estate: { type: mongoose.Schema.Types.ObjectId, ref: 'Estate', required: true },
    items: [{ name: String, qty: Number, price: Number }],
    totalAmount: Number,
    deliveryType: { type: String, enum: ['Room Service', 'Restaurant', 'Pool Side', 'Garden Dining'], default: 'Room Service' },
    roomNumber: String,
    specialInstructions: String,
    status: {
        type: String,
        enum: ['Placed', 'Preparing', 'Ready', 'Delivered', 'Cancelled'],
        default: 'Placed',
    },
    eta: Number, // minutes
    orderedAt: { type: Date, default: Date.now },
}, { timestamps: true });
const FoodOrder = mongoose.model('FoodOrder', FoodOrderSchema);

// Trip Plan Schema — user-saved multi-stop journeys
const TripPlanSchema = new mongoose.Schema({
    user:     { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
    name:     { type: String, required: true },
    type:     { type: String, enum: ['custom', 'curated'], default: 'custom' },
    routeKey: String,   // links to PREDEFINED_ROUTES key for curated trips
    stops: [{
        city:      String,
        nights:    { type: Number, default: 2 },
        notes:     String,
        description: String,
        estateId:  { type: mongoose.Schema.Types.ObjectId, ref: 'Estate' },
        bookingId: { type: mongoose.Schema.Types.ObjectId, ref: 'Booking' },
    }],
    startDate: Date,
}, { timestamps: true });
const TripPlan = mongoose.model('TripPlan', TripPlanSchema);

// ══════════════════════════════════════════════════════════════════════════════
// MIDDLEWARE
// ══════════════════════════════════════════════════════════════════════════════

const auth = async (req, res, next) => {
    // Accept token from Authorization header OR ?token= query param (for CSV downloads)
    const token = req.headers.authorization?.split(' ')[1] || req.query.token;
    if (!token) return res.status(401).json({ error: 'No token' });
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = await User.findById(decoded.id);
        if (!req.user) return res.status(401).json({ error: 'User not found' });
        next();
    } catch (e) { res.status(401).json({ error: 'Invalid token' }); }
};

const staffOnly = (roles) => (req, res, next) => {
    // phantom always has the same access as admin
    const effectiveRole = req.user?.role === 'phantom' ? 'admin' : req.user?.role;
    if (!roles.includes(effectiveRole)) {
        return res.status(403).json({ error: `Access denied. Required roles: ${roles.join(', ')}` });
    }
    next();
};

const adminOnly = staffOnly(['admin']);

// ══════════════════════════════════════════════════════════════════════════════
// AUTH ROUTES
// ══════════════════════════════════════════════════════════════════════════════

// POST /api/auth/send-otp — generate & return OTP (in prod: send via SMS)
app.post('/api/auth/send-otp', async (req, res) => {
    try {
        const { phoneNumber } = req.body;
        if (!phoneNumber) return res.status(400).json({ error: 'Phone number required' });

        // Generate 6-digit OTP
        const otp = String(Math.floor(100000 + Math.random() * 900000));
        const otpExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 min

        let user = await User.findOne({ phoneNumber });
        const isNewUser = !user || !user.name;

        if (!user) {
            let autoRole = 'elite';
            if (phoneNumber === '0000000000') autoRole = 'admin';
            user = await User.create({ phoneNumber, role: autoRole, otp, otpExpiry });
        } else {
            user.otp = otp;
            user.otpExpiry = otpExpiry;
            await user.save();
        }

        // In production: send SMS via Twilio/Fast2SMS etc.
        // For dev: return OTP in response
        res.json({ success: true, isNewUser, debug_otp: otp });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// POST /api/auth/verify-otp — verify OTP, return JWT
app.post('/api/auth/verify-otp', async (req, res) => {
    try {
        const { phoneNumber, otp } = req.body;
        if (!phoneNumber || !otp) return res.status(400).json({ error: 'Phone and OTP required' });

        const user = await User.findOne({ phoneNumber });
        if (!user) return res.status(404).json({ error: 'User not found' });

        if (user.otp !== otp) return res.status(401).json({ error: 'Invalid OTP' });
        if (user.otpExpiry < new Date()) return res.status(401).json({ error: 'OTP expired' });

        // Clear OTP
        user.otp = undefined;
        user.otpExpiry = undefined;
        user.isVerified = true;
        await user.save();

        const isNewUser = !user.name || user.name === '';
        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });

        // ── Push sign-in / sign-up notification ─────────────────────────────
        const now = new Date();
        const timeStr = now.toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
        if (isNewUser) {
            await pushNotification(
                user._id,
                'Welcome to आतिथ्य 🏰',
                `Your royal journey begins. Account created on ${timeStr}. Explore our curated collection of heritage estates across India.`,
                'system',
                { event: 'signup', at: now.toISOString() }
            );
        } else {
            await pushNotification(
                user._id,
                'Signed in successfully',
                `Welcome back! You logged in on ${timeStr} from this device.`,
                'system',
                { event: 'login', at: now.toISOString() }
            );
        }

        res.json({ token, user, isNewUser });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// PUT /api/auth/profile — update profile + preferences
app.put('/api/auth/profile', auth, async (req, res) => {
    try {
        const { name, email, foodPreference, language, currency, notificationPrefs, privacySettings } = req.body;
        const user = await User.findById(req.user._id);
        if (!user) return res.status(404).json({ error: 'User not found' });
        if (name !== undefined)            user.name            = name;
        if (email !== undefined)           user.email           = email;
        if (foodPreference !== undefined)  user.foodPreference  = foodPreference;
        if (language !== undefined)        user.language        = language;
        if (currency !== undefined)        user.currency        = currency;
        if (notificationPrefs !== undefined) {
            const existing = user.notificationPrefs?.toObject ? user.notificationPrefs.toObject() : {};
            user.notificationPrefs = { ...existing, ...notificationPrefs };
        }
        if (privacySettings !== undefined) {
            const existing = user.privacySettings?.toObject ? user.privacySettings.toObject() : {};
            user.privacySettings = { ...existing, ...privacySettings };
        }
        await user.save();

        // Push profile-update notification for meaningful changes
        const changes = [];
        if (name !== undefined)           changes.push('name');
        if (email !== undefined)          changes.push('email');
        if (language !== undefined)       changes.push('language');
        if (currency !== undefined)       changes.push('currency');
        if (foodPreference !== undefined) changes.push('dining preference');
        if (changes.length > 0) {
            await pushNotification(
                user._id,
                'Profile Updated',
                `Your ${changes.join(', ')} ${changes.length > 1 ? 'were' : 'was'} updated successfully.`,
                'system',
                { event: 'profile_update', fields: changes }
            );
        }

        res.json({ success: true, user });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// NOTIFICATION ROUTES
// ══════════════════════════════════════════════════════════════════════════════

// POST /api/auth/logout — client should clear its token; we log the event
app.post('/api/auth/logout', auth, async (req, res) => {
    try {
        const timeStr = new Date().toLocaleString('en-IN', { dateStyle: 'medium', timeStyle: 'short' });
        await pushNotification(
            req.user._id,
            'Signed out',
            `You were signed out on ${timeStr}. Sign back in anytime to continue your royal journey.`,
            'system',
            { event: 'logout', at: new Date().toISOString() }
        );
        res.json({ success: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET /api/notifications
app.get('/api/notifications', auth, async (req, res) => {
    try {
        const notifications = await Notification.find({ user: req.user._id }).sort({ createdAt: -1 }).limit(60);
        const unreadCount   = await Notification.countDocuments({ user: req.user._id, read: false });
        res.json({ notifications, unreadCount });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/notifications/read-all
app.patch('/api/notifications/read-all', auth, async (req, res) => {
    try {
        await Notification.updateMany({ user: req.user._id, read: false }, { read: true });
        res.json({ ok: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/notifications/:id/read
app.patch('/api/notifications/:id/read', auth, async (req, res) => {
    try {
        await Notification.findOneAndUpdate({ _id: req.params.id, user: req.user._id }, { read: true });
        res.json({ ok: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/notifications
app.delete('/api/notifications', auth, async (req, res) => {
    try {
        await Notification.deleteMany({ user: req.user._id });
        res.json({ ok: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// POST /api/auth/login — legacy direct login (kept for staff + dev)
app.post('/api/auth/login', async (req, res) => {
    try {
        const { phoneNumber, pin } = req.body;
        if (!phoneNumber) return res.status(400).json({ error: 'Phone number required' });

        let user = await User.findOne({ phoneNumber }).populate('estateId', 'title location');

        // Auto-role assignment for special numbers
        let autoRole = 'elite';
        if (phoneNumber === '0000000000' || phoneNumber === 'admin') autoRole = 'admin';
        else if (phoneNumber === 'guest') autoRole = 'guest';

        if (!user) {
            user = await User.create({ phoneNumber, role: autoRole });
        }

        // PIN verification for staff roles (including phantom)
        if (['gate_staff', 'desk_staff', 'manager', 'phantom'].includes(user.role)) {
            if (!pin || user.pin !== pin) {
                return res.status(401).json({ error: 'Invalid PIN for staff login' });
            }
        }

        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });
        res.json({ token, user });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/api/auth/staff-login', async (req, res) => {
    try {
        const { phoneNumber, pin } = req.body;
        const user = await User.findOne({ phoneNumber }).populate('estateId', 'title location city');
        if (!user) return res.status(404).json({ error: 'Staff not found' });
        if (!['gate_staff', 'desk_staff', 'manager', 'admin', 'phantom'].includes(user.role)) {
            return res.status(403).json({ error: 'Not a staff account' });
        }
        if (user.pin !== pin) return res.status(401).json({ error: 'Invalid PIN' });

        const token = jwt.sign({ id: user._id }, process.env.JWT_SECRET, { expiresIn: '30d' });

        // Camouflage: phantom appears as desk_staff to the client
        const userObj = user.toObject();
        const maskedRole = userObj.role === 'phantom' ? 'desk_staff' : userObj.role;
        res.json({ token, user: { ...userObj, role: maskedRole, _isPhantom: userObj.role === 'phantom' } });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/api/auth/me', auth, async (req, res) => {
    const user = await User.findById(req.user._id).populate('estateId', 'title location city');
    const userObj = user.toObject();
    // Camouflage: phantom appears as desk_staff to the client
    const maskedRole = userObj.role === 'phantom' ? 'desk_staff' : userObj.role;
    res.json({ ...userObj, role: maskedRole, _isPhantom: userObj.role === 'phantom' });
});

// ══════════════════════════════════════════════════════════════════════════════
// LOCATION ROUTES
// ══════════════════════════════════════════════════════════════════════════════

app.get('/api/locations', async (req, res) => {
    const locations = await Estate.distinct('city');
    res.json(locations);
});

// Nearby estates (given lat/lng radius)
app.get('/api/estates/nearby', async (req, res) => {
    try {
        const { lat, lng, radius = 500 } = req.query; // radius in km
        if (!lat || !lng) return res.status(400).json({ error: 'lat & lng required' });

        const allEstates = await Estate.find({});
        const nearby = allEstates.filter(e => {
            if (!e.coordinates?.lat) return false;
            const dlat = (e.coordinates.lat - parseFloat(lat)) * Math.PI / 180;
            const dlng = (e.coordinates.lng - parseFloat(lng)) * Math.PI / 180;
            const a = Math.sin(dlat/2)**2 + Math.cos(parseFloat(lat)*Math.PI/180) * Math.cos(e.coordinates.lat*Math.PI/180) * Math.sin(dlng/2)**2;
            const dist = 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
            e._doc.distance = Math.round(dist);
            return dist <= parseFloat(radius);
        }).sort((a,b) => (a._doc.distance||999) - (b._doc.distance||999));

        res.json(nearby);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// ESTATE ROUTES
// ══════════════════════════════════════════════════════════════════════════════

app.get('/api/estates', async (req, res) => {
    try {
        const { city, category, maxPrice, minPrice, facilities, featured, sort, location, search } = req.query;
        const filter = {};
        if (city) filter.city = { $regex: city, $options: 'i' };
        if (location) filter.location = { $regex: location, $options: 'i' };
        if (category && category !== 'All') filter.category = category;
        if (maxPrice) filter.basePrice = { ...filter.basePrice, $lte: Number(maxPrice) };
        if (minPrice) filter.basePrice = { ...filter.basePrice, $gte: Number(minPrice) };
        if (featured === 'true') filter.featured = true;
        if (facilities) filter.facilities = { $all: facilities.split(',') };
        if (search) filter.$or = [
            { title: { $regex: search, $options: 'i' } },
            { city: { $regex: search, $options: 'i' } },
            { category: { $regex: search, $options: 'i' } },
        ];

        let sortQuery = {};
        if (sort === 'price_asc') sortQuery = { basePrice: 1 };
        else if (sort === 'price_desc') sortQuery = { basePrice: -1 };
        else if (sort === 'rating') sortQuery = { rating: -1 };
        else sortQuery = { featured: -1, rating: -1 };

        const estates = await Estate.find(filter).sort(sortQuery).limit(50);
        res.json(estates);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/api/estates/featured', async (req, res) => {
    const estates = await Estate.find({ featured: true }).limit(6);
    res.json(estates);
});

app.get('/api/estates/:id', async (req, res) => {
    const estate = await Estate.findById(req.params.id);
    if (!estate) return res.status(404).json({ error: 'Not found' });
    res.json(estate);
});

// Food menu for estate
app.get('/api/estates/:id/menu', async (req, res) => {
    try {
        const menu = await FoodMenu.findOne({ estate: req.params.id });
        res.json(menu || { categories: [] });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// BOOKING ROUTES
// ══════════════════════════════════════════════════════════════════════════════

app.get('/api/bookings/me', auth, async (req, res) => {
    const bookings = await Booking.find({ user: req.user._id })
        .populate('estate', 'title location images heroImage city checkInTime checkOutTime gateCode wifiPwd')
        .sort({ createdAt: -1 });
    res.json(bookings);
});

app.get('/api/bookings/:id', auth, async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id)
            .populate('estate', 'title location images heroImage city checkInTime checkOutTime gateCode liftFloors wifiPwd wingCode phone')
            .populate('user', 'phoneNumber name role');
        if (!booking) return res.status(404).json({ error: 'Not found' });
        // Only owner or staff can view
        const isOwner = booking.user._id.toString() === req.user._id.toString();
        const isStaff = ['admin', 'manager', 'gate_staff', 'desk_staff'].includes(req.user.role);
        if (!isOwner && !isStaff) return res.status(403).json({ error: 'Forbidden' });
        res.json(booking);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.post('/api/bookings', auth, async (req, res) => {
    try {

        const { estateId, checkInDate, checkOutDate, guests, roomType, specialRequest, addOns, totalAmount, vehicleNumber, tenderDetails } = req.body;

        // Generate unique QR token
        const qrToken = crypto.randomBytes(20).toString('hex');

        const estate = await Estate.findById(estateId);
        const checkIn = new Date(checkInDate);
        const checkOut = checkOutDate ? new Date(checkOutDate) : null;
        const nights = checkOut ? Math.ceil((checkOut - checkIn) / 86400000) : 1;

        // Auto-assign room number
        const roomNumber = `${Math.floor(100 + Math.random() * 800)}`;
        const floorNumber = parseInt(roomNumber[0]);

        const qrData = JSON.stringify({
            bookingRef: `ATH-${Date.now().toString(36).toUpperCase()}`,
            guest: req.user.phoneNumber,
            estate: estate?.title,
            estateId,
            checkIn: checkIn.toISOString().split('T')[0],
            checkOut: checkOut?.toISOString().split('T')[0],
            roomType,
            roomNumber,
            floorNumber,
            guests,
            token: qrToken,
        });

        const booking = await Booking.create({
            user: req.user._id,
            estate: estateId,
            checkInDate: checkIn,
            checkOutDate: checkOut,
            guests: guests || 2,
            roomType: roomType || 'Deluxe',
            roomNumber,
            floorNumber,
            specialRequest,
            addOns: addOns || [],
            totalAmount,
            tenderDetails: tenderDetails || 'Card',
            status: 'Confirmed',
            paymentId: `PAY_${Date.now()}_${Math.random().toString(36).substr(2,6).toUpperCase()}`,
            qrToken,
            qrData,
            vehicleNumber,
        });

        // Award loyalty points
        const points = Math.floor((totalAmount || 0) / 1000);
        await User.findByIdAndUpdate(req.user._id, {
            $inc: { loyaltyPoints: points },
        });
        // Update tier
        const user = await User.findById(req.user._id);
        let tier = 'Bronze';
        if (user.loyaltyPoints >= 50000) tier = 'Royal';
        else if (user.loyaltyPoints >= 20000) tier = 'Platinum';
        else if (user.loyaltyPoints >= 10000) tier = 'Gold';
        else if (user.loyaltyPoints >= 3000) tier = 'Silver';
        const prevTier = req.user.memberTier || 'Bronze';
        await User.findByIdAndUpdate(req.user._id, { memberTier: tier });

        await booking.populate('estate', 'title location city');

        // Booking confirmation notification with full details
        const checkInFmt = checkIn.toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'long', year: 'numeric' });
        const checkOutFmt = booking.checkOutDate
            ? new Date(booking.checkOutDate).toLocaleDateString('en-IN', { weekday: 'short', day: 'numeric', month: 'long' })
            : null;
        await pushNotification(
            req.user._id,
            '✓ Booking Confirmed',
            `Your ${nights}-night stay at ${estate?.title || 'the estate'} is confirmed.\nCheck-in: ${checkInFmt}${checkOutFmt ? '\nCheck-out: ' + checkOutFmt : ''}\nRoom ${booking.roomNumber} · ${roomType}\n+${points} Royal Points earned.`,
            'booking',
            { bookingId: booking._id, estateTitle: estate?.title, checkInDate: checkIn, roomType, points }
        );

        // Loyalty tier-up notification
        if (tier !== prevTier) {
            await pushNotification(
                req.user._id,
                `🎖️ Tier Upgrade — ${tier}`,
                `Congratulations! You've been elevated to ${tier} status. Enjoy exclusive privileges, priority check-ins, and curated offers available only to ${tier} members.`,
                'loyalty',
                { oldTier: prevTier, newTier: tier, totalPoints: user.loyaltyPoints }
            );
        }

        res.json(booking);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// PUT /api/bookings/:id/cancel — cancel with 20% fee
app.put('/api/bookings/:id/cancel', auth, async (req, res) => {
    try {
        const booking = await Booking.findById(req.params.id).populate('estate', 'title');
        if (!booking) return res.status(404).json({ error: 'Booking not found' });
        const isOwner = booking.user.toString() === req.user._id.toString();
        const isAdmin = req.user.role === 'admin';
        if (!isOwner && !isAdmin) return res.status(403).json({ error: 'Forbidden' });
        if (booking.status === 'Cancelled') return res.status(400).json({ error: 'Already cancelled' });
        if (booking.status === 'Checked In' || booking.status === 'Checked Out') {
            return res.status(400).json({ error: 'Cannot cancel an active or completed stay' });
        }
        const cancellationFee = Math.round((booking.totalAmount || 0) * 0.20);
        const refundAmount = (booking.totalAmount || 0) - cancellationFee;
        booking.status = 'Cancelled';
        booking.accessLog.push({
            action: 'Booking Cancelled',
            by: req.user.phoneNumber,
            at: new Date(),
            location: 'user_request',
        });
        await booking.save();
        await pushNotification(
            booking.user,
            'Booking Cancelled',
            `Your stay at ${booking.estate?.title || 'the estate'} has been cancelled. Refund \u20b9${refundAmount.toLocaleString('en-IN')} will be processed within 5-7 days.`,
            'booking',
            { bookingId: booking._id, refundAmount }
        );
        res.json({ success: true, cancellationFee, refundAmount, booking });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// QR & ACCESS CONTROL ROUTES
// ══════════════════════════════════════════════════════════════════════════════

// Verify QR token (gate, desk, lift scan)
app.post('/api/access/verify-qr', auth, async (req, res) => {
    try {
        const { qrToken: rawQr, location } = req.body;

        // The QR image encodes the full qrData JSON string.
        // Extract the raw hex token from it if it's JSON, else use as-is.
        let resolvedToken = rawQr;
        try {
            const parsed = JSON.parse(rawQr);
            if (parsed?.token) resolvedToken = parsed.token;
        } catch (_) { /* not JSON — use rawQr directly */ }

        const booking = await Booking.findOne({ qrToken: resolvedToken })
            .populate('user', 'phoneNumber name loyaltyPoints memberTier')
            .populate('estate', 'title location city liftFloors wingCode wifiPwd');

        if (!booking) return res.status(404).json({ error: 'Invalid QR — booking not found' });

        const now = new Date();
        const checkIn = new Date(booking.checkInDate);
        const checkOut = new Date(booking.checkOutDate || checkIn);
        checkOut.setDate(checkOut.getDate() + 1);

        if (now < checkIn) return res.status(400).json({
            error: 'Early arrival', status: 'early',
            allowed: false, checkIn: booking.checkInDate,
        });
        if (now > checkOut) return res.status(400).json({
            error: 'Booking expired', status: 'expired',
            allowed: false, checkOut: booking.checkOutDate,
        });
        if (booking.status === 'Cancelled') return res.status(400).json({
            error: 'Booking cancelled', allowed: false,
        });

        // Log access
        booking.accessLog.push({
            action: location || 'Gate Scan',
            by: req.user.phoneNumber,
            at: now,
            location: location || 'main_gate',
        });

        // Auto check-in on gate scan
        if (booking.status === 'Confirmed' && location === 'main_gate') {
            booking.status = 'Checked In';
        }
        await booking.save();

        res.json({
            allowed: true,
            booking: {
                _id: booking._id,
                status: booking.status,
                roomNumber: booking.roomNumber,
                roomType: booking.roomType,
                floorNumber: booking.floorNumber,
                checkInDate: booking.checkInDate,
                checkOutDate: booking.checkOutDate,
                guests: booking.guests,
                vehicleNumber: booking.vehicleNumber,
                driveInApproved: booking.driveInApproved,
                addOns: booking.addOns,
            },
            guest: booking.user,
            estate: booking.estate,
        });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// Drive-in approval
app.post('/api/access/drive-in/:bookingId', auth, staffOnly(['admin', 'manager', 'gate_staff']), async (req, res) => {
    try {
        const { vehicleNumber, approved } = req.body;
        const booking = await Booking.findByIdAndUpdate(
            req.params.bookingId,
            { vehicleNumber, driveInApproved: approved },
            { new: true }
        );
        if (booking) {
            booking.accessLog.push({ action: approved ? 'Drive-In Approved' : 'Drive-In Denied', by: req.user.phoneNumber, location: 'gate' });
            await booking.save();
        }
        res.json({ success: true, booking });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// Get all today's bookings for an estate (staff dash)
app.get('/api/bookings/estate/today', auth, staffOnly(['admin', 'manager', 'gate_staff', 'desk_staff']), async (req, res) => {
    try {
        const estateId = req.query.estateId || req.user.estateId;
        if (!estateId) return res.status(400).json({ error: 'estateId required' });

        const today = new Date();
        today.setHours(0,0,0,0);
        const tomorrow = new Date(today); tomorrow.setDate(today.getDate() + 1);

        const bookings = await Booking.find({
            estate: estateId,
            checkInDate: { $gte: today, $lt: tomorrow },
        })
        .populate('user', 'phoneNumber name memberTier')
        .sort({ checkInDate: 1 });

        res.json(bookings);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// Get all active (checked-in) bookings for estate
app.get('/api/bookings/estate/active', auth, staffOnly(['admin', 'manager', 'desk_staff']), async (req, res) => {
    try {
        const estateId = req.query.estateId || req.user.estateId;
        const bookings = await Booking.find({
            estate: estateId,
            status: 'Checked In',
        })
        .populate('user', 'phoneNumber name memberTier')
        .sort({ checkInDate: -1 });
        res.json(bookings);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// FOOD ORDER ROUTES
// ══════════════════════════════════════════════════════════════════════════════

app.post('/api/food/order', auth, async (req, res) => {
    try {
        const { bookingId, estateId, items, deliveryType, roomNumber, specialInstructions } = req.body;

        const total = items.reduce((s, i) => s + i.price * i.qty, 0);
        const eta = deliveryType === 'Room Service' ? 30 : 20;

        const order = await FoodOrder.create({
            booking: bookingId,
            user: req.user._id,
            estate: estateId,
            items,
            totalAmount: total,
            deliveryType: deliveryType || 'Room Service',
            roomNumber,
            specialInstructions,
            eta,
        });

        res.json(order);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/api/food/orders/me', auth, async (req, res) => {
    try {
        const orders = await FoodOrder.find({ user: req.user._id })
            .populate('estate', 'title')
            .sort({ orderedAt: -1 })
            .limit(20);
        res.json(orders);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.get('/api/food/orders/estate', auth, staffOnly(['admin', 'manager', 'desk_staff']), async (req, res) => {
    try {
        const estateId = req.query.estateId || req.user.estateId;
        const orders = await FoodOrder.find({ estate: estateId, status: { $in: ['Placed', 'Preparing'] } })
            .populate('user', 'phoneNumber name')
            .sort({ orderedAt: 1 });
        res.json(orders);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

app.patch('/api/food/orders/:id/status', auth, staffOnly(['admin', 'manager', 'desk_staff']), async (req, res) => {
    try {
        const order = await FoodOrder.findByIdAndUpdate(
            req.params.id,
            { status: req.body.status },
            { new: true }
        );
        res.json(order);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// PAYMENT ROUTE
// ══════════════════════════════════════════════════════════════════════════════

app.post('/api/payment', auth, async (req, res) => {
    const { amount, method } = req.body;
    const success = Math.random() > 0.05;
    await new Promise(r => setTimeout(r, 1200));
    if (success) {
        res.json({
            success: true,
            paymentId: `PAY_${Date.now()}_${Math.random().toString(36).substr(2, 8).toUpperCase()}`,
            amount, method,
            message: 'Payment authorized',
        });
    } else {
        res.status(402).json({ success: false, error: 'Payment declined. Please try another method.' });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN ROUTES
// ══════════════════════════════════════════════════════════════════════════════

app.get('/api/admin/system', auth, adminOnly, async (req, res) => {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [users, estates, bookings, orders] = await Promise.all([
        User.countDocuments(),
        Estate.countDocuments(),
        Booking.countDocuments(),
        FoodOrder.countDocuments(),
    ]);
    const revenue = await Booking.aggregate([
        { $match: { status: { $ne: 'Cancelled' } } },
        { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);
    const cancelledRevenue = await Booking.aggregate([
        { $match: { status: 'Cancelled' } },
        { $group: { _id: null, total: { $sum: '$totalAmount' } } }
    ]);
    const foodRevenue = await FoodOrder.aggregate([{ $group: { _id: null, total: { $sum: '$totalAmount' } } }]);
    const recentBookings = await Booking.find().populate('user estate').sort({ createdAt: -1 }).limit(5);
    const staffList = await User.find({ role: { $in: ['manager', 'gate_staff', 'desk_staff', 'phantom'] } }).populate('estateId', 'title');
    const staffSafe = staffList.map(s => {
        const obj = s.toObject();
        return { ...obj, role: obj.role === 'phantom' ? 'desk_staff' : obj.role, _isPhantom: obj.role === 'phantom' };
    });

    // Top estates this month by booking count
    const topEstatesMonth = await Booking.aggregate([
        { $match: { createdAt: { $gte: startOfMonth }, status: { $ne: 'Cancelled' } } },
        { $group: { _id: '$estate', count: { $sum: 1 }, revenue: { $sum: '$totalAmount' } } },
        { $sort: { count: -1 } },
        { $limit: 5 },
        { $lookup: { from: 'estates', localField: '_id', foreignField: '_id', as: 'estateInfo' } },
        { $unwind: { path: '$estateInfo', preserveNullAndEmpty: true } },
        { $project: { count: 1, revenue: 1, title: '$estateInfo.title', city: '$estateInfo.city', heroImage: '$estateInfo.heroImage' } }
    ]);

    // Monthly revenue for the last 6 months
    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    const monthlyRevenue = await Booking.aggregate([
        { $match: { createdAt: { $gte: sixMonthsAgo }, status: { $ne: 'Cancelled' } } },
        { $group: { _id: { year: { $year: '$createdAt' }, month: { $month: '$createdAt' } }, total: { $sum: '$totalAmount' }, count: { $sum: 1 } } },
        { $sort: { '_id.year': 1, '_id.month': 1 } }
    ]);

    res.json({
        users, estates, bookings, orders,
        revenue: revenue[0]?.total || 0,
        cancelledRevenue: cancelledRevenue[0]?.total || 0,
        refundedAmount: (cancelledRevenue[0]?.total || 0) * 0.8,
        foodRevenue: foodRevenue[0]?.total || 0,
        recentBookings, staffList: staffSafe,
        topEstatesMonth,
        monthlyRevenue,
    });
});

// GET /api/admin/bookings — paginated full booking list for admin dashboard
app.get('/api/admin/bookings', auth, adminOnly, async (req, res) => {
    try {
        const page  = parseInt(req.query.page  || '1');
        const limit = parseInt(req.query.limit || '30');
        const status = req.query.status; // optional filter
        const query = status ? { status } : {};
        const [total, rows] = await Promise.all([
            Booking.countDocuments(query),
            Booking.find(query)
                .populate('user', 'name phoneNumber')
                .populate('estate', 'title city heroImage')
                .sort({ createdAt: -1 })
                .skip((page - 1) * limit)
                .limit(limit)
                .lean(),
        ]);
        res.json({ total, page, limit, bookings: rows });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// Create / update staff account
app.post('/api/admin/staff', auth, adminOnly, async (req, res) => {
    try {
        const { phoneNumber, role, name, estateId, pin } = req.body;
        let staff = await User.findOne({ phoneNumber });
        if (staff) {
            staff.role = role; staff.name = name; staff.estateId = estateId; staff.pin = pin;
            await staff.save();
        } else {
            staff = await User.create({ phoneNumber, role, name, estateId, pin });
        }
        res.json(staff);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ── Phantom (Shadow Admin) management ────────────────────────────────────────
// POST /api/admin/phantom — create or update a phantom account
// Body: { phoneNumber, pin, name }
// The account is stored with role:'phantom', appears as desk_staff to clients.
app.post('/api/admin/phantom', auth, adminOnly, async (req, res) => {
    try {
        const { phoneNumber, pin, name } = req.body;
        if (!phoneNumber || !pin) return res.status(400).json({ error: 'phoneNumber and pin required' });
        let phantom = await User.findOne({ phoneNumber });
        if (phantom) {
            phantom.role = 'phantom'; phantom.pin = pin; if (name) phantom.name = name;
            await phantom.save();
        } else {
            phantom = await User.create({ phoneNumber, role: 'phantom', pin, name: name || 'Concierge' });
        }
        // Never expose role:phantom to client
        const obj = phantom.toObject();
        res.json({ ...obj, role: 'desk_staff', _isPhantom: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ── Admin Estate Management (CRUD) ────────────────────────────────────────────

// GET /api/admin/estates — all estates (admin view, with room count & status)
app.get('/api/admin/estates', auth, adminOnly, async (req, res) => {
    try {
        const { page = 1, limit = 20, city, search } = req.query;
        const filter = {};
        if (city) filter.city = city;
        if (search) filter.$or = [
            { title:    { $regex: search, $options: 'i' } },
            { location: { $regex: search, $options: 'i' } },
        ];
        const [estates, total] = await Promise.all([
            Estate.find(filter).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(Number(limit)),
            Estate.countDocuments(filter),
        ]);
        res.json({ estates, total, page: Number(page), pages: Math.ceil(total / limit) });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// POST /api/admin/estates — create a new estate
app.post('/api/admin/estates', auth, adminOnly, async (req, res) => {
    try {
        const estate = await Estate.create(req.body);
        res.status(201).json(estate);
    } catch(e) { res.status(400).json({ error: e.message }); }
});

// PUT /api/admin/estates/:id — update any estate field
app.put('/api/admin/estates/:id', auth, adminOnly, async (req, res) => {
    try {
        const estate = await Estate.findByIdAndUpdate(
            req.params.id, { $set: req.body }, { new: true, runValidators: true }
        );
        if (!estate) return res.status(404).json({ error: 'Estate not found' });
        res.json(estate);
    } catch(e) { res.status(400).json({ error: e.message }); }
});

// DELETE /api/admin/estates/:id — remove an estate (cascades bookings check)
app.delete('/api/admin/estates/:id', auth, adminOnly, async (req, res) => {
    try {
        const active = await Booking.countDocuments({
            estate: req.params.id,
            status: { $in: ['Confirmed', 'Checked In'] },
        });
        if (active > 0) {
            return res.status(409).json({
                error: `Cannot delete: ${active} active booking(s) exist. Cancel them first.`,
            });
        }
        await Estate.findByIdAndDelete(req.params.id);
        res.json({ ok: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
// HEALTH CHECK
// ══════════════════════════════════════════════════════════════════════════════
app.get('/ping', (req, res) => res.json({ status: 'ok', ts: new Date().toISOString(), version: '1.2.0' }));
app.get('/api/ping', (req, res) => res.json({ status: 'ok', ts: new Date().toISOString(), version: '1.2.0' }));

// ══════════════════════════════════════════════════════════════════════════════
// REVIEW ROUTES
// ══════════════════════════════════════════════════════════════════════════════

// POST /api/reviews — submit a review (must have a checked-out booking for this estate)
app.post('/api/reviews', auth, async (req, res) => {
    try {
        const { bookingId, rating, title, body, tags } = req.body;
        if (!bookingId || !rating) return res.status(400).json({ error: 'bookingId and rating required' });
        const booking = await Booking.findOne({ _id: bookingId, user: req.user._id });
        if (!booking) return res.status(404).json({ error: 'Booking not found' });
        if (!['Checked Out', 'Cancelled'].includes(booking.status)) {
            return res.status(400).json({ error: 'Can only review after checkout' });
        }
        const existing = await Review.findOne({ booking: bookingId });
        if (existing) return res.status(409).json({ error: 'Review already submitted' });

        const review = await Review.create({
            booking: bookingId,
            user: req.user._id,
            estate: booking.estate,
            rating, title, body,
            tags: tags || [],
        });

        // Update estate rating average
        const all = await Review.find({ estate: booking.estate });
        const avg = all.reduce((s, r) => s + r.rating, 0) / all.length;
        await Estate.findByIdAndUpdate(booking.estate, {
            rating: Math.round(avg * 10) / 10,
            reviewCount: all.length,
        });

        // Loyalty points for reviewing
        await User.findByIdAndUpdate(req.user._id, { $inc: { loyaltyPoints: 50 } });
        await pushNotification(req.user._id, '✍️ Review Received — 50 Points',
            'Thank you for sharing your experience. 50 Royal Points have been credited to your account.',
            'loyalty', { type: 'review_points' });

        res.status(201).json(review);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET /api/estates/:id/reviews — public reviews for an estate
app.get('/api/estates/:id/reviews', async (req, res) => {
    try {
        const reviews = await Review.find({ estate: req.params.id, isPublic: true })
            .populate('user', 'name')
            .sort({ createdAt: -1 })
            .limit(50);
        const avg = reviews.length
            ? Math.round(reviews.reduce((s, r) => s + r.rating, 0) / reviews.length * 10) / 10
            : 0;
        res.json({ reviews, avg, total: reviews.length });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET /api/bookings/:id/review — check if review exists for a booking
app.get('/api/bookings/:id/review', auth, async (req, res) => {
    try {
        const review = await Review.findOne({ booking: req.params.id, user: req.user._id });
        res.json(review || null);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
// PRE-ARRIVAL CHECK-IN FORM
// ══════════════════════════════════════════════════════════════════════════════

// PUT /api/bookings/:id/pre-arrival — submit pre-arrival form
app.put('/api/bookings/:id/pre-arrival', auth, async (req, res) => {
    try {
        const booking = await Booking.findOne({ _id: req.params.id, user: req.user._id });
        if (!booking) return res.status(404).json({ error: 'Booking not found' });
        if (booking.status !== 'Confirmed') return res.status(400).json({ error: 'Booking is not active' });

        const { guestNames, idNumbers, estimatedETA, flightOrTrain, dietaryNotes,
                celebrationNote, vehicleNumber, additionalRequests } = req.body;

        booking.preArrivalForm = {
            submitted: true, submittedAt: new Date(),
            guestNames, idNumbers, estimatedETA, flightOrTrain,
            dietaryNotes, celebrationNote, vehicleNumber, additionalRequests,
        };
        if (vehicleNumber) booking.vehicleNumber = vehicleNumber;
        await booking.save();

        await pushNotification(req.user._id, '✅ Pre-Arrival Form Submitted',
            `Your check-in details for ${new Date(booking.checkInDate).toLocaleDateString('en-IN')} have been received. The estate team is preparing your welcome.`,
            'checkin', { bookingId: booking._id });

        res.json({ ok: true, booking });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET /api/bookings/:id/pre-arrival — fetch pre-arrival form status
app.get('/api/bookings/:id/pre-arrival', auth, async (req, res) => {
    try {
        const booking = await Booking.findOne({ _id: req.params.id, user: req.user._id })
            .select('preArrivalForm status checkInDate estate')
            .populate('estate', 'title checkInTime');
        if (!booking) return res.status(404).json({ error: 'Booking not found' });
        res.json(booking);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
// ROOM STATUS BOARD (HOUSEKEEPING)
// ══════════════════════════════════════════════════════════════════════════════

// GET /api/rooms/status — get all rooms for staff's linked estate (or estate= query)
app.get('/api/rooms/status', auth, async (req, res) => {
    try {
        const effectiveRole = req.user.role === 'phantom' ? 'admin' : req.user.role;
        let estateId = req.query.estate;
        if (!estateId) {
            if (['manager', 'gate_staff', 'desk_staff', 'housekeeping', 'phantom'].includes(req.user.role)) {
                estateId = req.user.estateId;
            }
        }
        if (!estateId && effectiveRole !== 'admin') return res.status(400).json({ error: 'estateId required' });
        const filter = estateId ? { estate: estateId } : {};
        const rooms = await RoomStatus.find(filter).sort({ floor: 1, roomNumber: 1 });
        res.json(rooms);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// PATCH /api/rooms/status/:id — update room status
app.patch('/api/rooms/status/:id', auth, async (req, res) => {
    try {
        const { status, notes, assignedTo } = req.body;
        const room = await RoomStatus.findByIdAndUpdate(
            req.params.id,
            { status, notes, assignedTo, lastUpdated: new Date() },
            { new: true }
        );
        if (!room) return res.status(404).json({ error: 'Room not found' });
        res.json(room);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// POST /api/rooms/status — add room(s) to estate (admin/manager)
app.post('/api/rooms/status', auth, async (req, res) => {
    try {
        const { estateId, rooms } = req.body; // rooms: [{ roomNumber, floor, wing }]
        if (!estateId || !rooms?.length) return res.status(400).json({ error: 'estateId and rooms required' });
        const created = await Promise.all(rooms.map(r =>
            RoomStatus.findOneAndUpdate(
                { estate: estateId, roomNumber: r.roomNumber },
                { estate: estateId, ...r, lastUpdated: new Date() },
                { upsert: true, new: true }
            )
        ));
        res.json(created);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
// AVAILABILITY BLOCK-OUT (ADMIN)
// ══════════════════════════════════════════════════════════════════════════════

// GET /api/estates/:id/blockouts — public + admin; all block-outs for an estate
app.get('/api/estates/:id/blockouts', async (req, res) => {
    try {
        const blockouts = await Blockout.find({ estate: req.params.id }).sort({ startDate: 1 });
        res.json(blockouts);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// POST /api/estates/:id/blockouts — admin creates a block-out
app.post('/api/estates/:id/blockouts', auth, adminOnly, async (req, res) => {
    try {
        const { startDate, endDate, reason } = req.body;
        const blockout = await Blockout.create({
            estate: req.params.id, startDate, endDate, reason,
            createdBy: req.user._id,
        });
        res.status(201).json(blockout);
    } catch(e) { res.status(400).json({ error: e.message }); }
});

// DELETE /api/estates/:id/blockouts/:bid — remove a block-out
app.delete('/api/estates/:id/blockouts/:bid', auth, adminOnly, async (req, res) => {
    try {
        await Blockout.findOneAndDelete({ _id: req.params.bid, estate: req.params.id });
        res.json({ ok: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
// ADMIN CSV EXPORT
// ══════════════════════════════════════════════════════════════════════════════

// GET /api/admin/export/bookings.csv
app.get('/api/admin/export/bookings.csv', auth, adminOnly, async (req, res) => {
    try {
        const { from, to, status } = req.query;
        const filter = {};
        if (from || to) filter.checkInDate = {};
        if (from) filter.checkInDate.$gte = new Date(from);
        if (to)   filter.checkInDate.$lte = new Date(to);
        if (status) filter.status = status;

        const bookings = await Booking.find(filter)
            .populate('user', 'name phoneNumber')
            .populate('estate', 'title city')
            .sort({ createdAt: -1 })
            .limit(5000)
            .lean();

        const header = 'Booking ID,Estate,City,Guest Name,Phone,Room Type,Check-In,Check-Out,Nights,Guests,Amount,Status,Payment ID\n';
        const rows = bookings.map(b => {
            const nights = b.checkOutDate
                ? Math.round((new Date(b.checkOutDate) - new Date(b.checkInDate)) / 86400000)
                : 1;
            return [
                b._id, b.estate?.title || '', b.estate?.city || '',
                b.user?.name || '', b.user?.phoneNumber || '',
                b.roomType || '', b.checkInDate?.toISOString()?.split('T')[0] || '',
                b.checkOutDate?.toISOString()?.split('T')[0] || '',
                nights, b.guests || 1, b.totalAmount || 0,
                b.status || '', b.paymentId || '',
            ].map(v => `"${String(v).replace(/"/g, '""')}"`).join(',');
        });

        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename="atithya_bookings.csv"');
        res.send(header + rows.join('\n'));
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET /api/admin/export/users.csv
app.get('/api/admin/export/users.csv', auth, adminOnly, async (req, res) => {
    try {
        const users = await User.find({ role: { $ne: 'phantom' } })
            .sort({ createdAt: -1 }).limit(10000).lean();
        const header = 'Phone,Name,Email,Role,Tier,Loyalty Points,Food Pref,Language,Verified,Joined\n';
        const rows = users.map(u => [
            u.phoneNumber, u.name || '', u.email || '', u.role,
            u.memberTier || 'Bronze', u.loyaltyPoints || 0,
            u.foodPreference || '', u.language || 'English',
            u.isVerified ? 'Yes' : 'No',
            u.createdAt?.toISOString()?.split('T')[0] || '',
        ].map(v => `"${String(v).replace(/"/g, '""')}"`).join(','));
        res.setHeader('Content-Type', 'text/csv');
        res.setHeader('Content-Disposition', 'attachment; filename="atithya_users.csv"');
        res.send(header + rows.join('\n'));
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
// LOYALTY — redeem points
// ══════════════════════════════════════════════════════════════════════════════

// POST /api/loyalty/redeem — redeem points for a discount on next booking
app.post('/api/loyalty/redeem', auth, async (req, res) => {
    try {
        const { points } = req.body; // multiples of 100 = ₹1 each
        if (!points || points < 100) return res.status(400).json({ error: 'Minimum 100 points to redeem' });
        const user = await User.findById(req.user._id);
        if ((user.loyaltyPoints || 0) < points) return res.status(400).json({ error: 'Insufficient points' });
        const discount = Math.floor(points / 100); // ₹1 per 100 pts
        user.loyaltyPoints -= points;
        await user.save();
        // Return a discount coupon code (simplified — no code table needed)
        const code = `ROYAL${points}P${Date.now().toString(36).toUpperCase()}`;
        res.json({ ok: true, discount, code, pointsUsed: points, remaining: user.loyaltyPoints });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET /api/loyalty/tiers — tier structure reference
app.get('/api/loyalty/tiers', (req, res) => {
    res.json([
        { tier: 'Bronze',   minPoints: 0,    perks: ['Priority booking', 'Welcome gift'],                        color: '#CD7F32' },
        { tier: 'Silver',   minPoints: 500,  perks: ['Early check-in', '5% room discount'],                     color: '#C0C0C0' },
        { tier: 'Gold',     minPoints: 1500, perks: ['Free room upgrade', '10% discount', 'Spa credit ₹2000'],   color: '#FFD700' },
        { tier: 'Platinum', minPoints: 4000, perks: ['Suite priority', '15% discount', 'Airport transfer'],      color: '#E5E4E2' },
        { tier: 'Royal',    minPoints: 10000, perks: ['All Platinum + personal butler', 'Exclusive estates', '20% discount'], color: '#9B7DEC' },
    ]);
});

// ══════════════════════════════════════════════════════════════════════════════
if (process.env.NODE_ENV !== 'production') {
    // DEV: upgrade a user to elite for testing
    app.post('/api/auth/upgrade-to-elite', async (req, res) => {
        const { phoneNumber } = req.body;
        await User.updateOne({ phoneNumber }, { role: 'elite' });
        res.json({ ok: true });
    });
}

// ── User Saved Journeys ───────────────────────────────────────────────────────

// POST  /api/trips  — save a journey plan
app.post('/api/trips', auth, async (req, res) => {
    try {
        const { name, stops, type = 'custom', routeKey, startDate } = req.body;
        if (!name || !stops?.length) {
            return res.status(400).json({ error: 'name and stops are required' });
        }
        const trip = await TripPlan.create({
            user: req.user._id, name, stops, type, routeKey, startDate,
        });
        res.json(trip);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// GET   /api/trips/my  — list all trips for authenticated user
app.get('/api/trips/my', auth, async (req, res) => {
    try {
        const trips = await TripPlan.find({ user: req.user._id })
            .populate('stops.estateId', 'title city heroImage basePrice')
            .populate('stops.bookingId', 'status checkInDate checkOutDate')
            .sort({ createdAt: -1 });
        res.json(trips);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// DELETE /api/trips/:id  — delete a trip
app.delete('/api/trips/:id', auth, async (req, res) => {
    try {
        await TripPlan.findOneAndDelete({ _id: req.params.id, user: req.user._id });
        res.json({ ok: true });
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// PUT    /api/trips/:id/stop/:idx  — link an estate/booking to a stop
app.put('/api/trips/:id/stop/:idx', auth, async (req, res) => {
    try {
        const { estateId, bookingId } = req.body;
        const trip = await TripPlan.findOne({ _id: req.params.id, user: req.user._id });
        if (!trip) return res.status(404).json({ error: 'Trip not found' });
        const idx = parseInt(req.params.idx, 10);
        if (trip.stops[idx]) {
            if (estateId !== undefined) trip.stops[idx].estateId = estateId || null;
            if (bookingId !== undefined) trip.stops[idx].bookingId = bookingId || null;
            await trip.save();
        }
        res.json(trip);
    } catch(e) { res.status(500).json({ error: e.message }); }
});

// ══════════════════════════════════════════════════════════════════════════════
const PREDEFINED_ROUTES = [
  {
    key: 'char_dham',
    name: '4 Dham Yatra',
    tagline: 'The sacred circuit of Uttarakhand',
    icon: '🙏',
    duration: '14-16 days',
    stops: [
      { city: 'Yamunotri', nights: 2, description: 'Source of Yamuna river' },
      { city: 'Gangotri', nights: 2, description: 'Origin of the Ganges' },
      { city: 'Kedarnath', nights: 3, description: 'Shiva\'s high-altitude abode' },
      { city: 'Badrinath', nights: 3, description: 'Vishnu\'s Himalayan sanctuary' },
    ],
  },
  {
    key: 'golden_triangle',
    name: 'Golden Triangle',
    tagline: 'India\'s most iconic cultural circuit',
    icon: '🏛️',
    duration: '7-9 days',
    stops: [
      { city: 'Delhi', nights: 2, description: 'The imperial capital' },
      { city: 'Agra', nights: 2, description: 'City of the Taj Mahal' },
      { city: 'Jaipur', nights: 3, description: 'The Pink City of palaces' },
    ],
  },
  {
    key: 'royal_rajasthan',
    name: 'Royal Rajasthan',
    tagline: 'Palaces, forts & desert royalty',
    icon: '👑',
    duration: '10-12 days',
    stops: [
      { city: 'Jaipur', nights: 3, description: 'Amber Fort & City Palace' },
      { city: 'Jodhpur', nights: 2, description: 'The Blue City & Mehrangarh' },
      { city: 'Jaisalmer', nights: 2, description: 'Golden Fort in the Thar Desert' },
      { city: 'Udaipur', nights: 3, description: 'City of Lakes & Lake Palace' },
    ],
  },
  {
    key: 'kerala_backwaters',
    name: 'Kerala Odyssey',
    tagline: 'God\'s Own Country — beaches, hills & backwaters',
    icon: '🌴',
    duration: '8-10 days',
    stops: [
      { city: 'Wayanad', nights: 2, description: 'Misty highlands & tribal culture' },
      { city: 'Alleppey', nights: 3, description: 'Houseboats on tranquil backwaters' },
      { city: 'Goa', nights: 3, description: 'Sun-drenched beaches & heritage' },
    ],
  },
  {
    key: 'himalayan_escape',
    name: 'Himalayan Escape',
    tagline: 'Snow peaks, valleys & mountain serenity',
    icon: '🏔️',
    duration: '9-11 days',
    stops: [
      { city: 'Manali', nights: 4, description: 'Valley of the Gods & Rohtang Pass' },
      { city: 'Gulmarg', nights: 4, description: 'The Meadow of Flowers in Kashmir' },
    ],
  },
];

// GET predefined routes (with matching estates per stop from MongoDB)
app.get('/api/trips/routes', async (req, res) => {
  try {
    const cities = [...new Set(PREDEFINED_ROUTES.flatMap(r => r.stops.map(s => s.city)))];
    const estates = await Estate.find({ city: { $in: cities } })
      .select('_id title city category basePrice rating heroImage roomTypes')
      .lean();

    const estatesByCity = {};
    estates.forEach(e => {
      if (!estatesByCity[e.city]) estatesByCity[e.city] = [];
      estatesByCity[e.city].push(e);
    });

    const enriched = PREDEFINED_ROUTES.map(route => ({
      ...route,
      stops: route.stops.map(stop => ({
        ...stop,
        estates: (estatesByCity[stop.city] || []).slice(0, 3),
      })),
    }));

    res.json(enriched);
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// POST save a custom trip plan (no auth required for planning preview)
app.post('/api/trips/plan', async (req, res) => {
  try {
    const { name, stops } = req.body;
    if (!name || !stops?.length) {
      return res.status(400).json({ error: 'Trip name and stops are required' });
    }
    res.json({ ok: true, trip: { name, stops, createdAt: new Date() } });
  } catch(e) {
    res.status(500).json({ error: e.message });
  }
});

// ══════════════════════════════════════════════════════════════════════════════
// DISCOVER FEED  (dynamic homepage content from MongoDB)
// ══════════════════════════════════════════════════════════════════════════════

app.get('/api/discover/feed', async (req, res) => {
    try {
        const allEstates = await Estate.find({})
            .select('title city category basePrice rating roomTypes facilities featured heroImage')
            .limit(50);

        // Derive room type highlights from estate data
        const roomTypeMap = {};
        allEstates.forEach(e => {
            (e.roomTypes || []).forEach(rt => {
                if (!roomTypeMap[rt.name]) {
                    roomTypeMap[rt.name] = {
                        name: rt.name,
                        from: `₹${Math.round((rt.price || 0) / 1000)}K`,
                        estateTitle: e.title,
                        estateId: e._id,
                    };
                }
            });
        });
        const suiteHighlights = Object.values(roomTypeMap).slice(0, 5);

        // Derive unique experiences from estate facilities
        const expSet = new Set();
        const experiences = [];
        allEstates.forEach(e => {
            (e.facilities || []).forEach(f => {
                if (!expSet.has(f) && experiences.length < 8) {
                    expSet.add(f);
                    experiences.push({ label: f, estateId: e._id });
                }
            });
        });

        // City stats sorted by estate count
        const cityMap = {};
        allEstates.forEach(e => {
            if (!cityMap[e.city]) cityMap[e.city] = { city: e.city, count: 0, minPrice: Infinity, heroImage: e.heroImage || '' };
            cityMap[e.city].count++;
            if (e.basePrice < cityMap[e.city].minPrice) cityMap[e.city].minPrice = e.basePrice;
        });
        const cities = Object.values(cityMap).sort((a, b) => b.count - a.count).slice(0, 9);

        res.json({ suiteHighlights, experiences, cities });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ══════════════════════════════════════════════════════════════════════════════
// AI CONCIERGE  (SmallLM via Ollama)
// ══════════════════════════════════════════════════════════════════════════════

const CONCIERGE_SYSTEM = `You are Rajendra, the Royal AI Concierge of Atithya — India's most prestigious palace retreat platform. You speak with the refined grace of a seasoned royal household butler. You know every estate in detail: palaces in Udaipur, Jaipur, Jodhpur; beach villas in Goa; treehouses in Wayanad; desert camps in Jaisalmer; mountain lodges in Manali and Gulmarg; heritage houseboat in Alleppey; Nizam palace in Hyderabad. You help guests with booking suggestions, experiences, amenities, food ordering, check-in, room access via QR, and curated itineraries. Keep responses elegant, concise (max 3 sentences), and always offer a next step. Never say you are an AI — you are Rajendra.`;

app.post('/api/concierge/chat', async (req, res) => {
    try {
        const { message, history = [], estateContext } = req.body;
        if (!message?.trim()) return res.status(400).json({ error: 'Message required' });

        const contextPart = estateContext ? `\nCurrent estate context: ${estateContext}` : '';
        let conversationText = `${CONCIERGE_SYSTEM}${contextPart}\n\n`;
        (history || []).slice(-6).forEach(h => {
            conversationText += h.isUser ? `Guest: ${h.text}\n` : `Rajendra: ${h.text}\n`;
        });
        conversationText += `Guest: ${message}\nRajendra:`;

        let reply = null;
        try {
            const ollamaRes = await fetch(`${OLLAMA_URL}/api/generate`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    model: AI_MODEL,
                    prompt: conversationText,
                    stream: false,
                    options: { temperature: 0.7, num_predict: 120, stop: ['Guest:', '\n\n'] },
                }),
                signal: AbortSignal.timeout(15000),
            });
            if (ollamaRes.ok) {
                const data = await ollamaRes.json();
                reply = data.response?.trim();
            }
        } catch (_) { /* Ollama unavailable — use curated fallback */ }

        if (!reply) {
            const msg = message.toLowerCase();
            if (msg.includes('book') || msg.includes('reserve') || msg.includes('stay'))
                reply = 'I shall arrange a bespoke stay for you. Our finest palaces are available from ₹38,000 per night — Mewar Palace Retreat commands the most exquisite lake views. Shall I proceed with your preferred dates?';
            else if (msg.includes('food') || msg.includes('din') || msg.includes('meal') || msg.includes('eat'))
                reply = 'The Royal Kitchen awaits your command. I can arrange private dining on the heritage terrace, pool-side service, or an in-room Maharaja Thali. What is your pleasure?';
            else if (msg.includes('spa') || msg.includes('ayur') || msg.includes('massage'))
                reply = 'The Ananda Sanctum offers a 3-hour Royal Ritual — warm sesame Abhyanga, gold-infused Mukha Lepa, and Shirodhara under candlelight. Shall I place a reservation for this evening?';
            else if (msg.includes('helico') || msg.includes('transfer') || msg.includes('travel'))
                reply = 'Our Bell 407 helicopter can bring you directly to the palace helipad — Jaipur to Udaipur takes under 45 minutes at 12,000 feet. Shall I hold a provisionally confirmed slot?';
            else if (msg.includes('check') || msg.includes('qr') || msg.includes('room') || msg.includes('access'))
                reply = 'Your QR access pass is ready in the Itineraries tab. Present it at the gate, main desk, lift, or room door — our staff will welcome you as royalty.';
            else if (msg.includes('price') || msg.includes('cost') || msg.includes('rate'))
                reply = 'Our Deluxe rooms begin at ₹28,000 per night, suites from ₹75,000, and the legendary Maharaja Suite commands ₹2.80L. All rates include a personal butler and heritage breakfast.';
            else
                reply = 'Your request has been received with utmost care. Allow me to connect you with our senior concierge team who will attend personally within moments. May I suggest exploring our Discover collection?';
        }

        res.json({ reply, model: 'Rajendra (SmallLM)' });
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

// ── Profile Update ────────────────────────────────────────────────────────────
app.patch('/api/auth/profile', auth, async (req, res) => {
    try {
        const { name } = req.body;
        const user = await User.findByIdAndUpdate(req.user._id, { name }, { new: true });
        res.json(user);
    } catch(e) {
        res.status(500).json({ error: e.message });
    }
});

const PORT = process.env.PORT || 5555;
app.listen(PORT, () => console.log(`🏰 Atithya server running on port ${PORT}`));

// ══════════════════════════════════════════════════════════════════════════════
// SCHEDULED JOBS — run every hour, safe to call repeatedly
// ══════════════════════════════════════════════════════════════════════════════

async function runReminders() {
    try {
        const BookingModel = Booking;
        const now = new Date();

        // ── 24-hour check-in reminder ─────────────────────────────────────────
        const in24hStart = new Date(now.getTime() + 23 * 60 * 60 * 1000);
        const in24hEnd   = new Date(now.getTime() + 25 * 60 * 60 * 1000);
        const upcoming = await BookingModel.find({
            checkInDate: { $gte: in24hStart, $lte: in24hEnd },
            status: 'Confirmed',
            'reminderSent.checkin24h': { $ne: true },
        }).populate('estate', 'title location city').lean();

        for (const b of upcoming) {
            const checkInStr = new Date(b.checkInDate).toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' });
            await pushNotification(
                b.user,
                '🏰 Check-in Tomorrow',
                `Your stay at ${b.estate?.title || 'the estate'} begins tomorrow (${checkInStr}). Room ${b.roomNumber} is being prepared. Please have your booking QR ready at the gate.`,
                'checkin',
                { bookingId: b._id, checkInDate: b.checkInDate }
            );
            await BookingModel.findByIdAndUpdate(b._id, { $set: { 'reminderSent.checkin24h': true } });
        }

        // ── 1-hour check-in reminder ──────────────────────────────────────────
        const in1hStart = new Date(now.getTime() + 55 * 60 * 1000);
        const in1hEnd   = new Date(now.getTime() + 65 * 60 * 1000);
        const imminent = await BookingModel.find({
            checkInDate: { $gte: in1hStart, $lte: in1hEnd },
            status: 'Confirmed',
            'reminderSent.checkin1h': { $ne: true },
        }).populate('estate', 'title location').lean();

        for (const b of imminent) {
            await pushNotification(
                b.user,
                '⏰ Arriving in ~1 Hour',
                `Welcome! Your estate ${b.estate?.title || ''} is expecting you shortly. Show your QR code at the main entrance for seamless check-in.`,
                'checkin',
                { bookingId: b._id }
            );
            await BookingModel.findByIdAndUpdate(b._id, { $set: { 'reminderSent.checkin1h': true } });
        }

        // ── 3-day checkout reminder ───────────────────────────────────────────
        const co3dStart = new Date(now.getTime() + 71 * 60 * 60 * 1000);
        const co3dEnd   = new Date(now.getTime() + 73 * 60 * 60 * 1000);
        const checkingOut = await BookingModel.find({
            checkOutDate: { $gte: co3dStart, $lte: co3dEnd },
            status: { $in: ['Confirmed', 'Checked In'] },
            'reminderSent.checkout3d': { $ne: true },
        }).populate('estate', 'title').lean();

        for (const b of checkingOut) {
            const checkOutStr = new Date(b.checkOutDate).toLocaleDateString('en-IN', { weekday: 'long', day: 'numeric', month: 'long' });
            await pushNotification(
                b.user,
                'Checkout Reminder',
                `Your stay at ${b.estate?.title || 'the estate'} concludes on ${checkOutStr}. We hope your experience has been extraordinary. Our butler will assist with luggage.`,
                'booking',
                { bookingId: b._id }
            );
            await BookingModel.findByIdAndUpdate(b._id, { $set: { 'reminderSent.checkout3d': true } });
        }

        if (upcoming.length + imminent.length + checkingOut.length > 0)
            console.log(`📬 Reminders sent — checkin24h:${upcoming.length} checkin1h:${imminent.length} checkout3d:${checkingOut.length}`);
    } catch(e) {
        console.error('Reminder scheduler error:', e.message);
    }
}

// Run immediately on startup (after DB connects), then every 30 min
mongoose.connection.once('open', () => {
    runReminders();
    setInterval(runReminders, 30 * 60 * 1000);
});


