import EmergencyContact from '../models/EmergencyContact.js';
import User from '../models/User.js';

export const getEmergencyContacts = async (req, res) => {
    try {
        const userId = req.user?.id;
        let federationId = null;
        
        if (userId) {
            const user = await User.findById(userId).lean();
            federationId = user?.federation || null;
        }

        const query = { isActive: true };
        if (federationId) {
            query.$or = [{ federation: null }, { federation: federationId }];
        } else {
            query.federation = null;
        }

        const contacts = await EmergencyContact.find(query).sort({ priority: -1, name: 1 });
        return res.status(200).json({ success: true, data: contacts, contacts });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const getAllEmergencyContacts = async (req, res) => {
    try {
        const contacts = await EmergencyContact.find().sort({ priority: -1, createdAt: -1 });
        return res.status(200).json({ success: true, data: contacts, contacts });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const createEmergencyContact = async (req, res) => {
    try {
        const contact = await EmergencyContact.create(req.body);
        return res.status(201).json({ success: true, data: contact, contact, message: 'Emergency contact created' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const updateEmergencyContact = async (req, res) => {
    try {
        const { id } = req.params;
        const contact = await EmergencyContact.findByIdAndUpdate(id, req.body, { new: true, runValidators: true });
        if (!contact) return res.status(404).json({ success: false, message: 'Emergency contact not found' });
        return res.status(200).json({ success: true, data: contact, contact, message: 'Emergency contact updated' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const deleteEmergencyContact = async (req, res) => {
    try {
        const { id } = req.params;
        const contact = await EmergencyContact.findByIdAndDelete(id);
        if (!contact) return res.status(404).json({ success: false, message: 'Emergency contact not found' });
        return res.status(200).json({ success: true, message: 'Emergency contact deleted' });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

export const seedDefaultContacts = async (req, res) => {
    try {
        const defaultContacts = [
            { name: 'Police', nameI18n: { en: 'Police', hi: 'पुलिस' }, phoneNumber: '100', category: 'police', priority: 100 },
            { name: 'Fire', nameI18n: { en: 'Fire', hi: 'अग्निशमन' }, phoneNumber: '101', category: 'fire', priority: 90 },
            { name: 'Ambulance', nameI18n: { en: 'Ambulance', hi: 'एम्बुलेंस' }, phoneNumber: '108', category: 'ambulance', priority: 95 },
            { name: 'Women Helpline', nameI18n: { en: 'Women Helpline', hi: 'महिला हेल्पलाइन' }, phoneNumber: '1091', category: 'women_helpline', priority: 80 },
            { name: 'Disaster Management', nameI18n: { en: 'Disaster Management', hi: 'आपदा प्रबंधन' }, phoneNumber: '1078', category: 'disaster', priority: 70 },
            { name: 'FIXLY Support', nameI18n: { en: 'FIXLY Support', hi: 'फिक्सली सहायता' }, phoneNumber: '1800-123-4567', category: 'fixly_support', priority: 50 }
        ];

        let seededCount = 0;
        for (const contact of defaultContacts) {
            const exists = await EmergencyContact.findOne({ phoneNumber: contact.phoneNumber });
            if (!exists) {
                await EmergencyContact.create(contact);
                seededCount++;
            }
        }

        return res.status(200).json({ success: true, message: `Seeded ${seededCount} default emergency contacts` });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
