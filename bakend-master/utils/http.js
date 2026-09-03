export const fail = (res, status, code, message, details) =>
    res.status(status).json({
        success: false,
        code,
        message,
        ...(details ? { details } : {}),
    });

export const ok = (res, payload = {}, status = 200) =>
    res.status(status).json({ success: true, ...payload });

export const maskId = (value) => {
    if (!value || typeof value !== 'string') return null;
    if (value.length <= 4) return '****';
    return `${'*'.repeat(Math.max(0, value.length - 4))}${value.slice(-4)}`;
};

export const isObjectId = (id) => /^[a-fA-F0-9]{24}$/.test(String(id || ''));
