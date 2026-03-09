const mongoose = require('mongoose');

const estateSchema = new mongoose.Schema({
    title:            { type: String, required: true },
    location:         { type: String, required: true },
    city:             { type: String, default: '' },
    state:            { type: String, default: '' },
    country:          { type: String, default: 'India' },
    category: {
        type: String,
        enum: ['Palace', 'Sanctuary', 'Fortress', 'Private Island', 'Heritage Estate',
               'Beach', 'Mountain', 'Desert', 'Forest', 'Heritage'],
        required: true,
    },
    heroImage:        { type: String, required: true },
    images:           { type: [String], default: [] },
    roomImages:       { type: Map, of: [String], default: {} },
    story:            { type: String, required: true },
    privileges: [{
        label:  String,
        detail: String,
    }],
    facilities:       { type: [String], default: [] },
    roomTypes: [{
        name:     String,
        price:    Number,
        capacity: Number,
        desc:     String,
    }],
    basePrice:        { type: Number, required: true },
    rating:           { type: Number, default: 4.8 },
    reviewCount:      { type: Number, default: 0 },
    distanceFromCity: { type: String, default: '' },
    coordinates: {
        lat: { type: Number },
        lng: { type: Number },
    },
    featured:         { type: Boolean, default: false },
    panoramaImage:    { type: String, default: '' },
    videoId360:       { type: String, default: '' },
    availableRooms:   { type: Number, default: 0 },
    gateCode:         { type: String, default: '' },
    liftFloors:       { type: [Number], default: [] },
    wingCode:         { type: String, default: '' },
    wifiPwd:          { type: String, default: '' },
    phone:            { type: String, default: '' },
    checkInTime:      { type: String, default: '14:00' },
    checkOutTime:     { type: String, default: '12:00' },
}, { timestamps: true });

module.exports = mongoose.model('Estate', estateSchema);
