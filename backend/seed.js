require('dotenv').config();
const mongoose = require('mongoose');

// ── Schemas (inline for seed) ─────────────────────────────────────────────────
const EstateSchema = new mongoose.Schema({
    title: String, location: String, city: String, state: String,
    country: { type: String, default: 'India' }, category: String,
    heroImage: String, images: [String], roomImages: { type: Map, of: [String] },
    story: String, privileges: [{ label: String, detail: String }], facilities: [String],
    roomTypes: [{ name: String, price: Number, capacity: Number, desc: String }],
    basePrice: Number, rating: Number, reviewCount: Number, distanceFromCity: String,
    coordinates: { lat: Number, lng: Number }, featured: Boolean,
    panoramaImage: String, videoId360: String, availableRooms: Number,
    gateCode: String, liftFloors: [Number], wingCode: String, wifiPwd: String,
    phone: String, checkInTime: { type: String, default: '14:00' }, checkOutTime: { type: String, default: '12:00' },
}, { timestamps: true });
const Estate = mongoose.model('Estate', EstateSchema);

const UserSchema = new mongoose.Schema({
    phoneNumber: { type: String, unique: true }, role: String,
    name: String, estateId: mongoose.Schema.Types.ObjectId,
    pin: String, isActive: { type: Boolean, default: true },
    loyaltyPoints: { type: Number, default: 0 }, memberTier: { type: String, default: 'Bronze' },
}, { timestamps: true });
const User = mongoose.model('User', UserSchema);

const FoodMenuSchema = new mongoose.Schema({
    estate: { type: mongoose.Schema.Types.ObjectId, ref: 'Estate' },
    categories: [{ name: String, icon: String, items: [{ name: String, desc: String, price: Number, isVeg: Boolean, isSignature: Boolean, prepTime: Number, allergens: [String], image: String }] }],
});
const FoodMenu = mongoose.model('FoodMenu', FoodMenuSchema);

// ── Image Banks ───────────────────────────────────────────────────────────────
const palaceA = [
    'https://images.unsplash.com/photo-1524230572899-a752b3835840?w=900',
    'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=900',
    'https://images.unsplash.com/photo-1551882547-ff40c4fe799f?w=900',
    'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=900',
    'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=900',
];
const palaceB = [
    'https://images.unsplash.com/photo-1566737236500-c8ac43014a93?w=900',
    'https://images.unsplash.com/photo-1571896349842-33c89424de2d?w=900',
    'https://images.unsplash.com/photo-1455587734955-081b22074882?w=900',
    'https://images.unsplash.com/photo-1578683010236-d716f9a3f461?w=900',
    'https://images.unsplash.com/photo-1571003123894-1f0594d2b5d9?w=900',
];
const palaceC = [
    'https://images.unsplash.com/photo-1590381105924-c72589b9ef3f?w=900',
    'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=900',
    'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=900',
    'https://images.unsplash.com/photo-1606402179428-a57976d71fa4?w=900',
    'https://images.unsplash.com/photo-1464983308776-3c7215084895?w=900',
];
const beachA = [
    'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?w=900',
    'https://images.unsplash.com/photo-1471922694854-ff1b63b20054?w=900',
    'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=900',
    'https://images.unsplash.com/photo-1499793983690-e29da59ef1c2?w=900',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900',
];
const beachB = [
    'https://images.unsplash.com/photo-1455543986359-f01defe57a73?w=900',
    'https://images.unsplash.com/photo-1433086966358-54859d0ed716?w=900',
    'https://images.unsplash.com/photo-1502685104226-ee32379fefbe?w=900',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=900',
    'https://images.unsplash.com/photo-1501691223387-dd0500403074?w=900',
];
const mountainA = [
    'https://images.unsplash.com/photo-1464822759023-fed622ff2c3b?w=900',
    'https://images.unsplash.com/photo-1472214103451-9374bd1c798e?w=900',
    'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=900',
    'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1b?w=900',
    'https://images.unsplash.com/photo-1526481280693-3bfa7568e0f3?w=900',
];
const mountainB = [
    'https://images.unsplash.com/photo-1519681393784-d120267933ba?w=900',
    'https://images.unsplash.com/photo-1486870591958-9b9d0d1dda99?w=900',
    'https://images.unsplash.com/photo-1501854140801-50d01698950b?w=900',
    'https://images.unsplash.com/photo-1510798831971-661eb04b3739?w=900',
    'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=900',
];
const forestA = [
    'https://images.unsplash.com/photo-1448375240586-882707db888b?w=900',
    'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=900',
    'https://images.unsplash.com/photo-1511497584788-876760111969?w=900',
    'https://images.unsplash.com/photo-1542401886-65d6c61db217?w=900',
    'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=900',
];

// ── Privilege Templates ────────────────────────────────────────────────────────
const palacePriv = [
    { label: 'Butler Service', detail: '24/7 personal butler on immediate call' },
    { label: 'Helipad Transfer', detail: 'Private helicopter transfers arranged' },
    { label: 'Royal Archive', detail: 'Exclusive viewing of historical artifacts and manuscripts' },
    { label: 'Vintage Cellar', detail: 'Personal sommelier and private cellar access' },
];
const heritagePriv = [
    { label: 'Heritage Walk', detail: 'Private guided tour of the estate grounds & history' },
    { label: 'Polo Experience', detail: 'Introductory polo session with estate mounts' },
    { label: 'Astronomy Night', detail: 'Private stargazing with in-residence astronomer' },
    { label: 'Butler Service', detail: '24/7 personal butler on immediate call' },
];
const beachPriv = [
    { label: 'Private Beach', detail: 'Exclusive section of beach reserved for your stay' },
    { label: 'Sunset Sail', detail: 'Private catamaran sunset cruise arranged daily' },
    { label: 'Dive Concierge', detail: 'Certified instructors & private reef access' },
    { label: 'Butler Service', detail: 'Dedicated beach butler for the duration' },
];
const mountainPriv = [
    { label: 'Alpine Trek', detail: 'Expert Himalayan guide for high-altitude treks' },
    { label: 'Stargazing', detail: 'Private astronomer and telescope sessions nightly' },
    { label: 'Bonfire Dining', detail: 'Private hilltop bonfire dinner arrangements' },
    { label: 'Alpine Spa', detail: 'Himalayan salt and herb body treatments' },
];
const forestPriv = [
    { label: 'Dawn Safari', detail: 'Private 6-seat jeep safari at dawn & dusk' },
    { label: 'Naturalist Guide', detail: 'Expert ecologist for forest walks and bird hides' },
    { label: 'Canopy Dinner', detail: 'Exclusive treetop dining with bonfire under the stars' },
    { label: 'Butler Service', detail: '24/7 forest butler trained in wildlife protocols' },
];

// ── Facility Sets ──────────────────────────────────────────────────────────────
const palaceFacilities = ['Spa & Wellness', 'Rooftop Terrace', 'Helipad', 'Private Pool', 'Concierge', 'Valet Parking', 'Fitness Centre', 'Heritage Library', 'Banquet Hall', 'Vintage Wine Cellar'];
const beachFacilities  = ['Private Beach', 'Infinity Pool', 'Water Sports Centre', 'Sunset Bar', 'Spa & Wellness', 'Dive Centre', 'Beach Butler', 'Seafood Restaurant', 'Sundeck Lounge', 'Fitness Centre'];
const mountainFacilities = ['Alpine Spa', 'Heated Indoor Pool', 'Trek Concierge', 'High-Altitude Observatory', 'Library Lounge', 'Altitude Dining', 'Fitness Centre', 'Bonfire Terrace', 'Yoga Pavilion', 'Ski Room'];
const forestFacilities  = ['Safari Lounge', 'Naturalist Desk', 'Infinity Pool', 'Open-Air Bar', 'Forest Spa', 'Bird Watching Hide', 'Jeep Fleet', 'Campfire Terrace', 'Yoga Deck', 'Treetop Dining'];
const heritageBeachFacilities = ['Colonial Library', 'Infinity Pool', 'Private Jetty', 'Heritage Bar', 'Spa & Wellness', 'Sundeck', 'Seafood Restaurant', 'Butler Service', 'Bicycle Hire', 'Boat Excursions'];

// ── Room Type Factories ────────────────────────────────────────────────────────
function palaceRooms(b) { return [
    { name: 'Maharaja Suite',  price: b*5,   capacity: 2, desc: 'Grand royal suite with private courtyard, plunge pool and antique furnishings' },
    { name: 'Royal Chamber',   price: b*2.5, capacity: 2, desc: 'Heritage room with carved jali screens, marble bathrooms and city vistas' },
    { name: 'Heritage Deluxe', price: b,     capacity: 2, desc: 'Period-decorated room with hand-painted frescoes and four-poster bed' },
    { name: 'Premier Room',    price: b*0.6, capacity: 2, desc: 'Elegant room with silk furnishings, courtyard views and rainfall shower' },
]; }
function beachRooms(b) { return [
    { name: 'Ocean Villa',       price: b*3.5, capacity: 2, desc: 'Standalone beachfront villa with private infinity pool and butler' },
    { name: 'Clifftop Suite',    price: b*2,   capacity: 2, desc: 'Elevated suite with panoramic ocean vistas and private sun terrace' },
    { name: 'Garden Pool Room',  price: b,     capacity: 2, desc: 'Private plunge pool nestled in tropical garden with outdoor shower' },
    { name: 'Sea View Deluxe',   price: b*0.6, capacity: 2, desc: 'Bright room with floor-to-ceiling windows facing the sea' },
]; }
function mountainRooms(b) { return [
    { name: 'Peak Suite',        price: b*4,   capacity: 2, desc: 'Panoramic valley suite with roll-top bath, private fireplace and cedar deck' },
    { name: 'Forest Loft',       price: b*2,   capacity: 2, desc: 'Elevated loft with handwoven textiles and unobstructed mountain panorama' },
    { name: 'Alpine Deluxe',     price: b,     capacity: 2, desc: 'Warm alpine room with stone fireplace and locally crafted furniture' },
    { name: 'Heritage Room',     price: b*0.6, capacity: 2, desc: 'Colonial-era room with vintage prints, fireplace and valley views' },
]; }
function forestRooms(b) { return [
    { name: 'Jungle Villa',      price: b*4,   capacity: 2, desc: 'Private raised villa inside primary jungle with wildlife observation deck' },
    { name: 'Lake Suite',        price: b*2,   capacity: 2, desc: 'Overwater or lakeside suite with private deck and naturalist concierge' },
    { name: 'Forest Cottage',    price: b,     capacity: 2, desc: 'Stone-and-teak cottage with en-suite rainforest garden shower' },
    { name: 'Treetop Room',      price: b*0.6, capacity: 2, desc: 'Elevated room among forest canopy with panoramic views of reserve' },
]; }

