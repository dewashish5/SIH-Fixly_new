/** Default India center when no federation region. */
export const INDIA_MAP_CENTER = [22.9734, 78.6569];
export const DELHI_MAP_CENTER = [28.6139, 77.209];

/** Rough state capitals / centroids (India) — offline fallback. */
const STATE_CENTERS = {
  'andhra pradesh': [15.9129, 79.74],
  'arunachal pradesh': [28.218, 94.7278],
  assam: [26.2006, 92.9376],
  bihar: [25.0961, 85.3131],
  chhattisgarh: [21.2787, 81.8661],
  goa: [15.2993, 74.124],
  gujarat: [22.2587, 71.1924],
  haryana: [29.0588, 76.0856],
  'himachal pradesh': [31.1048, 77.1734],
  jharkhand: [23.6102, 85.2799],
  karnataka: [15.3173, 75.7139],
  kerala: [10.8505, 76.2711],
  'madhya pradesh': [22.9734, 78.6569],
  maharashtra: [19.7515, 75.7139],
  manipur: [24.6637, 93.9063],
  meghalaya: [25.467, 91.3662],
  mizoram: [23.1645, 92.9376],
  nagaland: [26.1584, 94.5624],
  odisha: [20.9517, 85.0985],
  orissa: [20.9517, 85.0985],
  punjab: [31.1471, 75.3412],
  rajasthan: [27.0238, 74.2179],
  sikkim: [27.533, 88.5122],
  'tamil nadu': [11.1271, 78.6569],
  telangana: [18.1124, 79.0193],
  tripura: [23.9408, 91.9882],
  'uttar pradesh': [26.8467, 80.9462],
  uttarakhand: [30.0668, 79.0193],
  'west bengal': [22.9868, 87.855],
  delhi: [28.6139, 77.209],
  'new delhi': [28.6139, 77.209],
  'nct of delhi': [28.6139, 77.209],
  'jammu and kashmir': [33.7782, 76.5762],
  ladakh: [34.1526, 77.577],
  puducherry: [11.9416, 79.8083],
  chandigarh: [30.7333, 76.7794],
};

const DISTRICT_CENTERS = {
  'bilaspur|chhattisgarh': [22.0797, 82.1391],
  'raipur|chhattisgarh': [21.2514, 81.6296],
  'durg|chhattisgarh': [21.1904, 81.2849],
  'south delhi|delhi': [28.5245, 77.2066],
  'south delhi|new delhi': [28.5245, 77.2066],
};

function normalize(s) {
  return String(s || '')
    .toLowerCase()
    .trim()
    .replace(/\s+/g, ' ');
}

function offlineCenter(district, state) {
  const d = normalize(district);
  const st = normalize(state);
  if (d && st && DISTRICT_CENTERS[`${d}|${st}`]) {
    return DISTRICT_CENTERS[`${d}|${st}`];
  }
  if (st && STATE_CENTERS[st]) return STATE_CENTERS[st];
  if (d && STATE_CENTERS[d]) return STATE_CENTERS[d];
  return null;
}

/**
 * Resolve [lat, lng] for federation district/state.
 * Tries offline table first, then Open-Meteo geocoding (CORS-friendly).
 */
export async function resolveRegionCenter(district, state) {
  const offline = offlineCenter(district, state);
  const cacheKey = `fixly_map_center:${normalize(district)}|${normalize(state)}`;
  try {
    const cached = sessionStorage.getItem(cacheKey);
    if (cached) {
      const parsed = JSON.parse(cached);
      if (Array.isArray(parsed) && parsed.length === 2) return parsed;
    }
  } catch (_) {
    /* ignore */
  }

  const queries = [];
  if (district && state) queries.push(`${district}, ${state}, India`);
  if (district) queries.push(`${district}, India`);
  if (state) queries.push(`${state}, India`);

  for (const name of queries) {
    try {
      const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(name)}&count=5&language=en&format=json`;
      const res = await fetch(url);
      if (!res.ok) continue;
      const data = await res.json();
      const results = Array.isArray(data?.results) ? data.results : [];
      const india = results.find((r) => (r.country_code || '').toUpperCase() === 'IN') || results[0];
      if (india && Number.isFinite(india.latitude) && Number.isFinite(india.longitude)) {
        const center = [india.latitude, india.longitude];
        try {
          sessionStorage.setItem(cacheKey, JSON.stringify(center));
        } catch (_) {
          /* ignore */
        }
        return center;
      }
    } catch (_) {
      /* try next */
    }
  }

  return offline || INDIA_MAP_CENTER;
}
