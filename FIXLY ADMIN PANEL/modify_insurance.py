import re

with open('src/pages/Insurance/InsurancePage.jsx', 'r') as f:
    content = f.read()

# Add new tab
content = content.replace(
    "{ key: 'welfare', label: 'Welfare Programs & Health Camps' },",
    "{ key: 'welfare', label: 'Welfare Programs & Health Camps' },\n          { key: 'resources', label: 'Welfare Resources' },"
)

# Add state and useEffect for resources
state_code = """
  const [welfareResources, setWelfareResources] = useState([]);
  const [showResourceModal, setShowResourceModal] = useState(false);
  const [newResource, setNewResource] = useState({ title: '', type: 'link', category: 'Health', url: '', active: true });
  const [selectedFile, setSelectedFile] = useState(null);

  useEffect(() => {
    if (activeTab === 'resources') {
      import('../../services/api').then(({ api }) => {
        api.getWelfareResources().then(res => {
          if(res && res.data) setWelfareResources(res.data);
          else if(Array.isArray(res)) setWelfareResources(res);
        }).catch(err => console.error(err));
      });
    }
  }, [activeTab]);

  const handleAddResource = async (e) => {
    e.preventDefault();
    try {
      const { api } = await import('../../services/api');
      let resourceData = { ...newResource };
      if (newResource.type === 'pdf' && selectedFile) {
        const uploadRes = await api.uploadWelfareResourcePdf(selectedFile);
        resourceData.url = uploadRes.url || uploadRes.fileUrl;
      }
      await api.createWelfareResource(resourceData);
      setShowResourceModal(false);
      setNewResource({ title: '', type: 'link', category: 'Health', url: '', active: true });
      setSelectedFile(null);
      const res = await api.getWelfareResources();
      setWelfareResources(res.data || res);
    } catch(err) {
      console.error(err);
    }
  };
"""
content = content.replace("const [selectedClaimForView, setSelectedClaimForView] = useState(null);", "const [selectedClaimForView, setSelectedClaimForView] = useState(null);\n" + state_code)


# Add Resources Tab UI
resources_ui = """
      {/* Tab 4: Welfare Resources */}
      {activeTab === 'resources' && (
        <div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '16px' }}>
            <h3 style={{ fontSize: '16px', fontWeight: '700' }}>Welfare Resources</h3>
            <button
              onClick={() => setShowResourceModal(true)}
              style={{
                display: 'flex', alignItems: 'center', gap: '8px',
                padding: '8px 16px', backgroundColor: 'var(--primary-brand)', color: '#ffffff',
                borderRadius: '8px', fontSize: '13px', fontWeight: '600', border: 'none', cursor: 'pointer'
              }}
            >
              <Plus size={16} /> Add Resource
            </button>
          </div>
          <div style={{ backgroundColor: '#ffffff', borderRadius: '14px', border: '1px solid var(--border-light)', overflow: 'hidden' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
              <thead>
                <tr style={{ backgroundColor: '#f8faf9', borderBottom: '1px solid #e6ede8', color: '#55695e', fontSize: '12px', fontWeight: '700' }}>
                  <th style={{ padding: '14px 18px' }}>Title</th>
                  <th style={{ padding: '14px 18px' }}>Type</th>
                  <th style={{ padding: '14px 18px' }}>Category</th>
                  <th style={{ padding: '14px 18px' }}>Link/PDF</th>
                  <th style={{ padding: '14px 18px' }}>Status</th>
                </tr>
              </thead>
              <tbody>
                {welfareResources.length === 0 ? (
                  <tr>
                    <td colSpan="5" style={{ padding: '30px', textAlign: 'center', color: '#64748b', fontSize: '13px' }}>
                      No resources found.
                    </td>
                  </tr>
                ) : (
                  welfareResources.map((res, i) => (
                    <tr key={i} style={{ borderBottom: '1px solid #f1f5f3', fontSize: '13px' }}>
                      <td style={{ padding: '14px 18px', fontWeight: '600' }}>{res.title}</td>
                      <td style={{ padding: '14px 18px', textTransform: 'uppercase' }}>{res.type}</td>
                      <td style={{ padding: '14px 18px' }}>{res.category}</td>
                      <td style={{ padding: '14px 18px' }}>
                        {res.url ? <a href={res.url} target="_blank" rel="noreferrer" style={{color: '#2563eb'}}>View</a> : '-'}
                      </td>
                      <td style={{ padding: '14px 18px' }}>
                        <Badge status={res.active !== false ? 'Active' : 'Inactive'} />
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Add Resource Modal */}
      {showResourceModal && (
        <Modal
          isOpen={showResourceModal}
          onClose={() => setShowResourceModal(false)}
          title="Add Welfare Resource"
          maxWidth="500px"
        >
          <form onSubmit={handleAddResource} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>Title</label>
              <input type="text" required value={newResource.title} onChange={e => setNewResource({...newResource, title: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
            </div>
            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>Type</label>
              <select value={newResource.type} onChange={e => setNewResource({...newResource, type: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }}>
                <option value="link">Link</option>
                <option value="pdf">PDF</option>
                <option value="guide">Guide</option>
              </select>
            </div>
            <div>
              <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>Category</label>
              <select value={newResource.category} onChange={e => setNewResource({...newResource, category: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }}>
                <option value="Health">Health</option>
                <option value="Education">Education</option>
                <option value="Finance">Finance</option>
                <option value="Legal">Legal</option>
              </select>
            </div>
            {newResource.type === 'link' || newResource.type === 'guide' ? (
              <div>
                <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>URL</label>
                <input type="url" required value={newResource.url} onChange={e => setNewResource({...newResource, url: e.target.value})} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
              </div>
            ) : (
              <div>
                <label style={{ fontSize: '13px', fontWeight: '600', marginBottom: '6px', display: 'block' }}>PDF File</label>
                <input type="file" accept=".pdf" required onChange={e => setSelectedFile(e.target.files[0])} style={{ width: '100%', padding: '8px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
              </div>
            )}
            <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
              <input type="checkbox" checked={newResource.active} onChange={e => setNewResource({...newResource, active: e.target.checked})} />
              <label style={{ fontSize: '13px', fontWeight: '600' }}>Active</label>
            </div>
            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px', marginTop: '10px' }}>
              <button type="button" onClick={() => setShowResourceModal(false)} style={{ padding: '8px 16px', borderRadius: '8px', border: '1px solid #cbd5e1', background: '#fff', cursor: 'pointer' }}>Cancel</button>
              <button type="submit" style={{ padding: '8px 16px', borderRadius: '8px', border: 'none', background: 'var(--primary-brand)', color: '#fff', cursor: 'pointer', fontWeight: '600' }}>Save Resource</button>
            </div>
          </form>
        </Modal>
      )}
"""

content = content.replace("      {/* Policy Details Modal */}", resources_ui + "\n      {/* Policy Details Modal */}")

with open('src/pages/Insurance/InsurancePage.jsx', 'w') as f:
    f.write(content)