// ── The 56 Estates ────────────────────────────────────────────────────────────
const estates = [

  { title: 'Taj Exotica Resort & Spa', location: 'Radhanagar Beach, Havelock Island', city: 'Havelock Island', state: 'Andaman & Nicobar', category: 'Beach Villa',
    heroImage: beachA[0], images: beachA, panoramaImage: beachB[0], videoId360: 'biv1vAHRLPQ',
    story: 'Built on Radhanagar Beach — voted Asia\'s Best Beach by TIME Magazine — the Taj Exotica occupies land once reserved for the British Commissioner\'s residence when the Andamans served as the Empire\'s most feared penal colony from 1858. The archipelago was the site of the first Indian National Army provisional government under Subhas Chandra Bose in 1943. Today the Presidential Villas sit on shores that remember both colonial oppression and the first breath of Indian sovereignty.',
    privileges: beachPriv, facilities: beachFacilities, roomTypes: beachRooms(45000),
    basePrice: 45000, rating: 4.9, reviewCount: 312, distanceFromCity: '2 km from ferry terminal',
    coordinates: { lat: 11.99, lng: 92.98 }, featured: true, availableRooms: 18,
    gateCode: 'TAJ2025', wingCode: 'EXOTICA', wifiPwd: 'radhanagar', phone: '+91 316 228 2525' },

  { title: 'The Gateway Hotel Grand Bay', location: 'Beach Rd, Rushikonda, Visakhapatnam', city: 'Visakhapatnam', state: 'Andhra Pradesh', category: 'Heritage Palace',
    heroImage: palaceA[2], images: palaceA, panoramaImage: palaceB[0], videoId360: 'biv1vAHRLPQ',
    story: 'Originally the Madras Presidency\'s Circuit House in 1923, the Grand Bay wing overlooks the Bay of Bengal where the INS Circars naval base has stood since 1952. Vizag was home to the Kalinga dynasty before the Dutch East India Company established South India\'s first European trading post here in 1605. The Presidential Suites occupy the original Collector\'s chambers, their floors still bearing colonial-era Athangudi tilework.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(18000),
    basePrice: 18000, rating: 4.6, reviewCount: 278, distanceFromCity: '14 km from city centre',
    coordinates: { lat: 17.69, lng: 83.22 }, featured: false, availableRooms: 24,
    gateCode: 'GBH2025', wingCode: 'GRANDBAY', wifiPwd: 'vizagbay', phone: '+91 891 666 0101' },

  { title: 'Vivanta Tawang', location: 'Tawang Valley, Kameng District', city: 'Tawang', state: 'Arunachal Pradesh', category: 'Mountain Retreat',
    heroImage: mountainA[2], images: mountainA, panoramaImage: mountainB[0], videoId360: 'TjzRiLnGqGU',
    story: 'Perched at 10,000 feet in the shadow of the 400-year-old Tawang Monastery — the second-largest Buddhist monastery in the world and birthplace of the 6th Dalai Lama — Vivanta occupies a site strategically vital in the 1962 Sino-Indian War. The Executive Suites directly face the Tawang valley where Tibetan monks have walked unchanged since the 17th century.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(25000),
    basePrice: 25000, rating: 4.7, reviewCount: 189, distanceFromCity: '3 km from Tawang Town',
    coordinates: { lat: 27.58, lng: 91.86 }, featured: true, availableRooms: 20,
    gateCode: 'VVT2025', wingCode: 'HIMALAYA', wifiPwd: 'tawangzen', phone: '+91 3794 222 111' },

  { title: 'Radisson Blu Guwahati', location: 'Noonmati, Guwahati', city: 'Guwahati', state: 'Assam', category: 'Heritage Palace',
    heroImage: palaceB[0], images: palaceB, panoramaImage: palaceA[0], videoId360: 'biv1vAHRLPQ',
    story: 'The Elite Presidential Wing stands on the former site of the Ahom kingdom\'s river-trading post on the Brahmaputra, a civilisation that for 600 years fought off Mughal invasions 17 times without a single surrender. The basement cuts through layers of sediment carrying pottery shards from the Kamakhya Temple pilgrim trail — one of the 51 Shakti Peethas that has attracted devotees since the 8th century.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(12000),
    basePrice: 12000, rating: 4.5, reviewCount: 201, distanceFromCity: '8 km from Kamakhya',
    coordinates: { lat: 26.14, lng: 91.74 }, featured: false, availableRooms: 30,
    gateCode: 'RBG2025', wingCode: 'BRAHMA', wifiPwd: 'brahmaputra', phone: '+91 361 666 0101' },

  { title: 'Sultan Palace', location: 'Bailey Road, Patna', city: 'Patna', state: 'Bihar', category: 'Heritage Palace',
    heroImage: palaceC[0], images: palaceC, panoramaImage: palaceA[1], videoId360: 'biv1vAHRLPQ',
    story: 'Built on Pataliputra, the capital of the Maurya Empire where Chandragupta Maurya (321 BCE) and Ashoka the Great once ruled the largest empire in Indian history. Patna was the intellectual centre of ancient India and the property sits near Golghar — the British granary built in 1786 after the Great Famine of 1770.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(10000),
    basePrice: 10000, rating: 4.3, reviewCount: 145, distanceFromCity: '5 km from Patna Junction',
    coordinates: { lat: 25.59, lng: 85.14 }, featured: false, availableRooms: 22,
    gateCode: 'SUL2025', wingCode: 'MAURYA', wifiPwd: 'pataliputra', phone: '+91 612 222 0101' },

  { title: 'The Oberoi Sukhvilas', location: 'Chandimandir, New Chandigarh', city: 'Chandigarh', state: 'Chandigarh', category: 'Heritage Palace',
    heroImage: palaceA[0], images: palaceA, panoramaImage: palaceB[1], videoId360: 'biv1vAHRLPQ',
    story: 'The Kohinoor Villa with its private pool occupies 8,000 sq ft within a 30-acre forest reserve at the foothills of the Shivalik range, on land originally commissioned as a hunting retreat for the Patiala royal house. Chandigarh was designed by Le Corbusier in 1952 for the 500,000 refugees of Partition who lost Lahore to Pakistan.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(45000),
    basePrice: 45000, rating: 4.9, reviewCount: 356, distanceFromCity: '22 km from Sector 17',
    coordinates: { lat: 30.73, lng: 76.78 }, featured: true, availableRooms: 14,
    gateCode: 'OBK2025', wingCode: 'KOHINOOR', wifiPwd: 'sukhvilas', phone: '+91 172 502 0001' },

  { title: 'Mayfair Lake Resort', location: 'Naya Raipur, Chhattisgarh', city: 'Raipur', state: 'Chhattisgarh', category: 'Forest Retreat',
    heroImage: forestA[0], images: forestA, panoramaImage: forestA[2], videoId360: 'biv1vAHRLPQ',
    story: 'Set on the fringes of Barnawapara Wildlife Sanctuary, the Presidential Royal Villa overlooks a man-made lake built on tribal Gondi lands where the 13th-century Ratanpur kingdom once flourished. Chhattisgarh holds 44% of India\'s total forest, and the resort sits at the junction of four tiger corridors.',
    privileges: forestPriv, facilities: forestFacilities, roomTypes: forestRooms(12000),
    basePrice: 12000, rating: 4.5, reviewCount: 167, distanceFromCity: '18 km from Raipur centre',
    coordinates: { lat: 21.25, lng: 81.63 }, featured: false, availableRooms: 16,
    gateCode: 'MFL2025', wingCode: 'LAKESIDE', wifiPwd: 'barnawapara', phone: '+91 771 403 3000' },

  { title: 'The Fern Seaside Luxury Villas', location: 'Nagoa Beach, Diu', city: 'Diu', state: 'Dadra, Nagar Haveli & Diu', category: 'Beach Villa',
    heroImage: beachB[0], images: beachB, panoramaImage: beachA[1], videoId360: 'aSQn3l53NeM',
    story: 'The Elite Beachfront Villas at Nagoa Beach occupy the coastline where the Ottoman Admiral Piri Reis attempted his naval siege of Portuguese Diu in 1538 — the Battle of Diu that determined European dominance of the Indian Ocean for the next 200 years. Diu remained a Portuguese enclave until December 1961 when India\'s military operation liberated it in 36 hours.',
    privileges: beachPriv, facilities: beachFacilities, roomTypes: beachRooms(15000),
    basePrice: 15000, rating: 4.6, reviewCount: 198, distanceFromCity: '10 km from Diu Fort',
    coordinates: { lat: 20.71, lng: 70.58 }, featured: false, availableRooms: 20,
    gateCode: 'FSV2025', wingCode: 'NAGOA', wifiPwd: 'diubeach', phone: '+91 287 252 1001' },

  { title: 'The Leela Palace New Delhi', location: 'Diplomatic Enclave, Chanakyapuri', city: 'New Delhi', state: 'Delhi', category: 'Heritage Palace',
    heroImage: palaceA[1], images: palaceA, panoramaImage: palaceC[0], videoId360: 'biv1vAHRLPQ',
    story: 'The Maharaja Suite\'s bulletproof windows face the Diplomatic Enclave built on the former hunting grounds of the Delhi Sultans of the 13th century — the very terrain where Timur the Lame camped before sacking Delhi in 1398. The hotel stands in Chanakyapuri, named after Chanakya, the original Arthashastra statecraft genius who masterminded the Maurya Empire.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(90000),
    basePrice: 90000, rating: 5.0, reviewCount: 521, distanceFromCity: '6 km from India Gate',
    coordinates: { lat: 28.60, lng: 77.18 }, featured: true, availableRooms: 10,
    gateCode: 'LPD2025', wingCode: 'MAHARAJA', wifiPwd: 'leeladelhi', phone: '+91 11 3933 1234' },

  { title: 'The Leela Goa', location: 'Mobor, Cavelossim, South Goa', city: 'South Goa', state: 'Goa', category: 'Beach Villa',
    heroImage: beachA[1], images: beachA, panoramaImage: beachB[2], videoId360: 'aSQn3l53NeM',
    story: 'The Royal Villas with private plunge pools sit on land first documented in a Portuguese land grant of 1510, provided after Afonso de Albuquerque\'s conquest that made Goa the Lisbon of the East for 451 years. The Leela\'s lagoon was once the private fishing waters of the Saraswat Brahmin community who had fled the Inquisition, returning only after Liberation in 1961.',
    privileges: beachPriv, facilities: beachFacilities, roomTypes: beachRooms(55000),
    basePrice: 55000, rating: 4.9, reviewCount: 487, distanceFromCity: '45 km from Panaji',
    coordinates: { lat: 15.13, lng: 73.98 }, featured: true, availableRooms: 16,
    gateCode: 'LGO2025', wingCode: 'ROYALVILLA', wifiPwd: 'goaleela', phone: '+91 832 662 1234' },

  { title: 'Lakshmi Vilas Palace', location: 'Maharaja Fateh Singh Museum Rd, Vadodara', city: 'Vadodara', state: 'Gujarat', category: 'Heritage Palace',
    heroImage: palaceB[1], images: palaceB, panoramaImage: palaceA[2], videoId360: 'biv1vAHRLPQ',
    story: 'Built in 1890 by Maharaja Sayajirao Gaekwad III at a cost of Rs 6 million — four times the size of Buckingham Palace — Lakshmi Vilas remains the world\'s largest private residence still occupied by royalty. Sayajirao III provided the scholarship that funded Dr. B.R. Ambedkar\'s education at Columbia University, weaving social justice into these very stones.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(30000),
    basePrice: 30000, rating: 4.8, reviewCount: 342, distanceFromCity: '4 km from Vadodara station',
    coordinates: { lat: 22.31, lng: 73.18 }, featured: true, availableRooms: 18,
    gateCode: 'LVP2025', wingCode: 'GAEKWAD', wifiPwd: 'vadodarapalace', phone: '+91 265 242 4141' },

  { title: 'ITC Narmada Ahmedabad', location: 'Judges Bungalow Cross Rd, Ahmedabad', city: 'Ahmedabad', state: 'Gujarat', category: 'Heritage Palace',
    heroImage: palaceC[1], images: palaceC, panoramaImage: palaceB[2], videoId360: 'biv1vAHRLPQ',
    story: 'The Karnavati Khasa Royal Heritage Wing honours ancient Karnavati — the original name of Ahmedabad before Sultan Ahmad Shah I founded the walled city in 1411 CE. The hotel sits 2 km from where Mahatma Gandhi launched the Dandi Salt March on 12 March 1930, the act of civil disobedience that changed the course of a nation.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(35000),
    basePrice: 35000, rating: 4.7, reviewCount: 298, distanceFromCity: '8 km from Sabarmati Ashram',
    coordinates: { lat: 23.02, lng: 72.57 }, featured: false, availableRooms: 22,
    gateCode: 'ITN2025', wingCode: 'KARNAVATI', wifiPwd: 'ahmedabadgold', phone: '+91 79 6660 4444' },

  { title: 'ITC Grand Bharat', location: 'Delhi-Jaipur Highway, Gurugram', city: 'Gurugram', state: 'Haryana', category: 'Heritage Palace',
    heroImage: palaceA[3], images: palaceA, panoramaImage: palaceB[3], videoId360: 'biv1vAHRLPQ',
    story: 'The Presidential Villas with private helipad are set across 104 acres on the Aravalli foothills — terrain over which the Pandava armies marched to Kurukshetra as described in the Mahabharata. The property\'s golf course cuts through limestone outcrops dating to the Precambrian era (600 million years old).',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(75000),
    basePrice: 75000, rating: 4.9, reviewCount: 401, distanceFromCity: '32 km from Connaught Place',
    coordinates: { lat: 28.46, lng: 77.03 }, featured: true, availableRooms: 12,
    gateCode: 'IGB2025', wingCode: 'BHARAT', wifiPwd: 'grandbharat', phone: '+91 124 280 9999' },

  { title: 'Wildflower Hall', location: 'Chharabra, Shimla Hills', city: 'Shimla', state: 'Himachal Pradesh', category: 'Mountain Retreat',
    heroImage: mountainA[0], images: mountainA, panoramaImage: mountainB[1], videoId360: 'TjzRiLnGqGU',
    story: 'Lord Kitchener\'s former Royal Estate at 8,250 ft was built in 1905 as the private weekend retreat of Field Marshal Lord Kitchener during a period when Shimla served as the summer capital of British India (1864-1947). Kitchener plotted his strategic rivalry with Lord Curzon here, reshaping the entire chain of command of the British Indian Army.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(45000),
    basePrice: 45000, rating: 4.9, reviewCount: 389, distanceFromCity: '11 km from Shimla town',
    coordinates: { lat: 31.10, lng: 77.17 }, featured: true, availableRooms: 14,
    gateCode: 'WFH2025', wingCode: 'KITCHENER', wifiPwd: 'shimlawilds', phone: '+91 177 264 8585' },

  { title: 'The LaLiT Grand Palace', location: 'Gupkar Road, Srinagar', city: 'Srinagar', state: 'Jammu & Kashmir', category: 'Heritage Palace',
    heroImage: palaceB[2], images: palaceB, panoramaImage: palaceA[3], videoId360: 'biv1vAHRLPQ',
    story: 'Built in 1910 as Maharaja Pratap Singh\'s personal summer residence on the banks of Dal Lake, the palace witnessed the signing of every critical document of 20th-century Kashmiri sovereignty. It was here in 1947 that Maharaja Hari Singh signed the Instrument of Accession to India — a document that changed the history of South Asia forever.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(40000),
    basePrice: 40000, rating: 4.8, reviewCount: 367, distanceFromCity: '3 km from Hazratbal',
    coordinates: { lat: 34.08, lng: 74.79 }, featured: true, availableRooms: 16,
    gateCode: 'LGP2025', wingCode: 'DALLAKE', wifiPwd: 'srinagarpalace', phone: '+91 194 250 1001' },

  { title: 'The United Club', location: 'Jubilee Park, Jamshedpur', city: 'Jamshedpur', state: 'Jharkhand', category: 'Heritage Palace',
    heroImage: palaceC[2], images: palaceC, panoramaImage: palaceB[4], videoId360: 'biv1vAHRLPQ',
    story: 'The original 1908 club constructed by Jamsetji Nusserwanji Tata when he founded Jamshedpur — Asia\'s first planned industrial city. The United Club was the social centre of the only privately-owned planned city in the world; the original membership register contains signatures of every Indian Prime Minister since Independence.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(18000),
    basePrice: 18000, rating: 4.6, reviewCount: 213, distanceFromCity: '4 km from Jamshedpur station',
    coordinates: { lat: 22.81, lng: 86.18 }, featured: false, availableRooms: 20,
    gateCode: 'UCJ2025', wingCode: 'TATA', wifiPwd: 'jamshedpur108', phone: '+91 657 231 0101' },

  { title: 'The Leela Palace Bengaluru', location: 'HAL Airport Road, Bengaluru', city: 'Bengaluru', state: 'Karnataka', category: 'Heritage Palace',
    heroImage: palaceA[4], images: palaceA, panoramaImage: palaceC[1], videoId360: 'biv1vAHRLPQ',
    story: 'The Maharaja Suite\'s gold-leaf interiors are modelled on Hyder Ali\'s treasury, with columns replicating the Chennakesava Temple at Belur built by the Hoysala dynasty in 1117 CE. The location near Bangalore Palace (built 1878 in the Tudor style after Windsor Castle) places the Leela at the heart of the Mysore Kingdom\'s 20th-century modernisation — a kingdom that had electricity before London.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(70000),
    basePrice: 70000, rating: 4.9, reviewCount: 445, distanceFromCity: '10 km from MG Road',
    coordinates: { lat: 12.97, lng: 77.60 }, featured: true, availableRooms: 12,
    gateCode: 'LPB2025', wingCode: 'GOLDLEAF', wifiPwd: 'leelablr', phone: '+91 80 2521 1234' },

  { title: 'Lalitha Mahal Palace Hotel', location: 'Mysuru-Ooty Road, Mysuru', city: 'Mysuru', state: 'Karnataka', category: 'Heritage Palace',
    heroImage: palaceB[3], images: palaceB, panoramaImage: palaceA[1], videoId360: 'biv1vAHRLPQ',
    story: 'Built in 1921 by Maharaja Krishnaraja Wadiyar IV as the exclusive guesthouse for the British Viceroy — modelled on St Paul\'s Cathedral, London. As the second-largest palace in India, every room features Bohemian crystal chandeliers, Italian marble floors, and stucco ceilings painted by artists commissioned from Vienna.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(35000),
    basePrice: 35000, rating: 4.8, reviewCount: 398, distanceFromCity: '6 km from Mysore Palace',
    coordinates: { lat: 12.30, lng: 76.65 }, featured: true, availableRooms: 20,
    gateCode: 'LMP2025', wingCode: 'VICEROY', wifiPwd: 'mysorepalace', phone: '+91 821 252 5555' },

  { title: 'Kumarakom Lake Resort', location: 'Kumarakom Village, Kottayam', city: 'Kumarakom', state: 'Kerala', category: 'Forest Retreat',
    heroImage: forestA[1], images: forestA, panoramaImage: forestA[3], videoId360: 'biv1vAHRLPQ',
    story: 'The Heritage Villas with private pools were built on the waterlogged backwater lots of Vembanad Lake, where Kerala\'s earliest Jewish settlers — the Paradesi Jews of Kochi — operated a trading network predating the Roman Empire. The resort\'s private jetties extend over waters carrying the original boat-road network of the Travancore kingdom, whose maharajas funded Asia\'s first female education system in 1817.',
    privileges: forestPriv, facilities: forestFacilities, roomTypes: forestRooms(50000),
    basePrice: 50000, rating: 4.9, reviewCount: 412, distanceFromCity: '16 km from Kottayam town',
    coordinates: { lat: 9.61, lng: 76.43 }, featured: true, availableRooms: 14,
    gateCode: 'KLR2025', wingCode: 'VEMBANAD', wifiPwd: 'kumarakomwater', phone: '+91 481 252 5711' },

  { title: 'Brunton Boatyard', location: 'Calvathy Road, Fort Kochi', city: 'Kochi', state: 'Kerala', category: 'Heritage Palace',
    heroImage: palaceC[3], images: [...palaceC.slice(0,3), ...beachB.slice(0,2)], panoramaImage: beachA[2], videoId360: 'biv1vAHRLPQ',
    story: 'Standing on the exact site of the Brunton & Sons shipyard (1870) on the Kochi harbour that Vasco da Gama first entered in 1498, the Viceroy Suite overlooks the oldest Chinese fishing nets in India — still operated by families whose ancestors installed them under Kublai Khan\'s ambassador in 1350 CE. Fort Kochi is the oldest European settlement in India, pre-dating Goa, Bombay, and Madras.',
    privileges: heritagePriv, facilities: heritageBeachFacilities, roomTypes: palaceRooms(25000),
    basePrice: 25000, rating: 4.7, reviewCount: 356, distanceFromCity: '2 km from Chinese Fishing Nets',
    coordinates: { lat: 9.96, lng: 76.24 }, featured: false, availableRooms: 22,
    gateCode: 'BBK2025', wingCode: 'VICEROY', wifiPwd: 'fortkochi', phone: '+91 484 221 5461' },

  { title: 'The Ultimate Traveller Camp', location: 'Shang Sumdo, Ladakh Valley', city: 'Leh', state: 'Ladakh', category: 'Mountain Retreat',
    heroImage: mountainB[0], images: mountainB, panoramaImage: mountainA[3], videoId360: 'TjzRiLnGqGU',
    story: 'At 11,400 feet in the Indus Valley, these ultra-luxury tented palaces occupy a plateau where the ancient Silk Road connected the Tang Dynasty with the Kushana Empire; caravans carrying Chinese silk, Afghan lapis lazuli, and Roman glass passed within metres of the camp from the 2nd century BCE. Ladakh was only formally incorporated into British India in 1846 as spoils of the First Anglo-Sikh War.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(35000),
    basePrice: 35000, rating: 4.8, reviewCount: 245, distanceFromCity: '35 km from Leh airport',
    coordinates: { lat: 34.16, lng: 77.58 }, featured: true, availableRooms: 10,
    gateCode: 'UTC2025', wingCode: 'SILK', wifiPwd: 'ladakhclear', phone: '+91 1982 251 141' },

  { title: 'Bangaram Island Resort', location: 'Bangaram Atoll, Lakshadweep', city: 'Bangaram', state: 'Lakshadweep', category: 'Beach Villa',
    heroImage: beachB[1], images: beachB, panoramaImage: beachA[3], videoId360: 'aSQn3l53NeM',
    story: 'Bangaram Island — 120 km west of Kozhikode in the Arabian Sea — is an uninhabited coral atoll of 120 acres accessible only by chartered seaplane or speedboat. Lakshadweep\'s 36 atolls are the tops of an ancient volcanic mountain range submerged 65 million years ago; the lagoon contains 150 species of coral in waters Ibn Battuta described in 1343 as "the most crystalline in the known world."',
    privileges: beachPriv, facilities: beachFacilities, roomTypes: beachRooms(45000),
    basePrice: 45000, rating: 4.9, reviewCount: 187, distanceFromCity: '120 km from Kozhikode by seaplane',
    coordinates: { lat: 10.07, lng: 72.27 }, featured: true, availableRooms: 12,
    gateCode: 'BIR2025', wingCode: 'ATOLL', wifiPwd: 'bangaramlagoon', phone: '+91 4896 221 211' },

  { title: 'Taj Usha Kiran Palace', location: 'Jayendraganj, Lashkar, Gwalior', city: 'Gwalior', state: 'Madhya Pradesh', category: 'Heritage Palace',
    heroImage: palaceA[2], images: palaceA, panoramaImage: palaceC[2], videoId360: 'biv1vAHRLPQ',
    story: 'Built 130 years ago as the guest house of Maharaja Madho Rao Scindia I on the slopes below Gwalior Fort — a fortress continuously occupied since the 6th century BCE and called "the pearl among fortresses in India" by Babur. The Scindia family stored the original Kohinoor Diamond within Gwalior Fort\'s treasury before it was "gifted" to the East India Company in 1849.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(30000),
    basePrice: 30000, rating: 4.8, reviewCount: 312, distanceFromCity: '3 km from Gwalior Fort',
    coordinates: { lat: 26.21, lng: 78.18 }, featured: true, availableRooms: 16,
    gateCode: 'TUK2025', wingCode: 'SCINDIA', wifiPwd: 'gwaliorfort', phone: '+91 751 244 4000' },

  { title: 'Taj Mahal Palace', location: 'Apollo Bunder, Colaba, Mumbai', city: 'Mumbai', state: 'Maharashtra', category: 'Heritage Palace',
    heroImage: palaceA[0], images: palaceA, panoramaImage: palaceB[0], videoId360: 'biv1vAHRLPQ',
    story: 'Built in 1903 by Jamshetji Tata — reportedly after he was refused entry to a European-only hotel — the Taj Mahal Palace is India\'s most iconic address, facing the Gateway of India arch built for King George V\'s 1911 visit. During the 26/11 terrorist attack of 2008, hotel staff herded 1,500 guests to safety; 11 staff members sacrificed their lives. The Taj is the only hotel in the world that opens its doors on the anniversary of that crisis.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(85000),
    basePrice: 85000, rating: 5.0, reviewCount: 612, distanceFromCity: 'At Gateway of India',
    coordinates: { lat: 18.92, lng: 72.83 }, featured: true, availableRooms: 10,
    gateCode: 'TMP2025', wingCode: 'TATA', wifiPwd: 'tajcolaba1903', phone: '+91 22 6665 3366' },

  { title: 'Khangabok Palace', location: 'Bishnupur, Manipur Valley', city: 'Imphal', state: 'Manipur', category: 'Heritage Palace',
    heroImage: palaceC[0], images: palaceC, panoramaImage: palaceA[0], videoId360: 'biv1vAHRLPQ',
    story: 'The historic royal seat of the Ningthouja dynasty, rulers of Manipur for over 2,000 years in an unbroken royal succession — one of the longest in world history. The palace\'s throne room overlooks Loktak Lake, the largest freshwater lake in Northeast India and home to the phumdis — floating islands found nowhere else on Earth. Modern polo was codified here in 1859 from the ancient Meitei sport Sagol Kangjei.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(8000),
    basePrice: 8000, rating: 4.4, reviewCount: 123, distanceFromCity: '45 km from Imphal',
    coordinates: { lat: 24.51, lng: 93.80 }, featured: false, availableRooms: 14,
    gateCode: 'KBP2025', wingCode: 'NINGTHOUJA', wifiPwd: 'manipurpolo', phone: '+91 385 245 0101' },

  { title: 'Tripura Castle', location: 'Shillong Peak Road, Shillong', city: 'Shillong', state: 'Meghalaya', category: 'Mountain Retreat',
    heroImage: mountainB[3], images: mountainB, panoramaImage: mountainA[1], videoId360: 'TjzRiLnGqGU',
    story: 'The Summer Retreat of the Manikya Dynasty of Tripura, the Hindu royal family who ruled from the 14th century through 1949. Built in the 1930s in a hybrid Indo-Tibetan style, the hotel\'s library contains a first-edition copy of Marco Pallis\'s Peaks and Lamas (1939) and the original survey charts of Kanchenjunga drawn by the Sikkim Durbar\'s cartographers before Western expeditions arrived.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(20000),
    basePrice: 20000, rating: 4.6, reviewCount: 167, distanceFromCity: '10 km from Police Bazaar',
    coordinates: { lat: 25.57, lng: 91.88 }, featured: false, availableRooms: 12,
    gateCode: 'TRC2025', wingCode: 'MANIKYA', wifiPwd: 'shillongscot', phone: '+91 364 222 5050' },

  { title: 'Aizawl Ritz', location: 'Chanmari West, Aizawl', city: 'Aizawl', state: 'Mizoram', category: 'Mountain Retreat',
    heroImage: mountainA[2], images: mountainA, panoramaImage: mountainB[0], videoId360: 'biv1vAHRLPQ',
    story: 'The top property in Aizawl — a city built entirely on a ridge at 3,500 feet with no flat ground, making it one of the world\'s most vertical capital cities. Mizoram was closed to outsiders until 1987 and remains one of India\'s most literate states (91.3%), a legacy of Welsh Presbyterian missionaries who arrived in 1894 and built schools while documenting a culture of communal self-governance unique in South Asia.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(8000),
    basePrice: 8000, rating: 4.3, reviewCount: 89, distanceFromCity: 'Central Aizawl',
    coordinates: { lat: 23.73, lng: 92.72 }, featured: false, availableRooms: 16,
    gateCode: 'ARZ2025', wingCode: 'RIDGE', wifiPwd: 'aizawlpeak', phone: '+91 389 232 0101' },

  { title: 'The Heritage Kohima', location: 'Aradura Hill, Kohima', city: 'Kohima', state: 'Nagaland', category: 'Mountain Retreat',
    heroImage: mountainB[4], images: mountainB, panoramaImage: mountainA[3], videoId360: 'biv1vAHRLPQ',
    story: 'Converted from the restored Old District Commissioner\'s Bungalow (1905) perched on Aradura Hill, overlooking the Kohima War Cemetery where 1,420 Allied soldiers lie buried from the Battle of Kohima (1944) — called by Field Marshal Slim "the Stalingrad of the East." The hotel\'s garden was the tennis court on which the fiercest two-week battle of the entire Burma Campaign raged at point-blank range.',
    privileges: heritagePriv, facilities: mountainFacilities, roomTypes: mountainRooms(12000),
    basePrice: 12000, rating: 4.5, reviewCount: 134, distanceFromCity: '2 km from War Cemetery',
    coordinates: { lat: 25.67, lng: 94.10 }, featured: false, availableRooms: 14,
    gateCode: 'THK2025', wingCode: 'ARADURA', wifiPwd: 'kohimahill', phone: '+91 370 222 0101' },

  { title: 'The Belgadia Palace', location: 'Baripada, Mayurbhanj', city: 'Baripada', state: 'Odisha', category: 'Heritage Palace',
    heroImage: palaceC[1], images: palaceC, panoramaImage: palaceA[2], videoId360: 'biv1vAHRLPQ',
    story: 'The Victorian-era royal residence of the Maharaja of Mayurbhanj, built in 1905 in a unique Indo-Victorian fusion style. Mayurbhanj is the only district in India where the entire territory falls within the Similipal Biosphere Reserve — a UNESCO site with the largest population of melanistic tigers (black tigers) in the world. The dining hall still uses the original 1905 Austrian crystal dinner service gifted by Emperor Franz Joseph I.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(15000),
    basePrice: 15000, rating: 4.5, reviewCount: 156, distanceFromCity: '2 km from Baripada',
    coordinates: { lat: 21.93, lng: 86.73 }, featured: false, availableRooms: 16,
    gateCode: 'BPG2025', wingCode: 'MAYURBHANJ', wifiPwd: 'similipal', phone: '+91 6792 253 222' },

  { title: 'Palais de Mahe', location: 'Rue de la Caserne, White Town, Pondicherry', city: 'Pondicherry', state: 'Puducherry', category: 'Heritage Palace',
    heroImage: palaceB[0], images: palaceB, panoramaImage: palaceC[0], videoId360: 'biv1vAHRLPQ',
    story: 'A restored 18th-century French Governor\'s residence in White Town, where the street plan, architecture, and boulangeries remain unchanged from the French colonial era (1674-1954) as no urban development has been permitted in the protected zone since Liberation. Pondicherry was the headquarters of the French East India Company; Sri Aurobindo, who fled British India here in 1910, lived five doors away.',
    privileges: heritagePriv, facilities: heritageBeachFacilities, roomTypes: palaceRooms(18000),
    basePrice: 18000, rating: 4.7, reviewCount: 287, distanceFromCity: 'White Town centre',
    coordinates: { lat: 11.93, lng: 79.83 }, featured: false, availableRooms: 16,
    gateCode: 'PDM2025', wingCode: 'FRENCHQTR', wifiPwd: 'pondimansion', phone: '+91 413 222 9800' },

  { title: 'The Baradari Palace', location: 'Baradari Gardens, Patiala', city: 'Patiala', state: 'Punjab', category: 'Heritage Palace',
    heroImage: palaceA[1], images: palaceA, panoramaImage: palaceB[1], videoId360: 'biv1vAHRLPQ',
    story: 'The Garden Palace of the Patiala Maharajas, built by Maharaja Narinder Singh in 1849 — the same year the British Punjab Annexation stripped the Sikh Empire of its sovereignty. The Patiala necklace — containing 2,930 diamonds including the historic Sancy Diamond — was once stored in the vaults below the guest wing. Today the private courtyard hosts exclusive cultural evenings under the stars.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(20000),
    basePrice: 20000, rating: 4.6, reviewCount: 234, distanceFromCity: '4 km from Patiala fort',
    coordinates: { lat: 30.33, lng: 76.40 }, featured: false, availableRooms: 18,
    gateCode: 'BAR2025', wingCode: 'PATIALA', wifiPwd: 'baradaripalace', phone: '+91 175 222 0101' },

  { title: 'The Raj Palace', location: 'Chomu Haveli, Achrol, Jaipur', city: 'Jaipur', state: 'Rajasthan', category: 'Heritage Palace',
    heroImage: palaceA[4], images: palaceA, panoramaImage: palaceB[4], videoId360: 'biv1vAHRLPQ',
    story: 'The Maharaja Pavilion at Rs 30+ lakh per night remains the world\'s most expensive hotel suite in a heritage structure, occupying a 1727 CE haveli gifted by Maharaja Sawai Jai Singh II — who also designed the Jantar Mantar observatory and Jaipur\'s grid-planned Pink City (both UNESCO World Heritage Sites). The palace maintains the only living astrologer-in-residence among all Indian palace hotels.',
    privileges: [...palacePriv, { label: 'Court Astrologer', detail: 'Personal Vedic astronomical chart cast by the palace astrologer at your birth coordinates' }],
    facilities: [...palaceFacilities, 'Observatory Access', 'Elephant Ceremony', 'Private Polo Ground'],
    roomTypes: palaceRooms(250000),
    basePrice: 250000, rating: 5.0, reviewCount: 234, distanceFromCity: '15 km from Hawa Mahal',
    coordinates: { lat: 26.90, lng: 75.80 }, featured: true, availableRooms: 6,
    gateCode: 'RAJ2025', wingCode: 'MAHARAJA', wifiPwd: 'rajpalace1727', phone: '+91 141 234 0045' },

  { title: 'Umaid Bhawan Palace', location: 'Circuit House Road, Jodhpur', city: 'Jodhpur', state: 'Rajasthan', category: 'Heritage Palace',
    heroImage: palaceB[4], images: palaceB, panoramaImage: palaceA[0], videoId360: 'biv1vAHRLPQ',
    story: 'The world\'s largest Living Palace — 347 rooms on 26 acres — built between 1929 and 1943 by Maharaja Umaid Singh to provide employment during a severe famine. An astonishing 3,000 artisans worked for 14 years; the Art Deco ballroom\'s Viennese parquet floor has never been refinished. The Maharaja of Jodhpur, Gaj Singh II, still lives in part of the palace today.',
    privileges: [...palacePriv, { label: 'Polo Masterclass', detail: 'Private instruction by the Jodhpur Polo Club\'s senior patron' }],
    facilities: [...palaceFacilities, 'Indoor Pool', 'Museum Access', 'Polo Grounds'],
    roomTypes: palaceRooms(180000),
    basePrice: 180000, rating: 4.9, reviewCount: 456, distanceFromCity: '6 km from Mehrangarh Fort',
    coordinates: { lat: 26.30, lng: 73.05 }, featured: true, availableRooms: 8,
    gateCode: 'UBP2025', wingCode: 'UMAID', wifiPwd: 'jodhpurblue', phone: '+91 291 251 0101' },

  { title: 'Elgin Nor-Khill', location: 'Stadium Road, Gangtok', city: 'Gangtok', state: 'Sikkim', category: 'Mountain Retreat',
    heroImage: mountainA[4], images: mountainA, panoramaImage: mountainB[2], videoId360: 'TjzRiLnGqGU',
    story: 'The Former Royal Guest House of the Chogyal of Sikkim, the Buddhist monarchy whose last king married American Hope Cooke in 1963 and whose 1975 merger into India remains one of geopolitical history\'s most disputed annexations. Built in the 1930s in a hybrid Indo-Tibetan style, the hotel\'s library contains original survey charts of Kanchenjunga\'s first route drawn by the Sikkim Durbar\'s cartographers.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(25000),
    basePrice: 25000, rating: 4.7, reviewCount: 198, distanceFromCity: '3 km from MG Marg',
    coordinates: { lat: 27.33, lng: 88.61 }, featured: false, availableRooms: 14,
    gateCode: 'ENK2025', wingCode: 'CHOGYAL', wifiPwd: 'norkhillzen', phone: '+91 3592 205 637' },

  { title: 'ITC Grand Chola', location: 'Mount Road, Chennai', city: 'Chennai', state: 'Tamil Nadu', category: 'Heritage Palace',
    heroImage: palaceC[3], images: palaceC, panoramaImage: palaceA[3], videoId360: 'biv1vAHRLPQ',
    story: 'The Sangam Suite modelled on the Chola Dynasty\'s Brihadeeswarar Temple (UNESCO, 1010 CE) stands on the Mount Road corridor where Robert Clive first established British Madras in 1640. The ITC Grand Chola at 600 rooms is the largest hotel in South India; its entrance colonnade replicates the exact proportions of the Tanjore temple\'s 216-foot vimana tower.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(50000),
    basePrice: 50000, rating: 4.8, reviewCount: 398, distanceFromCity: '12 km from Marina Beach',
    coordinates: { lat: 13.03, lng: 80.26 }, featured: true, availableRooms: 14,
    gateCode: 'GCH2025', wingCode: 'CHOLA', wifiPwd: 'cholasuite', phone: '+91 44 2220 0000' },

  { title: 'Heritage Madurai', location: 'Melakkal Road, Madurai', city: 'Madurai', state: 'Tamil Nadu', category: 'Heritage Palace',
    heroImage: palaceB[2], images: palaceB, panoramaImage: palaceC[4], videoId360: 'biv1vAHRLPQ',
    story: 'Designed by the legendary Sri Lankan architect Geoffrey Bawa on a colonial bungalow complex planted in 1923. The Meenakshi Amman Temple 3 km away has stood uninterrupted for 2,000 years with 33,000 sculptures on 14 towers; Heritage Madurai\'s private rooftop provides the only unobstructed view of all 14 gopurams simultaneously.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(25000),
    basePrice: 25000, rating: 4.7, reviewCount: 312, distanceFromCity: '8 km from Meenakshi Temple',
    coordinates: { lat: 9.92, lng: 78.12 }, featured: false, availableRooms: 20,
    gateCode: 'HMD2025', wingCode: 'BAWA', wifiPwd: 'maduraitemple', phone: '+91 452 238 5455' },

  { title: 'Taj Falaknuma Palace', location: 'Falaknuma, Hyderabad', city: 'Hyderabad', state: 'Telangana', category: 'Heritage Palace',
    heroImage: palaceA[3], images: palaceA, panoramaImage: palaceB[3], videoId360: 'biv1vAHRLPQ',
    story: 'Built in 1893 by Nawab Vikar ul-Umra and later purchased by Nizam VI Mahbub Ali Khan, the Falaknuma Palace\'s dining table seats 101 guests simultaneously — the longest in Asia. The Nizam VII was in 1940 the world\'s richest individual with an estimated fortune of $2 trillion in today\'s money; his private jewellery collection included the Jacob Diamond at 184 carats, stored in a sock in his personal wardrobe.',
    privileges: [...palacePriv, { label: 'Jacob Diamond Display', detail: 'Private viewing of the Nizam jewellery replica collection' }],
    facilities: [...palaceFacilities, 'Jilaukhana Courtyard', 'Billiards Room', 'Horse-Drawn Carriage'],
    roomTypes: palaceRooms(65000),
    basePrice: 65000, rating: 5.0, reviewCount: 534, distanceFromCity: '10 km from Charminar',
    coordinates: { lat: 17.32, lng: 78.47 }, featured: true, availableRooms: 10,
    gateCode: 'TFP2025', wingCode: 'NIZAM', wifiPwd: 'falaknuma1893', phone: '+91 40 6629 8585' },

  { title: 'Ujjayanta Palace', location: 'Palace Compound, Agartala', city: 'Agartala', state: 'Tripura', category: 'Heritage Palace',
    heroImage: palaceC[0], images: palaceC, panoramaImage: palaceA[4], videoId360: 'biv1vAHRLPQ',
    story: 'The massive white Mughal-style palace built in 1901 by Maharaja Radha Kishore Manikya. The name "Ujjayanta" (victorious) was conferred by Rabindranath Tagore who was a personal guest of the Maharaja. The palace contains India\'s only royal museum dedicated entirely to the tribal art of the 19 Tripuri communities, preserved in 36 galleries.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(12000),
    basePrice: 12000, rating: 4.4, reviewCount: 134, distanceFromCity: 'Central Agartala',
    coordinates: { lat: 23.83, lng: 91.28 }, featured: false, availableRooms: 16,
    gateCode: 'UJP2025', wingCode: 'MANIKYA', wifiPwd: 'agartalapalace', phone: '+91 381 222 5100' },

  { title: 'Taj Nadesar Palace', location: 'Nadesar, Varanasi', city: 'Varanasi', state: 'Uttar Pradesh', category: 'Heritage Palace',
    heroImage: palaceA[1], images: palaceA, panoramaImage: palaceB[0], videoId360: 'biv1vAHRLPQ',
    story: 'The boutique palace of the Maharaja of Varanasi, built in 1835 on 8 acres granted by the East India Company. Varanasi — continuously inhabited for 3,000 years — is the oldest living city on Earth. The property\'s dawn boat ritual provides private access to the sacred Ganga Aarti ceremony on the ghats, an unbroken tradition since the 6th century Gupta period.',
    privileges: [...palacePriv, { label: 'Ghat Ceremony', detail: 'Private dawn boat for the sacred Ganga Aarti ceremony at Dashashwamedh Ghat' }],
    facilities: [...palaceFacilities, 'Private Ghat Access', 'Pandit Consultation', 'Benaras Weave Atelier'],
    roomTypes: palaceRooms(45000),
    basePrice: 45000, rating: 4.8, reviewCount: 356, distanceFromCity: '5 km from Dashashwamedh Ghat',
    coordinates: { lat: 25.33, lng: 83.00 }, featured: true, availableRooms: 10,
    gateCode: 'TNP2025', wingCode: 'NADESAR', wifiPwd: 'varanasiganges', phone: '+91 542 250 3000' },

  { title: 'The Oberoi Amarvilas', location: 'Taj East Gate Road, Agra', city: 'Agra', state: 'Uttar Pradesh', category: 'Heritage Palace',
    heroImage: palaceB[1], images: palaceB, panoramaImage: palaceA[2], videoId360: 'biv1vAHRLPQ',
    story: 'Every room faces the Taj Mahal 600 metres away — the only hotel in the world where the UNESCO World Heritage monument is the exclusive unobstructed view from every bathroom, bedroom, and dining chair. Built on the precise elevation that Shah Jahan chose as the Moonlight Garden viewing terrace for the Taj, which required 22,000 artisans over 21 years and was completed in 1653.',
    privileges: [...palacePriv, { label: 'Taj Sunrise Access', detail: 'Private escorted dawn access to the Taj Mahal gardens before public opening' }],
    facilities: [...palaceFacilities, 'Taj View Terrace', 'Mughal Heritage Pool'],
    roomTypes: palaceRooms(70000),
    basePrice: 70000, rating: 5.0, reviewCount: 567, distanceFromCity: '600m from Taj Mahal',
    coordinates: { lat: 27.17, lng: 78.04 }, featured: true, availableRooms: 10,
    gateCode: 'OAV2025', wingCode: 'TAJVIEW', wifiPwd: 'amarvilasTaj', phone: '+91 562 223 1515' },

  { title: 'Ananda in the Himalayas', location: 'The Palace Estate, Narendra Nagar, Rishikesh', city: 'Rishikesh', state: 'Uttarakhand', category: 'Mountain Retreat',
    heroImage: mountainA[0], images: mountainA, panoramaImage: mountainB[4], videoId360: 'TjzRiLnGqGU',
    story: 'The Viceregal Palace Suite commands the Viceregal Lodge built in 1910, set on a ridgeline 1,000 feet above the Ganges where the river emerges from its gorge at Rishikesh — the Yoga Capital of the World. Below the estate, the Beatles composed White Album songs at Maharishi Mahesh Yogi\'s ashram in 1968 — the international debut of Transcendental Meditation.',
    privileges: [...mountainPriv, { label: 'Vedic Wellness', detail: 'Daily private Vedic consultation with resident Pandit and Ayurvedic physician' }],
    facilities: [...mountainFacilities, 'Ayurvedic Centre', 'Vedic Library', 'Ganges Meditation Deck', 'Yoga Shala'],
    roomTypes: mountainRooms(60000),
    basePrice: 60000, rating: 5.0, reviewCount: 489, distanceFromCity: '30 km from Rishikesh',
    coordinates: { lat: 30.13, lng: 78.33 }, featured: true, availableRooms: 12,
    gateCode: 'ANA2025', wingCode: 'VICEREGAL', wifiPwd: 'anandaganges', phone: '+91 1378 227 500' },

  { title: 'ITC Royal Bengal', location: 'NewTown, Kolkata', city: 'Kolkata', state: 'West Bengal', category: 'Heritage Palace',
    heroImage: palaceC[2], images: palaceC, panoramaImage: palaceA[1], videoId360: 'biv1vAHRLPQ',
    story: 'The Grand Presidential Suite at India\'s largest hotel (660 rooms) stands on NewTown\'s reclaimed ground — the same Ganges delta where Robert Clive\'s 200-man force defeated Siraj ud-Daulah\'s 50,000-strong army at Plassey in 1757, the battle that handed India to the British East India Company. Kolkata was the capital of British India from 1772 to 1911, birthplace of the Bengal Renaissance.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(40000),
    basePrice: 40000, rating: 4.8, reviewCount: 389, distanceFromCity: '12 km from Howrah Bridge',
    coordinates: { lat: 22.58, lng: 88.46 }, featured: true, availableRooms: 14,
    gateCode: 'IRB2025', wingCode: 'BENGAL', wifiPwd: 'kolkataitc', phone: '+91 33 4455 7777' },

  { title: 'Glenburn Tea Estate', location: 'Glenburn, Darjeeling', city: 'Darjeeling', state: 'West Bengal', category: 'Forest Retreat',
    heroImage: forestA[0], images: forestA, panoramaImage: mountainB[1], videoId360: 'TjzRiLnGqGU',
    story: 'Operating since 1860, Glenburn\'s 1,600-acre estate is tended by the fourth-generation family maintaining original Scotch-planting traditions. The Silver Tips Imperial variety grown here sells for Rs 99,999 per kilogram — the world\'s most expensive commercial tea. Kanchenjunga, the world\'s third-highest peak, fills every bedroom window in an unbroken panorama.',
    privileges: [...forestPriv, { label: 'Tea Plucking', detail: 'Private early-morning hand-plucking session with master tea maker in the garden' }],
    facilities: [...forestFacilities, 'Tea Factory Tour', 'Silver Tips Tasting', 'Mountain Viewpoint'],
    roomTypes: forestRooms(30000),
    basePrice: 30000, rating: 4.9, reviewCount: 267, distanceFromCity: '25 km from Darjeeling town',
    coordinates: { lat: 26.98, lng: 88.25 }, featured: true, availableRooms: 8,
    gateCode: 'GTE2025', wingCode: 'PLANTER', wifiPwd: 'glenburnfirst', phone: '+91 354 225 7226' },

  // ── Maharashtra Multi-City Estates ────────────────────────────────────────

  { title: 'The Ritz-Carlton Pune', location: 'Golf Course Square, Pune', city: 'Pune', state: 'Maharashtra', category: 'Heritage Palace',
    heroImage: palaceB[4], images: palaceB, panoramaImage: palaceC[3], videoId360: 'biv1vAHRLPQ',
    story: 'The Presidential Suite overlooks the Golf Course Square of the former Pune Cantonment — built in 1817 after the Third Anglo-Maratha War ended the 130-year Peshwa dynasty. Pune was the intellectual capital of the Maratha Empire where Chhatrapati Shivaji Maharaj organised the first modern guerrilla army to defeat Mughal rule in 1674. The foundations lie on the former lines of the 8th King\'s Royal Irish Hussars.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(50000),
    basePrice: 50000, rating: 4.8, reviewCount: 376, distanceFromCity: '12 km from Shivajinagar',
    coordinates: { lat: 18.55, lng: 73.90 }, featured: true, availableRooms: 14,
    gateCode: 'RCP2025', wingCode: 'GOLF', wifiPwd: 'puneritz', phone: '+91 20 4014 0101' },

  { title: 'ABIL Mansion Koregaon Park', location: 'Koregaon Park, Pune', city: 'Pune', state: 'Maharashtra', category: 'Heritage Palace',
    heroImage: palaceA[2], images: palaceA, panoramaImage: palaceC[2], videoId360: 'biv1vAHRLPQ',
    story: 'Ultra-private penthouse residences in Koregaon Park — Pune\'s most coveted address — in a neighbourhood already home to Osho\'s International Meditation Resort attracting billionaires and spiritual seekers since 1974. Koregaon Park sits on the site of the 1818 Battle of Koregaon where 500 British Mahar soldiers defeated 28,000 Peshwa troops — the battle celebrated annually by 1 million Dalits as Bhima Koregaon.',
    privileges: palacePriv, facilities: [...palaceFacilities, 'Sky Pool', 'Concierge Security'],
    roomTypes: palaceRooms(45000),
    basePrice: 45000, rating: 4.7, reviewCount: 145, distanceFromCity: '8 km from Shivajinagar',
    coordinates: { lat: 18.54, lng: 73.89 }, featured: false, availableRooms: 8,
    gateCode: 'ABM2025', wingCode: 'KOREGAON', wifiPwd: 'abilpune', phone: '+91 20 4014 9000' },

  { title: 'Amanzi Blue Skies', location: 'Arthur Seat Road, Mahabaleshwar', city: 'Mahabaleshwar', state: 'Maharashtra', category: 'Mountain Retreat',
    heroImage: mountainA[1], images: mountainA, panoramaImage: mountainB[2], videoId360: 'TjzRiLnGqGU',
    story: 'The ultra-luxury private estate with 360-degree Sahyadri views sits atop Malcolm Peth at 4,500 feet — the plateau designated the official summer capital of Bombay Presidency in 1828, attracting British Governors who came to escape the monsoon heat. The estate\'s private helipad was originally the Governor\'s secure landing spot for clandestine communications with Calcutta.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(55000),
    basePrice: 55000, rating: 4.9, reviewCount: 198, distanceFromCity: '6 km from Mahabaleshwar town',
    coordinates: { lat: 17.92, lng: 73.65 }, featured: true, availableRooms: 8,
    gateCode: 'ABS2025', wingCode: 'BLUESKY', wifiPwd: 'sahyadrisky', phone: '+91 2168 260 260' },

  { title: 'Le Meridien Forest Resort Mahabaleshwar', location: 'Panchgani-Mahabaleshwar Road', city: 'Mahabaleshwar', state: 'Maharashtra', category: 'Forest Retreat',
    heroImage: forestA[2], images: forestA, panoramaImage: forestA[1], videoId360: 'biv1vAHRLPQ',
    story: 'The Sanctuary Suite nestles inside a private forest reserve on the watershed ridge where the Krishna, Koyna, and Venna rivers all originate from the same plateau — a phenomenon celebrated in Maratha texts as the Trivenisangam of the Western Ghats. The forest below falls within Koyna Wildlife Sanctuary, a UNESCO Natural Heritage site since 2012 sheltering over 240 species of birds.',
    privileges: forestPriv, facilities: forestFacilities, roomTypes: forestRooms(35000),
    basePrice: 35000, rating: 4.7, reviewCount: 234, distanceFromCity: '18 km from Mahabaleshwar',
    coordinates: { lat: 17.88, lng: 73.70 }, featured: false, availableRooms: 14,
    gateCode: 'LMF2025', wingCode: 'SANCTUARY', wifiPwd: 'koynajungle', phone: '+91 2168 260 101' },

  { title: 'Radisson Blu Presidential Villa Alibaug', location: 'Nagaon Beach, Alibaug', city: 'Alibaug', state: 'Maharashtra', category: 'Beach Villa',
    heroImage: beachA[2], images: beachA, panoramaImage: beachB[3], videoId360: 'aSQn3l53NeM',
    story: 'The Presidential Coastal Villa — a 15-minute helicopter hop from Mumbai\'s Juhu helipad — overlooks the Kolaba Fort built by Chhatrapati Shivaji Maharaj in 1680 as his naval headquarters. Alibaug\'s coastline was home to the Maratha Navy under Admiral Kanhoji Angre, whose fleet never surrendered to European colonists. The private lap pool was excavated from laterite rock carrying Angre\'s naval charts from 1710.',
    privileges: beachPriv, facilities: beachFacilities, roomTypes: beachRooms(45000),
    basePrice: 45000, rating: 4.8, reviewCount: 287, distanceFromCity: '8 km from Alibaug ferry',
    coordinates: { lat: 18.64, lng: 72.88 }, featured: true, availableRooms: 12,
    gateCode: 'RAB2025', wingCode: 'NAGAON', wifiPwd: 'alibaugcoast', phone: '+91 2141 230 101' },

  { title: 'Mansion House Alibaug', location: 'Velas Road, Murud, Alibaug', city: 'Alibaug', state: 'Maharashtra', category: 'Heritage Palace',
    heroImage: palaceC[4], images: palaceC, panoramaImage: palaceA[4], videoId360: 'biv1vAHRLPQ',
    story: 'A private boutique estate built as the summer palace of the Nawabs of Janjira — the only unconquered African-origin royal dynasty in India, ruling since 1490 CE from Murud-Janjira, an island fort never taken by Shivaji, the British, the Dutch, or the Portuguese. Today it serves India\'s ultra-high-net-worth residents as the most private address on the Konkan coast.',
    privileges: palacePriv, facilities: palaceFacilities, roomTypes: palaceRooms(60000),
    basePrice: 60000, rating: 4.9, reviewCount: 134, distanceFromCity: '35 km from Alibaug',
    coordinates: { lat: 18.32, lng: 72.96 }, featured: true, availableRooms: 6,
    gateCode: 'MHA2025', wingCode: 'JANJIRA', wifiPwd: 'nawabkonkan', phone: '+91 2144 274 001' },

  { title: 'The Source at Sula', location: 'Govardhan, Nashik', city: 'Nashik', state: 'Maharashtra', category: 'Forest Retreat',
    heroImage: forestA[3], images: forestA, panoramaImage: forestA[4], videoId360: 'biv1vAHRLPQ',
    story: 'The Viceroy Suite sits inside India\'s most beloved vineyard — Sula Vineyards, established in 1999 on the banks of the Godavari River — in a valley that for 1,200 years served as a pilgrim route to Trimbakeshwar, one of the 12 Jyotirlinga shrines of Shiva. Nashik holds the Kumbh Mela every 12 years, when 30 million pilgrims gather on the Godavari bank in a single day.',
    privileges: forestPriv, facilities: forestFacilities, roomTypes: forestRooms(40000),
    basePrice: 40000, rating: 4.8, reviewCount: 311, distanceFromCity: '14 km from Nashik',
    coordinates: { lat: 20.01, lng: 73.74 }, featured: true, availableRooms: 14,
    gateCode: 'SSV2025', wingCode: 'VINEYARD', wifiPwd: 'sulawine', phone: '+91 253 223 5888' },

  { title: 'Radisson Blu Resort & Spa Nashik', location: 'Pandavleni Hills, Nashik', city: 'Nashik', state: 'Maharashtra', category: 'Mountain Retreat',
    heroImage: mountainB[1], images: mountainB, panoramaImage: mountainA[2], videoId360: 'biv1vAHRLPQ',
    story: 'The Presidential Suite overlooks the Pandavleni Caves — 24 Buddhist rock-cut caves carved between the 1st century BCE and 6th century CE at the height of the Satavahana dynasty\'s patronage. Nashik is the third-holiest city in Hinduism, revered as the site where Rama, Sita, and Lakshmana spent 14 years of their forest exile along the Godavari River.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(25000),
    basePrice: 25000, rating: 4.6, reviewCount: 245, distanceFromCity: '6 km from Nashik centre',
    coordinates: { lat: 20.00, lng: 73.82 }, featured: false, availableRooms: 18,
    gateCode: 'RBN2025', wingCode: 'PANDAVA', wifiPwd: 'nashikgodavari', phone: '+91 253 660 5555' },

  { title: 'Le Meridien Tiger Capital Nagpur', location: 'Wardha Road, Nagpur', city: 'Nagpur', state: 'Maharashtra', category: 'Forest Retreat',
    heroImage: forestA[4], images: forestA, panoramaImage: forestA[0], videoId360: 'biv1vAHRLPQ',
    story: 'The Royal Suite occupies the geographic centre of India — the Zero Mile Stone of the British survey of India (1907) stands 2 km from the entrance. Nagpur is the gateway to Tadoba-Andhari Tiger Reserve, home to 88 Bengal Tigers in a single reserve. Company records from 1867 show the site served as the Nagpur Residency of the British Agent to the Central Provinces.',
    privileges: forestPriv, facilities: forestFacilities, roomTypes: forestRooms(30000),
    basePrice: 30000, rating: 4.7, reviewCount: 289, distanceFromCity: 'Central Nagpur',
    coordinates: { lat: 21.15, lng: 79.10 }, featured: false, availableRooms: 16,
    gateCode: 'LMN2025', wingCode: 'TIGER', wifiPwd: 'tadobanagpur', phone: '+91 712 669 0000' },

  { title: 'Della Resorts Presidential Suite', location: 'Kunegaon, Lonavala', city: 'Lonavala', state: 'Maharashtra', category: 'Mountain Retreat',
    heroImage: mountainA[3], images: mountainA, panoramaImage: mountainB[3], videoId360: 'TjzRiLnGqGU',
    story: 'The Presidential Suite with its 12-seater dining table sits on the Sahyadri escarpment at 2,100 feet, the same strategic ridge used by Maratha commander Tanaji Malusare when he scaled the Kondhana Fort cliffs with rope ladders in 1670 CE — the conquest immortalised in the film Tanhaji. Lonavala\'s railway connection (1863) opened the Sahyadri hills to Bombay\'s cotton mill elite, creating India\'s first planned hill-resort culture.',
    privileges: mountainPriv, facilities: mountainFacilities, roomTypes: mountainRooms(35000),
    basePrice: 35000, rating: 4.7, reviewCount: 312, distanceFromCity: '8 km from Lonavala station',
    coordinates: { lat: 18.75, lng: 73.43 }, featured: true, availableRooms: 10,
    gateCode: 'DRS2025', wingCode: 'SAHYADRI', wifiPwd: 'lonavalahill', phone: '+91 2114 399 300' },

  { title: 'Aamby Valley City', location: 'Aamby Valley, Sahyadri Range', city: 'Lonavala', state: 'Maharashtra', category: 'Mountain Retreat',
    heroImage: mountainB[2], images: mountainB, panoramaImage: mountainA[4], videoId360: 'TjzRiLnGqGU',
    story: 'A fully self-contained private city of 10,000 acres in the Western Ghats with an international-grade airstrip and golf courses. Aamby Valley City is India\'s most advanced private planned township — the estate\'s private airstrip once operated the world\'s first private town airline, and the Golfshire course is India\'s largest private golf enclave attracting the country\'s top industrialists.',
    privileges: mountainPriv, facilities: [...mountainFacilities, 'Private Airstrip', 'Golf Courses', 'Cricket Ground'],
    roomTypes: mountainRooms(45000),
    basePrice: 45000, rating: 4.6, reviewCount: 178, distanceFromCity: '60 km from Pune',
    coordinates: { lat: 18.80, lng: 73.58 }, featured: false, availableRooms: 30,
    gateCode: 'AVC2025', wingCode: 'AIRSTRIP', wifiPwd: 'aambyvalley', phone: '+91 2114 667 777' },

  { title: 'Vivanta Aurangabad', location: 'Chikalthana, Aurangabad', city: 'Aurangabad', state: 'Maharashtra', category: 'Heritage Palace',
    heroImage: palaceA[3], images: palaceA, panoramaImage: palaceB[4], videoId360: 'biv1vAHRLPQ',
    story: 'Set on a 5-acre Mughal-inspired landscape, 10 km from the Ajanta Caves (UNESCO, 2nd century BCE) and 30 km from the Ellora Caves (UNESCO, 6th-11th century). The property\'s Mughal archway gate replicates the Daulatabad Fort\'s entry carved in 1187 CE, and the suite\'s gardens echo the Bibi Ka Maqbara built in 1668 as Aurangzeb\'s tribute to his queen Dilras Banu Begum.',
    privileges: heritagePriv, facilities: palaceFacilities, roomTypes: palaceRooms(30000),
    basePrice: 30000, rating: 4.7, reviewCount: 298, distanceFromCity: '12 km from Ajanta caves',
    coordinates: { lat: 19.88, lng: 75.32 }, featured: false, availableRooms: 20,
    gateCode: 'VAU2025', wingCode: 'MUGHAL', wifiPwd: 'aurangabadfort', phone: '+91 240 661 1111' },

  { title: 'AeroVillage Panheli', location: 'Panheli Airstrip, Sahyadri Range, Nashik District', city: 'Nashik', state: 'Maharashtra', category: 'Mountain Retreat',
    heroImage: mountainA[4], images: mountainA, panoramaImage: mountainB[4], videoId360: 'TjzRiLnGqGU',
    story: 'India\'s first and only fly-in resort where guests land their private jet or helicopter directly at the villa doorstep. The property sits on the Sahyadri scarp face at 3,000 feet — basalt columns dating to the Deccan Traps eruption 66 million years ago that coincided with the extinction of the dinosaurs. AeroVillage\'s private apron has hosted Dassault Falcons, Bombardier Globals, and the personal jets of 14 Fortune 500 CEOs.',
    privileges: [...mountainPriv, { label: 'Fly-In Landing', detail: 'Direct private jet or helicopter landing at your villa apron — 1,800m runway' }],
    facilities: [...mountainFacilities, 'Private Airstrip (1800m)', 'Jet Hangar', 'Helicopter Pad'],
    roomTypes: mountainRooms(80000),
    basePrice: 80000, rating: 4.9, reviewCount: 87, distanceFromCity: '45 km from Nashik',
    coordinates: { lat: 20.10, lng: 73.75 }, featured: true, availableRooms: 8,
    gateCode: 'AVP2025', wingCode: 'FLYIN', wifiPwd: 'aerovillage', phone: '+91 253 667 7000' },

];

