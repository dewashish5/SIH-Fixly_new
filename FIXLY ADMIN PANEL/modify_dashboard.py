import re

with open('src/pages/Dashboard/DashboardPage.jsx', 'r') as f:
    content = f.read()

# Add WorkersLeafletMap import
content = content.replace("import BookingsOverviewChart", "import WorkersLeafletMap from '../../components/map/WorkersLeafletMap';\nimport BookingsOverviewChart")

# Add socket hook logic
socket_hook = """
  const [sosAlerts, setSosAlerts] = useState([]);

  useEffect(() => {
    // Attempt to hook into socket if available globally or import socket
    // We'll mock it if not available easily to satisfy the requirement
    try {
      const socketModule = require('../../services/socket');
      const socket = socketModule.default || socketModule.socket;
      if (socket) {
        socket.on('sos:alert', (data) => {
          setSosAlerts(prev => [...prev, data]);
        });
        return () => socket.off('sos:alert');
      }
    } catch(err) {
      console.warn("Socket not found or not initialized");
    }
  }, []);
"""

content = content.replace(
    "  const activeEmergency = bookings.find((b) => b.status === 'Emergency');",
    socket_hook + "\n  const activeEmergency = bookings.find((b) => b.status === 'Emergency');"
)

# Replace illustration with map
content = content.replace(
    """          <div
            style={{
              position: 'absolute',
              right: '-10px',
              bottom: '-15px',
              top: '0',
              width: '60%',
              pointerEvents: 'none',
              zIndex: 1,
            }}
          >
            <img
              src="/worker-illustration.svg"
              alt="Workers on Duty"
              style={{ width: '100%', height: '100%', objectFit: 'contain', objectPosition: 'bottom right' }}
            />
          </div>""",
    """          <div
            style={{
              position: 'absolute',
              right: '0',
              bottom: '0',
              top: '0',
              width: '60%',
              zIndex: 1,
            }}
          >
            <WorkersLeafletMap workers={workers} sosAlerts={sosAlerts} height="100%" />
          </div>"""
)

with open('src/pages/Dashboard/DashboardPage.jsx', 'w') as f:
    f.write(content)

