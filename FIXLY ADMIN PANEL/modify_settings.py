import re

with open('src/pages/Settings/SettingsPage.jsx', 'r') as f:
    content = f.read()

# Add new tab in the tabs array
content = content.replace(
    "{ key: 'banners', label: 'Promotions & Coupons', icon: Tag },",
    "{ key: 'banners', label: 'Promotions & Coupons', icon: Tag },\n          { key: 'emergency_contacts', label: 'Emergency Contacts', icon: Phone },"
)

# Add state and useEffect for emergency contacts
state_code = """
  // -------------------------------------------------------------
  // TAB 6: EMERGENCY CONTACTS
  // -------------------------------------------------------------
  const [emergencyContacts, setEmergencyContacts] = useState([]);
  const [showContactModal, setShowContactModal] = useState(false);
  const [newContact, setNewContact] = useState({ name: '', phone: '', category: 'Police' });

  const fetchEmergencyContacts = async () => {
    try {
      const res = await api.getEmergencyContacts();
      if(res && res.data) setEmergencyContacts(res.data);
      else if(Array.isArray(res)) setEmergencyContacts(res);
    } catch(err) {
      console.error(err);
    }
  };

  useEffect(() => {
    if (activeTab === 'emergency_contacts') {
      fetchEmergencyContacts();
    }
  }, [activeTab]);

  const handleAddContact = async (e) => {
    e.preventDefault();
    try {
      await api.createEmergencyContact(newContact);
      setShowContactModal(false);
      setNewContact({ name: '', phone: '', category: 'Police' });
      fetchEmergencyContacts();
      showToast('success', 'Emergency contact added');
    } catch(err) {
      showToast('error', 'Failed to add emergency contact');
    }
  };
"""

content = content.replace(
    "  // -------------------------------------------------------------",
    state_code + "\n  // -------------------------------------------------------------",
    1
)


# Add the Contacts Tab UI
contacts_ui = """
      {/* ========================================================= */}
      {/* TAB 6: EMERGENCY CONTACTS */}
      {/* ========================================================= */}
      {activeTab === 'emergency_contacts' && (
        <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '700' }}>Emergency Contacts</h3>
            <button
              onClick={() => setShowContactModal(true)}
              style={{
                display: 'flex', alignItems: 'center', gap: '8px',
                padding: '8px 16px', backgroundColor: 'var(--primary-brand)', color: '#ffffff',
                borderRadius: '8px', fontSize: '13px', fontWeight: '600', border: 'none', cursor: 'pointer'
              }}
            >
              <Plus size={16} /> Add Contact
            </button>
          </div>
          <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                  <th style={{ padding: '14px 18px' }}>Name</th>
                  <th style={{ padding: '14px 18px' }}>Phone</th>
                  <th style={{ padding: '14px 18px' }}>Category</th>
                </tr>
              </thead>
              <tbody>
                {emergencyContacts.length === 0 ? (
                  <tr>
                    <td colSpan="3" style={{ padding: '30px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                      No emergency contacts found.
                    </td>
                  </tr>
                ) : (
                  emergencyContacts.map((contact, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                      <td style={{ padding: '14px 18px', fontWeight: '600' }}>{contact.name}</td>
                      <td style={{ padding: '14px 18px' }}>{contact.phone}</td>
                      <td style={{ padding: '14px 18px' }}>{contact.category}</td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>

          {/* Add Contact Modal */}
          {showContactModal && (
            <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.5)', zIndex: 1000, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ backgroundColor: '#fff', borderRadius: '14px', padding: '24px', width: '100%', maxWidth: '400px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '16px' }}>
                  <h3 style={{ fontSize: '18px', fontWeight: '700', margin: 0 }}>Add Emergency Contact</h3>
                  <button onClick={() => setShowContactModal(false)} style={{ background: 'none', border: 'none', cursor: 'pointer' }}><X size={20} /></button>
                </div>
                <form onSubmit={handleAddContact} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
                  <div>
                    <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>Name</label>
                    <input type="text" required value={newContact.name} onChange={e => setNewContact({...newContact, name: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
                  </div>
                  <div>
                    <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>Phone</label>
                    <input type="text" required value={newContact.phone} onChange={e => setNewContact({...newContact, phone: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
                  </div>
                  <div>
                    <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>Category</label>
                    <select value={newContact.category} onChange={e => setNewContact({...newContact, category: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }}>
                      <option value="Police">Police</option>
                      <option value="Ambulance">Ambulance</option>
                      <option value="Fire">Fire</option>
                      <option value="Other">Other</option>
                    </select>
                  </div>
                  <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
                    <button type="button" onClick={() => setShowContactModal(false)} style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', background: '#fff', cursor: 'pointer' }}>Cancel</button>
                    <button type="submit" style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--primary-brand)', color: '#fff', cursor: 'pointer', fontWeight: '600' }}>Save</button>
                  </div>
                </form>
              </div>
            </div>
          )}
        </div>
      )}
"""

content = content.replace("      {/* ========================================================= */}\n      {/* TAB 5: ADMIN PROFILE */}", contacts_ui + "\n      {/* ========================================================= */}\n      {/* TAB 5: ADMIN PROFILE */}")

with open('src/pages/Settings/SettingsPage.jsx', 'w') as f:
    f.write(content)

