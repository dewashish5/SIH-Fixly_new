import { apiClient, getDeviceId, setAuthSession } from './client';

const PLACEHOLDER_AVATAR =
  'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=120&auto=format&fit=crop&q=80';

function fmtMoney(n) {
  const num = Number(n) || 0;
  return `₹${num.toLocaleString('en-IN')}`;
}

function formatDate(value) {
  if (!value) return '—';
  try {
    return new Date(value).toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'short',
      year: 'numeric',
    });
  } catch {
    return String(value);
  }
}

function coordsFromLocation(location) {
  // GeoJSON: [lng, lat] → UI Leaflet [lat, lng]
  const c = location?.coordinates;
  if (Array.isArray(c) && c.length >= 2) {
    return [c[1], c[0]];
  }
  return [28.5355, 77.391];
}

function mapKycToVerification(worker) {
  const kyc =
    worker.kycStatus ||
    worker.workerProfile?.kycStatus ||
    (worker.workerProfile?.verified === true || worker.isVerified ? 'verified' : 'pending');

  const raw = String(kyc).toLowerCase();
  if (raw === 'approved' || raw === 'verified') return 'Verified';
  if (raw === 'rejected') return 'Rejected';
  if (raw === 'suspended') return 'Suspended';
  return 'Pending';
}

/** Map backend User(worker) → admin UI worker row */
export function mapWorker(w) {
  const wp = w.workerProfile || {};
  const id = w._id || w.id;
  return {
    id: String(id),
    name: w.name || '—',
    service: wp.category || w.category || 'General',
    skills: Array.isArray(wp.skills) ? wp.skills : [],
    location: w.address || wp.bio || 'Location not set',
    city: w.city || '—',
    coordinates: coordsFromLocation(w.location),
    rating: Number(wp.rating ?? 5),
    totalReviews: Number(wp.totalReviews ?? 0),
    completedJobs: Number(wp.totalJobs ?? 0),
    availability: w.availability || 'Available',
    verification: mapKycToVerification(w),
    phone: w.phone || '—',
    email: w.email || '—',
    experience: wp.experienceYears != null ? `${wp.experienceYears} Years` : '—',
    certifications: Array.isArray(wp.certifications) ? wp.certifications : [],
    hourlyRate: wp.hourlyRate != null ? `${fmtMoney(wp.hourlyRate)}/hr` : '—',
    avatar: w.avatar || PLACEHOLDER_AVATAR,
    idProof: w.isVerified ? 'Verified' : 'Pending',
    insuranceStatus: mapKycToVerification(w) === 'Verified' ? 'Active (₹5L Policy)' : 'Pending',
    joinedDate: formatDate(w.createdAt),
    todayEarnings: '₹0',
    lifetimeEarnings: '₹0',
    battery: '—',
    raw: w,
  };
}

/** Map backend User(customer) → admin UI customer row */
export function mapCustomer(c) {
  const id = c._id || c.id;
  const addr = c.savedAddresses?.[0];
  return {
    id: String(id),
    name: c.name || '—',
    phone: c.phone || '—',
    email: c.email || '—',
    address: addr?.addressLine || '—',
    city: addr?.city || '—',
    totalBookings: Number(c.totalBookings ?? 0),
    totalSpent: fmtMoney(c.totalSpent ?? 0),
    rawSpent: Number(c.totalSpent ?? 0),
    rating: Number(c.rating ?? 5),
    status: c.status || (c.isVerified ? 'Active' : 'Active'),
    memberSince: formatDate(c.createdAt),
    preferredServices: c.preferredServices || [],
    recentBookingId: c.recentBookingId || null,
    raw: c,
  };
}

const STATUS_MAP = {
  SEARCHING: 'Pending',
  ACCEPTED: 'Assigned',
  ARRIVED: 'Confirmed',
  IN_PROGRESS: 'In Progress',
  COMPLETED: 'Completed',
  CANCELLED: 'Cancelled',
};

