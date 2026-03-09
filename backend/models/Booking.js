const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: true,
    },
    estate: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Estate',
        required: true,
    },
    checkInDate: {
        type: Date,
        required: true,
    },
    checkOutDate: {
        type: Date,
    },
    guests: {
        type: Number,
        default: 2,
    },
    roomType: {
        type: String,
        default: 'Deluxe',
    },
    roomNumber: {
        type: String,
    },
    floorNumber: {
        type: Number,
    },
    specialRequest: {
        type: String,
    },
    addOns: {
        type: Array,
        default: [],
    },
    totalAmount: {
        type: Number,
        required: true,
    },
    tenderDetails: {
        type: String,
        default: 'Card',
    },
    status: {
        type: String,
        enum: ['Pending', 'Confirmed', 'Completed', 'Cancelled'],
        default: 'Confirmed',
    },
    paymentId: {
        type: String,
    },
    qrToken: {
        type: String,
    },
    qrData: {
        type: String,
    },
    vehicleNumber: {
        type: String,
    },
}, { timestamps: true });

module.exports = mongoose.model('Booking', bookingSchema);
