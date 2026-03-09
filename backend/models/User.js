const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
    phoneNumber: {
        type: String,
        required: true,
        unique: true,
    },
    role: {
        type: String,
        enum: ['guest', 'elite', 'admin'],
        default: 'guest',
    },
    documentType: {
        type: String,
    },
    documentId: {
        type: String,
    },
    isVerified: {
        type: Boolean,
        default: false,
    },
    preferences: {
        type: [String],
        default: [],
    }
}, { timestamps: true });

module.exports = mongoose.model('User', userSchema);
