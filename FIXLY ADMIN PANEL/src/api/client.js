const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

const TOKEN_KEY = 'fixly_admin_token';
const REFRESH_KEY = 'fixly_admin_refresh';
const USER_ID_KEY = 'fixly_admin_user_id';
const DEVICE_KEY = 'fixly_admin_device_id';

export function getToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function getRefreshToken() {
  return localStorage.getItem(REFRESH_KEY);
}

export function getUserId() {
  return localStorage.getItem(USER_ID_KEY);
}

export function getDeviceId() {
  let id = localStorage.getItem(DEVICE_KEY);
  if (!id) {
    id = `admin-web-${crypto.randomUUID?.() || `${Date.now()}-${Math.random().toString(36).slice(2)}`}`;
    localStorage.setItem(DEVICE_KEY, id);
  }
  return id;
}

export function setAuthSession({ accessToken, refreshToken, userId }) {
  if (accessToken) localStorage.setItem(TOKEN_KEY, accessToken);
  if (refreshToken) localStorage.setItem(REFRESH_KEY, refreshToken);
  if (userId) localStorage.setItem(USER_ID_KEY, userId);
}

export function clearAuthSession() {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(REFRESH_KEY);
  localStorage.removeItem(USER_ID_KEY);
}

export function isLoggedIn() {
  return Boolean(getToken());
}

/**
 * Fetch wrapper — JSON + Bearer from localStorage.
 * @param {string} path - Absolute path starting with /api/...
 * @param {{ method?: string, body?: unknown, auth?: boolean, headers?: Record<string,string> }} [options]
 */
export async function apiClient(path, options = {}) {
  const { method = 'GET', body, auth = true, headers: extraHeaders = {} } = options;

  const headers = {
    Accept: 'application/json',
    ...extraHeaders,
  };

  if (body !== undefined) {
    headers['Content-Type'] = 'application/json';
  }

  if (auth) {
    const token = getToken();
    if (token) headers.Authorization = `Bearer ${token}`;
    headers['x-device-id'] = getDeviceId();
  }

  const res = await fetch(`${BASE_URL}${path}`, {
    method,
    headers,
    body: body !== undefined ? JSON.stringify(body) : undefined,
  });

  let data = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = { message: text };
    }
  }

  if (!res.ok) {
    const err = new Error(data?.message || `Request failed (${res.status})`);
    err.status = res.status;
    err.data = data;
    throw err;
  }

  return data;
}

export { BASE_URL, TOKEN_KEY };
