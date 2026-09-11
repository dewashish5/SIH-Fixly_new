import { useEffect, useState } from 'react';
import { useApp } from '../context/AppContext';
import { api } from '../services/api';
import { DELHI_MAP_CENTER, resolveRegionCenter } from './regionMapCenter';

/**
 * Federation admins → map centers on their state/district.
 * Super admin → Delhi default (national HQ view).
 */
export function useFederationMapCenter() {
  const { adminRole, adminUser } = useApp();
  const [center, setCenter] = useState(DELHI_MAP_CENTER);
  const [zoom, setZoom] = useState(11);
  const [label, setLabel] = useState('');

  useEffect(() => {
    let cancelled = false;

    const run = async () => {
      if (adminRole !== 'federation_admin') {
        if (!cancelled) {
          setCenter(DELHI_MAP_CENTER);
          setZoom(11);
          setLabel('');
        }
        return;
      }

      const federationId =
        typeof adminUser?.federation === 'object' && adminUser?.federation !== null
          ? adminUser.federation._id || adminUser.federation.id
          : adminUser?.federation;
      if (!federationId) return;

      try {
        const res = await api.getFederationDetails(federationId);
        const fed = res?.data || res;
        const district = fed?.district || '';
        const state = fed?.state || '';
        if (!district && !state) return;

        const resolved = await resolveRegionCenter(district, state);
        if (cancelled) return;
        setCenter(resolved);
        setZoom(district ? 11 : 8);
        setLabel([district, state].filter(Boolean).join(', '));
      } catch (err) {
        console.warn('Federation map center failed:', err);
      }
    };

    run();
    return () => {
      cancelled = true;
    };
  }, [adminRole, adminUser?.federation]);

  return { center, zoom, label };
}
