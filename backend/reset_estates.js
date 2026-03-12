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

  {
    title: 'Umaid Bhawan Palace',
    location: 'Circuit House Road, Jodhpur',
    city: 'Jodhpur',
    state: 'Rajasthan',
    country: 'India',
    category: 'Heritage Palace',
    heroImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAwepovNxBCzkyJBknCOzuRs1bInmzcPLFiOla-PI-Pt_eoyuayGvuv7TXDzHRsR-ywkKksKOlr9foObxSeG0riIYnesCRsvCe4LlzcHA003UWncmrSmSR_3aoEXSZSvVTqREPw7HUtfu1F60=s1360-w1360-h1020',
    images: [
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwerYDtzK6ows-DDZkoqu7Rvo0aWnDSc8FwXN8iKK-G1qi7sQqVM7xU3KXMP1USRub9YP0-KiQkrskUToRzVNbxwYOT01K1YMj-N7H373YNjhhwF4B_fd9NWZp7iS-xq0nEq6xoYO=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwepA1aWUF85VS_O7n8dW5EilU6Ccuw6cB3-QXrA9LxBHOu-VlzVwakS2gxqIgMkj78vjnNlgujDN4OdcAmGxEMLj-DLX6Oynz9N6SUsGapslBY8XggshUUqVw81zEJm7-gA-x3KuM-WD7cHQ=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweo1IK70u48C_mg_LirDN8OE8LtGbTkuyFDt_wj9Dtzzn_K5B1GebxVhBxgK547Y8sol5BCHiMiGjhHBOLeeBTNXF1ZUjfEm44BR1_GITY7nNn1dmQUbfifEqQxAWJJBNKPU5Cyidw=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwerSR-UwlL5BM2ysYzOf_1WW4H3ucGF1160ToXQNfZGQptz7GiO0GGDOYAnhDhX2kUWAT7NOoSzS9HnLsVMNZD5eczOowX9vdeCpP85xiuqRU2tUKVS7X6UyaLCt-qEOEzpH3_rzqg=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweo5BsQKWDPW3kEp0ZZ7lSw5ZtDFs6XZTUdYfPpk-_bBfcsEZRKn4ru9LFCUJJTpNUDylyLy8YJXEozmiCYA2hq70HrzTGK1lGxMg2Q2mi_yRCXUDR8HI_uoEuMn60ey8OroLoiP=s1360-w1360-h1020',
    ],
    story: "Commissioned in 1929 by Maharaja Umaid Singh to provide employment to 3,000 villagers during a devastating famine, Umaid Bhawan Palace took 15 years to build and remains one of the largest private residences in the world. Designed by Henry Vaughan Lanchester in a blend of Indo-Saracenic and Art Deco styles, its 347 rooms rise above the Blue City of Jodhpur in warm honey-coloured Chittar sandstone — quarried entirely without mortar, each block interlocking by gravity alone. Half the palace remains home to the royal family of Jodhpur; the other half is a legendary Taj hotel.",
    privileges: [
      { label: 'Royal Turban Ceremony', detail: 'Private ceremonial welcome by palace staff in traditional attire' },
      { label: 'Vintage Car Excursion', detail: 'Guided tour of the Maharaja\'s antique car collection' },
      { label: 'Sunset Jodhpur View', detail: 'Exclusive rooftop access overlooking the Blue City at dusk' },
      { label: 'Polo Grounds Access', detail: 'Private access to royal polo grounds with coaching available' },
    ],
    facilities: [
      'Spa & Wellness', 'Outdoor Pool', 'Fitness Centre', 'Tennis Court',
      'Polo Grounds', 'Heritage Museum', 'Vintage Car Gallery', 'Banquet Hall',
      'Concierge', 'Valet Parking', 'Yoga Pavilion', 'Cigar Lounge',
    ],
    roomTypes: [
      { name: 'Maharaja Suite',    price: 395000, capacity: 2, desc: 'Lavish Art Deco suite with private terrace, personal butler and Blue City panoramas' },
      { name: 'Regal Suite',       price: 195000, capacity: 2, desc: 'Split-level suite featuring original 1940s furnishings, sunken bathtub and garden views' },
      { name: 'Heritage Deluxe',   price: 78000,  capacity: 2, desc: 'Spacious room with hand-carved jharokha windows, sandstone accents and marigold decor' },
      { name: 'Palace Room',       price: 48000,  capacity: 2, desc: 'Elegantly appointed room with hand-woven textiles and views of the palace forecourt' },
    ],
    basePrice: 78000,
    rating: 5,
    reviewCount: 487,
    distanceFromCity: '3 km from Clock Tower',
    coordinates: { lat: 26.2839, lng: 73.0243 },
    featured: true,
    panoramaImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAweqgrHf4k4_MGAkhuNOEpZ4FV5YhrQtdc32-bfcLRT2bEoNwlC8FdNGKzgPaTnCuuEzeH5IAN0T-IqPwFekFex3bwpulP2XFIR8Qx5DwwKDhfBae9RSorz5oNQoIB2hcvea=s1360-w1360-h1020',
    videoId360: 'yx8k7GJ_Ta0',
    availableRooms: 8,
    gateCode: 'UBP2025',
    liftFloors: [],
    wingCode: 'SINGH',
    wifiPwd: 'umaid1943jodhpur',
    phone: '+91 291 251 0101',
    checkInTime: '14:00',
    checkOutTime: '12:00',
  },

  {
    title: 'BrijRama Palace',
    location: 'Darbhanga Ghat, Munshi Ghat, Varanasi',
    city: 'Varanasi',
    state: 'Uttar Pradesh',
    country: 'India',
    category: 'Heritage Palace',
    heroImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAwer_1ympOeZ25ISp_IvZ3mCmcni6Gkp4mQR9VfLpfV1x-fGbDI9blINhKyRx04RneRphhnd-3co2Era7sMPi7QZh40w1eRVV3Ppi7COL4GLGAVN7j1pRNa_YS96GWZmFT8y1-kZfMrO5KGs=s1360-w1360-h1020',
    images: [
      'https://lh3.googleusercontent.com/proxy/sRXYUDt0YyR2OV6yiJGf596kpZEm4TSuK3886qrvw9yE5jbMu2ybLDzsbFJz1ccbpeu0MYE6ltOI1EiNBJFr8pEoojSm8pK35UdXt7B_bQzNnHlCvEUZ_-2RPYP-8o0MzFd2fXPrLxETWkF6g_7t1aZgKubuHg=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipPyQLP7hTSzYBNDEMIseTdF6v5dBULYe1vaPAHI=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweoUwJQsAtKuj1fkiSqP4UwKT-ZO6BIvzYTYJFCTIZ6V_IhMOdO-5zvAJHNF6Hm7qfKJAW4JjlE1h4x_Mjs7YZr1_rooBEOPLSm5lfYxyFp-Vtrm8szbM1T6AyCr8JoVYUDm1rdI2w=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwer8PTusSiQUGs_NdTZgWvlC46OCanLLM685PBN5rMqOIgmEpc_lWt2xqz7q1JknY7kDptj-wr_Ore4ixiuYgRCrk6VKoSXWi14vc-iCLZn6TITl5Q22vYEwKytekA1f2fra5icd-A=s1360-w1360-h1020',
    ],
    story: "Rising directly from the sacred ghats of the Ganges, BrijRama Palace is an 18th-century heritage haveli that has witnessed Varanasi's eternal rhythms for over 250 years. Originally the residence of the Darbhanga royal family, this eight-storeyed sandstone palace was painstakingly restored into a luxury hotel while preserving its original frescoes, carved balconies, and the uninterrupted view of the Ganga Aarti from its riverside terraces. To stay here is to watch the oldest continually inhabited city on Earth come alive — lamp by lamp — at dusk.",
    privileges: [
      { label: 'Private Ganga Aarti', detail: 'Reserved front-row boat viewing of the evening Ganga Aarti ceremony' },
      { label: 'Dawn Boat Ritual', detail: 'Exclusive sunrise boat ride along the ghats with personal guide' },
      { label: 'Vedic Ceremony', detail: 'Private puja and ritual bath arranged at Manikarnika Ghat' },
      { label: 'Rooftop Dining', detail: 'Candlelit dinner on the riverside terrace with panoramic Ganges view' },
    ],
    facilities: [
      'Riverside Terrace', 'Rooftop Restaurant', 'Spa & Ayurveda', 'Yoga Pavilion',
      'Heritage Library', 'Ghat Access', 'Concierge', 'Boat Transfers',
      'Private Puja Arrangements', 'Cultural Performances',
    ],
    roomTypes: [
      { name: 'Ganga Grand Suite',   price: 185000, capacity: 2, desc: 'Expansive suite with floor-to-ceiling river views, private balcony and antique four-poster bed' },
      { name: 'Heritage River Room', price: 72000,  capacity: 2, desc: 'Restored haveli room with original frescoes, carved jharokha balcony and direct Ganges vistas' },
      { name: 'Courtyard Deluxe',    price: 42000,  capacity: 2, desc: 'Elegant room overlooking the inner sandstone courtyard with hand-painted ceiling murals' },
      { name: 'Classic Room',        price: 26000,  capacity: 2, desc: 'Cosy room with traditional block-print textiles, terracotta accents and partial river glimpses' },
    ],
    basePrice: 42000,
    rating: 4.8,
    reviewCount: 341,
    distanceFromCity: 'On Munshi Ghat, Varanasi',
    coordinates: { lat: 25.3010, lng: 83.0104 },
    featured: true,
    panoramaImage: 'https://lh3.googleusercontent.com/proxy/TOPllNmnwrhKUHnEmYapC3AOfxuvMY4AB4g8ghHW2qN_KIsjl344KFKXHSuR2pMs9_Jvue6kgTFIkuFncE9G7VVx3Qxdcp5U0Lwm0VIVV06lJh-wiBnnj5h1gBtdq-ufrd0SUchMTjy8furmDYZNP3mPyTFQNQ=s1360-w1360-h1020',
    videoId360: '6gDBq8M_JOg',
    availableRooms: 7,
    gateCode: 'BRP2025',
    liftFloors: [],
    wingCode: 'DARBHANGA',
    wifiPwd: 'brijrama1743',
    phone: '+91 542 239 0700',
    checkInTime: '14:00',
    checkOutTime: '12:00',
  },

  {
    title: 'Fort JadhavGADH',
    location: 'Hadapsar, Pune',
    city: 'Pune',
    state: 'Maharashtra',
    country: 'India',
    category: 'Heritage Fort',
    heroImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAwep8c-OngNIGnNLzxsCkP5KNVTzT9EcAjWgv0a4dQb-pDt4cipq5UWKc4JU_ZOErpIkxT1h2BJ2w5hwR2eS1MiFBJRgKowvu1U_2Ro01esbOlYf_afjpV9zzCPCnsLXVlWpz4Gv1=s1360-w1360-h1020',
    images: [
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweoJGHxAp_YZQW4A8paruqkMMBdQeXGBu2alqs4oUuhZd3I2-LvKLZXL9lqmbA-FH6qrzBy0UmSrLfWKuvSgAtw3R50M8UE7T0TMGHPwF-1kDfEput-FeG62kTvgOVJSrjkc3lGz7A=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAweqLF3ZqmI1GBeHBUBzMDp1_ForbTzp2_-Arg4TYmNm0uOxHOliCuFL84VcLNd7CAiM8pKsDDYRPK95fWvB_gJsP1-amxzKaBwnw5ZwBPRl77EMnn2DDp-ZJwXYVIF_WaXgbZwZQPg=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/gps-cs-s/AHVAwep7fynQRRHVU_xT_mM5N8zL_ySEBlO_kAYq6RHH3-QoYRjq5uxTVOnqtnYxUTYsw5zp3wywccio6Qgc4O4UXQ-hTPvJu6JBjeDI33XJ5BzTbjeZaEK-NapQTEjXz1_eSFD6PPru=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipPqMaxjp0fFsEXAq8qJJWOo0ld-47wXyCyu7Kco=s1360-w1360-h1020',
    ],
    story: "Perched on a rocky promontory on the outskirts of Pune, Fort JadhavGADH is a 300-year-old Maratha-era fortification that has been reborn as a living heritage hotel. The Jadhav clan — loyal commanders in Chhatrapati Shivaji Maharaj's legendary cavalry — built this bastion to guard the Deccan plateau passes. Today its massive bastions, weathered ramparts and secret tunnels have been converted into 56 uniquely themed rooms, each named after a different Maratha warrior. The fort hosts regular Maratha cultural evenings, sword-fighting demonstrations and open-air performances under star-filled skies.",
    privileges: [
      { label: 'Maratha War Trail', detail: 'Guided heritage trek through original ramparts and secret tunnels' },
      { label: 'Sword & Shield Demo', detail: 'Private Maratha martial arts demonstration by resident instructors' },
      { label: 'Bonfire Courtyard', detail: 'Reserved bonfire setting inside the fort\'s inner bailey with folk music' },
      { label: 'Vintage Cannon Tour', detail: 'Exclusive guided tour of the fort\'s original artillery collection' },
    ],
    facilities: [
      'Heritage Pool', 'Spa & Wellness', 'Yoga Deck', 'Amphitheatre',
      'Maratha Cultural Shows', 'Rock Climbing Wall', 'ATV Trails', 'Archery Range',
      'Bonfire Pit', 'Heritage Museum', 'Banquet Lawns', 'Valet Parking',
    ],
    roomTypes: [
      { name: 'Bastion Suite',       price: 92000, capacity: 2, desc: 'Corner turret suite inside original fort bastion with 270° panoramic views of the Sahyadris' },
      { name: 'Warrior Heritage Room', price: 48000, capacity: 2, desc: 'Themed room named after a Maratha commander, with exposed stone walls and period armoury decor' },
      { name: 'Rampart Deluxe',      price: 32000, capacity: 2, desc: 'Elevated room built into the fort rampart wall with courtyard and hill views' },
      { name: 'Courtyard Room',      price: 20000, capacity: 2, desc: 'Cosy room opening onto the central fort courtyard, with terracotta floors and warm lantern lighting' },
    ],
    basePrice: 32000,
    rating: 4.7,
    reviewCount: 298,
    distanceFromCity: '18 km from Pune city centre',
    coordinates: { lat: 18.4843, lng: 73.9897 },
    featured: true,
    panoramaImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAweok-gxUwra7gMOVWMA2h3DWrcYgOLxuVck7KyydJh-n8vgbbX4NqsehQoQuZh-gb6VbJihj7Eh7EjEuWF9zEmhVXI07HcaM0axP5Q8NUImS1FsMHNvLHAgUnvaZ93XnmXv-FjQ=s1360-w1360-h1020',
    videoId360: 'fO4B0IvgLEE',
    availableRooms: 9,
    gateCode: 'FJG2025',
    liftFloors: [],
    wingCode: 'JADHAV',
    wifiPwd: 'fortjadhav1720',
    phone: '+91 20 6680 2222',
    checkInTime: '14:00',
    checkOutTime: '12:00',
  },

  {
    title: 'Kaldan Samudhra Palace',
    location: 'East Raja Street, Mahabalipuram',
    city: 'Mahabalipuram',
    state: 'Tamil Nadu',
    country: 'India',
    category: 'Beachside Palace',
    heroImage: 'https://lh3.googleusercontent.com/p/AF1QipNrv4zcic_4gmr3K4w0jgug75qZa-sGw3amRTRx=s1360-w1360-h1020',
    images: [
      'https://lh3.googleusercontent.com/p/AF1QipNhWi5b8lhQ_eJKIB-yZSjPuUvt8ZSg0ppVw8Gg=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipNuK048EkrBLp0jn0OqeqDYGQcVo9y23zPUnz_U=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipMFxM8-o8ose_XhqEZoo58r2A-uUaDVFZwiOPwU=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipPBhqz8XsLBfc0fjD7ZHXJmWpSOkj6yRK5lCpkQ=s1360-w1360-h1020',
    ],
    story: "Commanding an unbroken stretch of Coromandel coastline beside the ancient UNESCO-listed Shore Temple, Kaldan Samudhra Palace is a palacial retreat where Pallava-era stone carving traditions meet the Bay of Bengal. The Shore Temple complex, carved from granite by Pallava king Narasimhavarman II in the 8th century, lies just minutes on foot — guests fall asleep to the sound of waves breaking over the same rocks that ancient maritime traders once navigated. The palace takes its name from the old Tamil 'samudhra' meaning ocean, reflecting its identity as a house built for the sea.",
    privileges: [
      { label: 'Shore Temple Sunrise', detail: 'Private pre-dawn guided viewing of UNESCO Shore Temple before public access' },
      { label: 'Sculpture Workshop', detail: 'Personal session with local Mahabalipuram stone-carving masters' },
      { label: 'Sea Kayaking', detail: 'Private guided kayaking along the ancient Pallava coastline' },
      { label: 'Moonlit Beach Dinner', detail: 'Exclusive private dinner set up directly on the beach under the stars' },
    ],
    facilities: [
      'Beachfront Access', 'Infinity Pool', 'Spa & Ayurveda', 'Yoga Pavilion',
      'Water Sports Centre', 'Beach Restaurant', 'Cultural Tours', 'Bicycle Hire',
      'Concierge', 'Open-Air Terrace', 'Heritage Library',
    ],
    roomTypes: [
      { name: 'Ocean Palace Suite',  price: 88000, capacity: 2, desc: 'Top-floor suite with private plunge pool, unobstructed sea views and Tamil Nadu artisan decor' },
      { name: 'Sea-View Deluxe',     price: 44000, capacity: 2, desc: 'Spacious room with floor-to-ceiling glass opening onto a balcony facing the Bay of Bengal' },
      { name: 'Heritage Pool Room',  price: 32000, capacity: 2, desc: 'Ground-floor room with direct pool access, terracotta tile floors and Chola-inspired motifs' },
      { name: 'Garden Retreat',      price: 20000, capacity: 2, desc: 'Tranquil room set in lush coastal garden with verandah, outdoor shower and sea breeze' },
    ],
    basePrice: 32000,
    rating: 4.6,
    reviewCount: 214,
    distanceFromCity: 'Next to Shore Temple, Mahabalipuram',
    coordinates: { lat: 12.6172, lng: 80.1928 },
    featured: true,
    panoramaImage: 'https://lh3.googleusercontent.com/p/AF1QipOxlj0FWybNj_xbSqX0GR50KiGX0OttiXxHgLte=s1360-w1360-h1020',
    videoId360: 'F-HnBj5SJ2w',
    availableRooms: 8,
    gateCode: 'KSP2025',
    liftFloors: [],
    wingCode: 'PALLAVA',
    wifiPwd: 'samudhra1720',
    phone: '+91 44 2744 2222',
    checkInTime: '14:00',
    checkOutTime: '12:00',
  },

  {
    title: 'Hill Palace Hotel',
    location: 'Thrippunithura, Ernakulam, Kochi',
    city: 'Kochi',
    state: 'Kerala',
    country: 'India',
    category: 'Heritage Palace',
    heroImage: 'https://lh3.googleusercontent.com/p/AF1QipOyJRHrMKnQZDq_5qUPHp1umEMayOaTiB5dJgY_=s1360-w1360-h1020',
    images: [
      'https://lh3.googleusercontent.com/p/AF1QipPfBHN2CuOMd6a31uyPtBEYplh66XSuSt-kFCUM=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipM-eyqYLfWCbzuSlxKFUqwPCqBqUekSi6vH6zZd=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipNEh5nFoZ-VPO4lqAzPW770fsC8heq-ST6PwO31=s1360-w1360-h1020',
      'https://lh3.googleusercontent.com/p/AF1QipO-vojaDBxV-JCCqKSyxv6QsWkkDh0m3TUmGCEU=s1360-w1360-h1020',
    ],
    story: "Set on a verdant hilltop in Thrippunithura, the royal seat of the Cochin Royal Family, Hill Palace was the official residence of the Kochi Maharajas for over a century. The 49-acre estate — the largest archeological museum in Kerala — is a symphony of Kerala traditional architecture: sloping tiled roofs, carved wooden pillars, cool shaded verandahs and lotus-filled ponds scattered across gently rolling hills. The palace's private museum houses over 1,000 royal artefacts, manuscripts and coronation robes; to stay here is to occupy the same rooms where the last Maharaja of Cochin once received his court.",
    privileges: [
      { label: 'Royal Museum Access', detail: 'Private after-hours tour of Hill Palace\'s 1,000-piece royal artefact collection' },
      { label: 'Kathakali Performance', detail: 'Personal Kathakali dance-drama performance arranged in the palace courtyard' },
      { label: 'Backwater Cruise', detail: 'Exclusive sunset cruise on Vembanad Lake aboard a traditional kettuvallam houseboat' },
      { label: 'Ayurvedic Ritual', detail: 'Personalised Panchakarma consultation and treatment by royal Ayurvedic physicians' },
    ],
    facilities: [
      'Heritage Pool', 'Ayurveda Centre', 'Yoga Pavilion', 'Heritage Museum',
      'Royal Gardens', 'Kathakali Stage', 'Elephant Interactions', 'Backwater Tours',
      'Concierge', 'Heritage Library', 'Banquet Hall', 'Restaurant',
    ],
    roomTypes: [
      { name: 'Maharaja Suite',      price: 115000, capacity: 2, desc: 'Original royal chamber with carved rosewood furniture, private garden courtyard and panoramic hilltop views' },
      { name: 'Palace Heritage Room', price: 55000, capacity: 2, desc: 'Restored room with traditional Kerala murals, polished laterite floors and private tiled verandah' },
      { name: 'Garden Pavilion',     price: 36000, capacity: 2, desc: 'Standalone cottage set among the palace gardens with private sit-out and lotus pool views' },
      { name: 'Classic Room',        price: 22000, capacity: 2, desc: 'Elegant room with Kerala wood-panel ceilings, block-print textiles and garden outlook' },
    ],
    basePrice: 36000,
    rating: 4.7,
    reviewCount: 267,
    distanceFromCity: '12 km east of Kochi city centre',
    coordinates: { lat: 9.9541, lng: 76.3390 },
    featured: true,
    panoramaImage: 'https://lh3.googleusercontent.com/gps-cs-s/AHVAwep1KPCqhowiQnQG69qntz4L5PB0Vh9PJWsylz8hRz47T0xdynlF39N6Aq1JO_9r9caV_IHgMvwaXCr374R4WD9ZOYg2aVCioV8CClkcBlsBw-1mWnBaOJvXspZPuWrrUwCrUhFE=s1360-w1360-h1020',
    videoId360: 'Kz28ncARMo4',
    availableRooms: 9,
    gateCode: 'HPK2025',
    liftFloors: [],
    wingCode: 'COCHIN',
    wifiPwd: 'hillpalace1865',
    phone: '+91 484 277 8113',
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
