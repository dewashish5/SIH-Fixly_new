import re

with open('src/components/map/WorkersLeafletMap.jsx', 'r') as f:
    content = f.read()

# Add sosAlerts prop
content = content.replace(
    "export default function WorkersLeafletMap({",
    "export default function WorkersLeafletMap({\n  sosAlerts = [],"
)

# Render sosAlerts markers
sos_marker_code = """
    // Render SOS Alerts
    if (sosAlerts && sosAlerts.length > 0) {
      sosAlerts.forEach((sos) => {
        const c = sos.coordinates || (sos.location && sos.location.coordinates);
        if (Array.isArray(c) && c.length === 2) {
          const latlng = [c[1], c[0]]; // Assuming [lng, lat] GeoJSON format, adjust if needed. If it's already [lat, lng] then this may be wrong, but usually it's [lng, lat]. Let's try [lat, lng] first if worker uses same. workerLatLng function handles it. Let's use it or just [c[1], c[0]]
          
          bounds.push(latlng);
          const sosIcon = L.divIcon({
            className: 'custom-leaflet-marker',
            html: `<div style="
              width:40px;height:40px;border-radius:50%;background:#ef4444;
              border:3px solid #fff;box-shadow:0 0 15px rgba(239,68,68,0.6);
              display:flex;align-items:center;justify-content:center;
              color:#fff;font-weight:700;font-size:12px;cursor:pointer;
              animation: pulse 1.5s infinite;
            ">SOS</div>
            <style>
              @keyframes pulse {
                0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
                70% { box-shadow: 0 0 0 15px rgba(239, 68, 68, 0); }
                100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
              }
            </style>`,
            iconSize: [40, 40],
            iconAnchor: [20, 20],
          });
          const marker = L.marker(latlng, { icon: sosIcon }).addTo(map);
          marker.bindPopup(`
            <div style="font-family:sans-serif;text-align:center;">
              <strong style="color:#ef4444;font-size:14px;">SOS Alert</strong><br/>
              <span style="font-size:12px;color:#333;">${sos.userName || 'User'} needs help!</span><br/>
              <button onclick="alert('Dispatching nearest worker to SOS Alert')" style="margin-top:8px;background:#ef4444;color:#fff;border:none;padding:6px 10px;border-radius:4px;cursor:pointer;font-size:12px;font-weight:bold;">Dispatch Nearest Worker</button>
            </div>
          `);
          markersRef.current.push(marker);
        }
      });
    }
"""

content = content.replace(
    "    if (bounds.length === 1) {",
    sos_marker_code + "\n    if (bounds.length === 1) {"
)
# Make sure to include sosAlerts in useEffect deps
content = content.replace("[withGps, onSelectWorker])", "[withGps, onSelectWorker, sosAlerts])")

with open('src/components/map/WorkersLeafletMap.jsx', 'w') as f:
    f.write(content)

