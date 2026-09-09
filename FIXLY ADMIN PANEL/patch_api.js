--- src/services/api.js
+++ src/services/api.js
@@ -271,6 +271,38 @@
   updateSupportTicketStatus: async (id, statusData) => {
     const res = await adminApi.patch(`/support/tickets/${id}`, statusData);
     return res.data;
+  },
+
+  // Welfare Resources
+  getWelfareResources: async () => {
+    const res = await adminApi.get('/admin/welfare/resources');
+    return res.data;
+  },
+  createWelfareResource: async (data) => {
+    const res = await adminApi.post('/admin/welfare/resources', data);
+    return res.data;
+  },
+  updateWelfareResource: async (id, data) => {
+    const res = await adminApi.put(`/admin/welfare/resources/${id}`, data);
+    return res.data;
+  },
+  deleteWelfareResource: async (id) => {
+    const res = await adminApi.delete(`/admin/welfare/resources/${id}`);
+    return res.data;
+  },
+  uploadWelfareResourcePdf: async (file) => {
+    const formData = new FormData();
+    formData.append('file', file);
+    const res = await adminApi.post('/admin/welfare/resources/upload', formData, {
+      headers: { 'Content-Type': 'multipart/form-data' }
+    });
+    return res.data;
+  },
+
+  // Emergency Contacts
+  getEmergencyContacts: async () => {
+    const res = await adminApi.get('/admin/emergency/contacts');
+    return res.data;
+  },
+  createEmergencyContact: async (data) => {
+    const res = await adminApi.post('/admin/emergency/contacts', data);
+    return res.data;
+  },
+  updateEmergencyContact: async (id, data) => {
+    const res = await adminApi.put(`/admin/emergency/contacts/${id}`, data);
+    return res.data;
+  },
+  deleteEmergencyContact: async (id) => {
+    const res = await adminApi.delete(`/admin/emergency/contacts/${id}`);
+    return res.data;
+  },
+
+  // Demand Forecast
+  getDemandForecast: async () => {
+    const res = await adminApi.get('/ai/demand-forecast');
+    return res.data;
   }
 };
