import mongoose from 'mongoose';

const appVersionSchema = new mongoose.Schema(
    {
        apiVersion: {
            type: String,
            required: true,
            default: 'V1',
            trim: true
        },
        appVersion: {
            type: String,
            default: '1.0.0',
            trim: true
        },
        minVersion: {
            type: String,
            default: 'V1',
            trim: true
        },
        forceUpdate: {
            type: Boolean,
            default: false
        },
        updateTitle: {
            type: String,
            default: 'Update Available',
            trim: true
        },
        updateMessage: {
            type: String,
            default: 'A new version of Fixly is available. Please update the app to continue.',
            trim: true
        },
        updateUrl: {
            type: String,
            default: '',
            trim: true
        },
        platform: {
            type: String,
            enum: ['all', 'android', 'ios'],
            default: 'all'
        },
        isActive: {
            type: Boolean,
            default: true,
            index: true
        }
    },
    {
        timestamps: true
    }
);

const AppVersion = mongoose.model('AppVersion', appVersionSchema);

export default AppVersion;
