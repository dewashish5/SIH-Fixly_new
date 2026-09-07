import Cooperative from '../models/Cooperative.js';
import CooperativeSociety from '../models/CooperativeSociety.js';
import User from '../models/User.js';
import { fail, ok } from '../utils/http.js';

const getOrCreate = async () => {
    let doc = await Cooperative.findOne({ active: true });
    if (!doc) doc = await Cooperative.create({});
    return doc;
};

export const getCooperativeInfo = async (_req, res) => {
    try {
        const info = await getOrCreate();
        const societiesCount = await CooperativeSociety.countDocuments({ active: true });
        return ok(res, {
            data: {
                ...info.toObject ? info.toObject() : info,
                societiesCount
            }
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getMyMembership = async (req, res) => {
    try {
        if (req.user.role !== 'worker') return fail(res, 403, 'FORBIDDEN', 'Worker role required');
        const federation = await getOrCreate();
        const worker = await User.findById(req.user.id)
            .select('name isVerified createdAt workerProfile')
            .populate('workerProfile.society');

        const society = worker?.workerProfile?.society || null;
        const societyMemberId = worker?.workerProfile?.societyMemberId || null;

        return ok(res, {
            data: {
                member: Boolean(worker),
                verified: Boolean(worker?.isVerified),
                joinedAt: worker?.createdAt,
                societyMemberId,
                society,
                federation,
                cooperative: federation,
            },
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const listSocieties = async (req, res) => {
    try {
        const { state, district, search } = req.query;
        const query = { active: true };
        if (state) query.state = new RegExp(state, 'i');
        if (district) query.district = new RegExp(district, 'i');
        if (search) {
            query.$or = [
                { name: new RegExp(search, 'i') },
                { registrationNumber: new RegExp(search, 'i') },
                { district: new RegExp(search, 'i') },
            ];
        }

        const societies = await CooperativeSociety.find(query).sort({ createdAt: -1 });
        return ok(res, { data: societies, count: societies.length });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const getSocietyById = async (req, res) => {
    try {
        const { id } = req.params;
        const society = await CooperativeSociety.findById(id);
        if (!society) {
            return fail(res, 404, 'NOT_FOUND', 'Cooperative Society not found');
        }

        const workers = await User.find({
            role: 'worker',
            'workerProfile.society': society._id
        }).select('name phone avatar isVerified workerProfile.category workerProfile.societyMemberId rating');

        return ok(res, {
            data: {
                society,
                members: workers,
                membersCount: workers.length
            }
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminGetCooperative = async (_req, res) => {
    try {
        const doc = await getOrCreate();
        const societiesCount = await CooperativeSociety.countDocuments({ active: true });
        const totalWorkersCount = await User.countDocuments({ role: 'worker' });
        return ok(res, {
            data: {
                ...doc.toObject ? doc.toObject() : doc,
                societiesCount,
                totalWorkersCount
            }
        });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminUpdateCooperative = async (req, res) => {
    try {
        const info = await getOrCreate();
        const fields = [
            'name', 'federationName', 'registrationNumber', 'state', 'district', 'commissionRate',
            'welfareContributionRate', 'insuranceEnabled', 'fairWagePolicy', 'active',
            'minimumWageFloor', 'emergencySurchargePercent', 'emergencySurchargeFixed', 'welfareBalance'
        ];
        for (const key of fields) {
            if (req.body[key] !== undefined) {
                if (key === 'minimumWageFloor' && typeof req.body[key] === 'object') {
                    info.minimumWageFloor = req.body[key];
                } else {
                    info[key] = req.body[key];
                }
            }
        }
        await info.save();
        return ok(res, { data: info, message: 'Cooperative Federation settings updated successfully!' });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

export const adminCooperativeMembers = async (_req, res) => {
    try {
        const workers = await User.find({ role: 'worker' })
            .select('name email phone isVerified createdAt workerProfile.category workerProfile.society workerProfile.societyMemberId')
            .populate('workerProfile.society', 'name registrationNumber district state');
        return ok(res, { data: workers });
    } catch (error) {
        return fail(res, 500, 'INTERNAL_ERROR', error.message);
    }
};

// Admin: List all primary cooperative societies
export const adminListSocieties = async (req, res) => {
    try {
        const { state, district, search } = req.query;
        const query = {};
        if (state) query.state = new RegExp(state, 'i');
        if (district) query.district = new RegExp(district, 'i');
        if (search) {
            query.$or = [
                { name: new RegExp(search, 'i') },
                { registrationNumber: new RegExp(search, 'i') },
                { district: new RegExp(search, 'i') },
            ];
        }

        const societies = await CooperativeSociety.find(query).sort({ createdAt: -1 });
        return res.status(200).json({ success: true, count: societies.length, societies, data: societies });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Create new primary cooperative society
export const adminCreateSociety = async (req, res) => {
    try {
        const {
            name,
            registrationNumber,
            state,
            district,
            wardOrArea,
            officeAddress,
            contactPhone,
            presidentName,
            secretaryName,
            fairWageComplianceScore
        } = req.body;

        if (!name || !registrationNumber || !state || !district) {
            return res.status(400).json({
                success: false,
                message: 'Name, registrationNumber, state, and district are required'
            });
        }

        const existing = await CooperativeSociety.findOne({
            registrationNumber: registrationNumber.toUpperCase().trim()
        });
        if (existing) {
            return res.status(400).json({
                success: false,
                message: `Society with registration '${registrationNumber.toUpperCase()}' already exists`
            });
        }

        const federation = await getOrCreate();
        const society = await CooperativeSociety.create({
            name: name.trim(),
            registrationNumber: registrationNumber.toUpperCase().trim(),
            state: state.trim(),
            district: district.trim(),
            wardOrArea: wardOrArea || '',
            officeAddress: officeAddress || '',
            contactPhone: contactPhone || '',
            presidentName: presidentName || '',
            secretaryName: secretaryName || '',
            fairWageComplianceScore: Number(fairWageComplianceScore) || 100,
            federation: federation._id,
            activeMembersCount: 0,
            active: true
        });

        return res.status(201).json({
            success: true,
            message: 'Primary Cooperative Society created successfully',
            society
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Get Society by ID with affiliated members
export const adminGetSocietyById = async (req, res) => {
    try {
        const { id } = req.params;
        const society = await CooperativeSociety.findById(id);
        if (!society) {
            return res.status(404).json({ success: false, message: 'Cooperative Society not found' });
        }

        const workers = await User.find({
            role: 'worker',
            'workerProfile.society': society._id
        }).select('name phone email avatar isVerified workerProfile rating createdAt');

        return res.status(200).json({
            success: true,
            society,
            workers,
            membersCount: workers.length
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Update Primary Cooperative Society
export const adminUpdateSociety = async (req, res) => {
    try {
        const { id } = req.params;
        const society = await CooperativeSociety.findById(id);
        if (!society) {
            return res.status(404).json({ success: false, message: 'Cooperative Society not found' });
        }

        const updates = { ...req.body };
        if (updates.registrationNumber) {
            updates.registrationNumber = updates.registrationNumber.toUpperCase().trim();
        }

        const updated = await CooperativeSociety.findByIdAndUpdate(id, updates, { new: true });
        return res.status(200).json({
            success: true,
            message: 'Cooperative Society updated successfully',
            society: updated
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};

// Admin: Assign worker to primary cooperative society
export const adminAssignWorkerToSociety = async (req, res) => {
    try {
        const { workerId, societyId, societyMemberId } = req.body;
        if (!workerId || !societyId) {
            return res.status(400).json({
                success: false,
                message: 'workerId and societyId are required'
            });
        }

        const society = await CooperativeSociety.findById(societyId);
        if (!society) {
            return res.status(404).json({ success: false, message: 'Society not found' });
        }

        const worker = await User.findById(workerId);
        if (!worker || worker.role !== 'worker') {
            return res.status(404).json({ success: false, message: 'Worker not found' });
        }

        const memberId = societyMemberId || `MEM-${society.district.substring(0, 3).toUpperCase()}-${Date.now().toString().slice(-4)}`;

        worker.workerProfile = worker.workerProfile || {};
        worker.workerProfile.society = society._id;
        worker.workerProfile.societyMemberId = memberId;
        await worker.save();

        const count = await User.countDocuments({
            role: 'worker',
            'workerProfile.society': society._id
        });
        society.activeMembersCount = count;
        await society.save();

        return res.status(200).json({
            success: true,
            message: `Worker assigned to ${society.name} with Member ID: ${memberId}`,
            data: {
                workerId: worker._id,
                societyId: society._id,
                societyMemberId: memberId,
                societyName: society.name
            }
        });
    } catch (error) {
        return res.status(500).json({ success: false, message: error.message });
    }
};
