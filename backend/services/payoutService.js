import axios from 'axios';

export const processRazorpayPayout = async (payoutId, amount, upiId, workerName) => {
    const key = process.env.RAZORPAY_KEY_ID;
    const secret = process.env.RAZORPAY_KEY_SECRET;
    
    if (!key || !secret) {
        throw new Error('Razorpay credentials missing');
    }

    const auth = Buffer.from(`${key}:${secret}`).toString('base64');
    
    try {
        const contactRes = await axios.post('https://api.razorpay.com/v1/contacts', {
            name: workerName || 'Worker',
            type: 'employee',
            reference_id: `worker_${Date.now()}`
        }, {
            headers: { Authorization: `Basic ${auth}` }
        });
        
        const contactId = contactRes.data.id;
        
        const fundRes = await axios.post('https://api.razorpay.com/v1/fund_accounts', {
            contact_id: contactId,
            account_type: 'vpa',
            vpa: {
                address: upiId
            }
        }, {
            headers: { Authorization: `Basic ${auth}` }
        });
        
        const fundAccountId = fundRes.data.id;
        
        const payoutRes = await axios.post('https://api.razorpay.com/v1/payouts', {
            account_number: process.env.RAZORPAYX_ACCOUNT_NUMBER || '2323230058569805',
            fund_account_id: fundAccountId,
            amount: Math.round(amount * 100),
            currency: 'INR',
            mode: 'UPI',
            purpose: 'payout',
            queue_if_low_balance: true,
            reference_id: payoutId.toString()
        }, {
            headers: { Authorization: `Basic ${auth}` }
        });
        
        return payoutRes.data;
    } catch (error) {
        if (error.response && error.response.data) {
            throw new Error(error.response.data.error?.description || 'Razorpay payout failed');
        }
        throw error;
    }
};