// ── User Seed Data ─────────────────────────────────────────────────────────────
const users = [
  { phoneNumber: '9876543210', role: 'admin', name: 'Atithya Admin', isActive: true, loyaltyPoints: 50000, memberTier: 'Royal' },
  { phoneNumber: '9999999999', role: 'elite', name: 'Maharaj Guest', isActive: true, loyaltyPoints: 25000, memberTier: 'Platinum' },
  { phoneNumber: '8888888888', role: 'elite', name: 'Royal Guest', isActive: true, loyaltyPoints: 10000, memberTier: 'Gold' },
];

// ── Main Seed ─────────────────────────────────────────────────────────────────
async function seed() {
  await mongoose.connect(process.env.MONGO_URI);
  console.log('✅ MongoDB connected');

  const deletedEstates = await Estate.deleteMany({});
  console.log(`🗑  Deleted ${deletedEstates.deletedCount} old estates`);

  const inserted = await Estate.insertMany(estates);
  console.log(`✅ Inserted ${inserted.length} estates`);

  // Summary by state
  const byState = {};
  estates.forEach(e => { byState[e.state] = (byState[e.state] || 0) + 1; });
  const stateCount = Object.keys(byState).length;
  console.log(`📍 Estates across ${stateCount} states/UTs:`, byState);

  // Seed users (upsert)
  for (const u of users) {
    await User.updateOne({ phoneNumber: u.phoneNumber }, { $set: u }, { upsert: true });
  }
  console.log(`✅ ${users.length} users upserted`);

  // Create food menus for first 5 estates
  await FoodMenu.deleteMany({});
  const menuEstates = inserted.slice(0, 5);
  for (const estate of menuEstates) {
    await FoodMenu.create({
      estate: estate._id,
      categories: [
        { name: 'Royal Breakfast', icon: '🌅', items: [
          { name: 'Maharaja Thali', desc: 'Traditional Indian breakfast spread with seasonal fruits, handmade flatbreads and five chutneys', price: 1800, isVeg: true, isSignature: true, prepTime: 20, image: '' },
          { name: 'Forest Mushroom Omelette', desc: 'Wild forest mushrooms, truffle oil, fresh herbs and aged cheddar in a folded egg omelette', price: 1200, isVeg: true, isSignature: false, prepTime: 12, image: '' },
          { name: 'Continental Spread', desc: 'Artisanal breads, imported charcuterie, organic butter and estate honey', price: 950, isVeg: false, isSignature: false, prepTime: 8, image: '' },
        ]},
        { name: 'Signature Cuisine', icon: '🍽️', items: [
          { name: 'Slow-Braised Lamb Raan', desc: '16-hour slow-braised Rajasthani lamb leg with saffron jus and handmade bread', price: 4500, isVeg: false, isSignature: true, prepTime: 35, image: '' },
          { name: 'Dal Maharani', desc: 'Black lentil slow-cooked 72 hours over wood fire with cream and hand-pounded spices', price: 1400, isVeg: true, isSignature: true, prepTime: 20, image: '' },
          { name: 'Malabar Lobster Moilee', desc: 'Whole local lobster in coconut cream, curry leaf and turmeric — served with string hoppers', price: 6200, isVeg: false, isSignature: true, prepTime: 40, image: '' },
        ]},
        { name: 'Heritage Bar', icon: '🥃', items: [
          { name: 'Palace Sling', desc: 'Darjeeling first flush tea-infused gin, elderflower, fresh lime and ginger beer', price: 1600, isVeg: true, isSignature: true, prepTime: 5, image: '' },
          { name: 'Masala Old Fashioned', desc: 'Single malt whisky, cardamom bitters, jaggery syrup and orange peel', price: 1800, isVeg: true, isSignature: true, prepTime: 4, image: '' },
        ]},
      ],
    });
  }
  console.log(`✅ Food menus created for ${menuEstates.length} estates`);

  await mongoose.disconnect();
  console.log(`\n🏰 Seed complete — ${inserted.length} world-class Indian estates loaded across ${stateCount} states & UTs\n`);
}

seed().catch(err => { console.error('❌ Seed failed:', err.message); process.exit(1); });
