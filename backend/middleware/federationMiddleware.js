import User from '../models/User.js';

export function federationScope(req, res, next) {
  // Super admin sees everything (no filter)
  if (req.user.adminRole === 'super_admin') {
    req.federationFilter = {};
    return next();
  }
  // Federation admin sees only their federation's data
  if (req.user.adminRole === 'federation_admin' && req.user.federation) {
    req.federationFilter = { federation: req.user.federation };
    return next();
  }
  // Default: no access
  return res.status(403).json({ success: false, message: 'Federation access denied' });
}