/** Map backend Booking → admin UI booking row */
export function mapBooking(b) {
  const id = b.bookingId || b._id || b.id;
  const customer = typeof b.customer === 'object' && b.customer ? b.customer : null;
  const worker = typeof b.worker === 'object' && b.worker ? b.worker : null;
  const service = typeof b.service === 'object' && b.service ? b.service : null;
  const total = b.invoice?.totalAmount ?? 0;
  const platform = b.invoice?.platformFee ?? 0;

  return {
    id: String(id).replace(/^#/, ''),
    customer: customer?.name || '—',
    customerPhone: customer?.phone || '—',
    customerEmail: customer?.email || '—',
    customerAddress: b.serviceAddress?.addressLine || '—',
    city: '—',
    service: service?.category || service?.title || '—',
    serviceType: service?.title || b.problemDescription || '—',
    workerId: worker ? String(worker._id || worker.id) : null,
    worker: worker?.name || 'Unassigned',
    workerPhone: worker?.phone || '—',
    workerRating: worker?.workerProfile?.rating ?? 0,
    status: STATUS_MAP[b.status] || b.status || 'Pending',
    amount: fmtMoney(total),
    rawAmount: Number(total),
    welfareCut: fmtMoney(platform),
    workerPayout: fmtMoney(Math.max(0, total - platform)),
    time: formatDate(b.scheduledTime || b.createdAt),
    date: formatDate(b.scheduledTime || b.createdAt),
    paymentMethod: b.invoice?.paymentMethod || 'UPI',
    paymentStatus:
      b.invoice?.paymentStatus === 'PAID'
        ? 'Paid'
        : b.invoice?.paymentStatus === 'FAILED'
          ? 'Failed'
          : 'Pending',
    isEmergency: false,
    insuranceCovered: false,
    scheduledSlot: formatDate(b.scheduledTime),
    notes: b.problemDescription || '',
    raw: b,
  };
}

/** Map backend Service → admin UI service row */
export function mapService(s) {
  const id = s._id || s.id;
  return {
    id: String(id),
    name: s.title || s.name || '—',
    category: s.category || '—',
    description: Array.isArray(s.whatsIncluded)
      ? s.whatsIncluded.join(', ')
      : s.description || '',
    basePrice: fmtMoney(s.basePrice),
    rawPrice: Number(s.basePrice ?? 0),
    requiredSkills: '—',
    availability: s.estimatedTime || '—',
    emergencyAvailable: false,
    status: s.isActive === false ? 'Inactive' : 'Active',
    activeWorkers: 0,
    completedTasks: '0',
    avgRating: 5.0,
    percentage: 10,
    icon: 'Layers',
    iconColor: '#0284c7',
    bg: '#f0f9ff',
    coopWelfarePercent: 5,
    raw: s,
  };
}

function unwrapList(data, keys = []) {
  if (Array.isArray(data)) return data;
  for (const k of keys) {
    if (Array.isArray(data?.[k])) return data[k];
  }
  if (Array.isArray(data?.data)) return data.data;
  return [];
}

export async function login(email, password) {
  const deviceId = getDeviceId();
  const data = await apiClient('/api/auth/login', {
    method: 'POST',
    auth: false,
    body: {
      email,
      password,
      deviceId,
      location: { type: 'Point', coordinates: [77.391, 28.5355] },
    },
  });

  const accessToken = data.accessToken || data.token;
  const refreshToken = data.refreshToken;
  const user = data.user || {};
  const userId = user._id || user.id || data.userId;

  if (!accessToken) {
    throw new Error('Login succeeded but no accessToken returned');
  }

  setAuthSession({ accessToken, refreshToken, userId: userId ? String(userId) : null });
  return { user, accessToken, refreshToken, userId };
}

export async function listWorkers(kyc = 'all') {
  const data = await apiClient(`/api/admin/workers?kyc=${encodeURIComponent(kyc)}`);
  return unwrapList(data, ['workers', 'data']).map(mapWorker);
}

export async function verifyWorker(id, status = 'approved') {
  return apiClient(`/api/admin/workers/${id}/kyc`, {
    method: 'PATCH',
    body: { status },
  });
}

export async function listCustomers() {
  const data = await apiClient('/api/admin/customers');
  return unwrapList(data, ['customers', 'users', 'data']).map(mapCustomer);
}

export async function listBookings() {
  const data = await apiClient('/api/admin/bookings');
  return unwrapList(data, ['bookings', 'data']).map(mapBooking);
}

export async function listServices() {
  const data = await apiClient('/api/admin/services');
  return unwrapList(data, ['services', 'data']).map(mapService);
}

export async function stats() {
  const data = await apiClient('/api/admin/stats');
  return data?.stats || data?.data || data || {};
}
