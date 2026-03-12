// reset_estates.js — wipe all estates, insert curated list
// Usage: node reset_estates.js
require('dotenv').config();
const mongoose = require('mongoose');

const EstateSchema = new mongoose.Schema({
    title: String, location: String, city: String, state: String,
    country: { type: String, default: 'India' }, category: String,
    heroImage: String, images: [String],
    roomImages: { type: Map, of: [String] },
    story: String,
    privileges: [{ label: String, detail: String }],
    facilities: [String],
    roomTypes: [{ name: String, price: Number, capacity: Number, desc: String }],
    basePrice: Number, rating: Number, reviewCount: Number,
    distanceFromCity: String,
    coordinates: { lat: Number, lng: Number },
    featured: Boolean,
    panoramaImage: String, videoId360: String, availableRooms: Number,
    gateCode: String, liftFloors: [Number], wingCode: String,
    wifiPwd: String, phone: String,
    checkInTime: { type: String, default: '14:00' },
    checkOutTime: { type: String, default: '12:00' },
}, { timestamps: true });

const Estate = mongoose.model('Estate', EstateSchema);

// ─────────────────────────────────────────────────────────────────────────────
// CURATED ESTATES — add new objects below, one by one
// ─────────────────────────────────────────────────────────────────────────────
const ESTATES = [
  {
    title: 'Taj Mahal Palace',
    location: 'Apollo Bunder, Colaba, Mumbai',
    city: 'Mumbai',
    state: 'Maharashtra',
    country: 'India',
    category: 'Heritage Palace',
    heroImage: 'https://lh3.googleusercontent.com/p/AF1QipMK1ySAtAw-z_kv8wBwEXvLg9wMPbv9dV4SdB4O=s1360-w1360-h1020',
    images: [
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweoxwilQpEBAn7CmB0XlR51bWPW5uqyFBlDToQCWPSUi7NUhJdmyc5FCQvLWR2WZMGGlGkZdQks5lBc4Q1DJK-1Zw9fzljAqszRyOwo3UFXoOhqXSKcz1MOTtLGMyxupKNdpqreE=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwerFs95HLSzbvp61wN8JXCVRVnnD0f6Z3FyOHxL4EzD_DUgGJ-A1fv3mf3tocQHdtbqvKSBTaeCTDuk2a6O-yxvEHH7kSlSsJl8liACw-WTLpweTrEJhEaTIRIbRCG_7Smg8N-ztFA=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweqjS2soYCdu3k_0Lc_OotA-d178AGO_yPH0IsmlToLRaSqBixomcwDgtd3nID19Q8YjpcXJqBgoWENOmp9obBcTB-whDvjHEcXFkIceyIpnA9W4MWI7Kw1Oe5tcffq_-s505y0=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwerVt2kz-lLR0ig-E08swJu0069y3uuHHwANgAx5Oo3105l4QW9JPqwHwiheO9OQpRFbqL3eXg_WpUU7zCKnx3YnFuIi3nhPu4hdEB_lvOJz9T4LFzuEHx6oThHrmIvRRkE0x4uh=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweq0f_E-ct694hYTPqeWsmmhLxL8Uhn1QSLinHPc_3o2AUbJLFF8FBUGGN5Z4G-l2HlhjMuMENOybLo3aSs3R1U6lrAWm8HegIFsTjKEVYKDFtNyGnuP91jiszYPekahZsAvRJG=s1360-w1360-h1020',
    ],
    story: "Built in 1903 by Jamshetji Tata — reportedly after he was refused entry to a European-only hotel — the Taj Mahal Palace is India's most iconic address, facing the Gateway of India arch built for King George V's 1911 visit. During the 26/11 terrorist attack of 2008, hotel staff herded 1,500 guests to safety; 11 staff members sacrificed their lives. The Taj is the only hotel in the world that opens its doors on the anniversary of that crisis.",
    privileges: [
      { label: 'Butler Service', detail: '24/7 personal butler on immediate call' },
      { label: 'Helipad Transfer', detail: 'Private helicopter transfers arranged' },
      { label: 'Royal Archive', detail: 'Exclusive viewing of historical artifacts and manuscripts' },
      { label: 'Vintage Cellar', detail: 'Personal sommelier and private cellar access' },
    ],
    facilities: [
      'Spa & Wellness', 'Rooftop Terrace', 'Helipad', 'Private Pool',
      'Concierge', 'Valet Parking', 'Fitness Centre', 'Heritage Library',
      'Banquet Hall', 'Vintage Wine Cellar',
    ],
    roomTypes: [
      { name: 'Maharaja Suite',   price: 425000, capacity: 2, desc: 'Grand royal suite with private courtyard, plunge pool and antique furnishings' },
      { name: 'Royal Chamber',    price: 212500, capacity: 2, desc: 'Heritage room with carved jali screens, marble bathrooms and city vistas' },
      { name: 'Heritage Deluxe',  price: 85000,  capacity: 2, desc: 'Period-decorated room with hand-painted frescoes and four-poster bed' },
      { name: 'Premier Room',     price: 51000,  capacity: 2, desc: 'Elegant room with silk furnishings, courtyard views and rainfall shower' },
    ],
    basePrice: 85000,
    rating: 5,
    reviewCount: 612,
    distanceFromCity: 'At Gateway of India',
    coordinates: { lat: 18.92, lng: 72.83 },
    featured: true,
    panoramaImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAweqBa6UDiQ3nUvE3BLmLij7NrpDwHcwt1o1sfmY3SlqdyOvx0tMjkJtc8bWLrsnUd-SQc4sJkd6Bbm9rabMgbkBlftffESIaxgBoaQH39rhdIjVjDKpfm-5EcQGFtp0_FxAMWusBGg=s1360-w1360-h1020',
    videoId360: 'FicdWhMgadQ',
    availableRooms: 10,
    gateCode: 'TMP2025',
    liftFloors: [],
    wingCode: 'TATA',
    wifiPwd: 'tajcolaba1903',
    phone: '+91 22 6665 3366',
    checkInTime: '14:00',
    checkOutTime: '12:00',
  },

  // ── PASTE NEXT ESTATE HERE ──────────────────────────────────────────────────
];

// ─────────────────────────────────────────────────────────────────────────────
async function run() {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected');

    const del = await Estate.deleteMany({});
    console.log(`🗑  Deleted ${del.deletedCount} existing estate(s)`);

    const inserted = await Estate.insertMany(ESTATES);
    console.log(`✅ Inserted ${inserted.length} estate(s):`);
    inserted.forEach(e => console.log(`   • ${e.title} (${e.city})`));

    await mongoose.disconnect();
    console.log('Done.');
}

run().catch(e => { console.error(e); process.exit(1); });
