# Fixly Platform - Mobile App Version & Redis Cache Management Guide

यह दस्तावेज़ Flutter मोबाइल ऐप, एडमिन पैनल और बैकएंड सिस्टम के बीच **Mobile App Versioning, Force Update** और **Redis Cache Management** के पूर्ण आर्किटेक्चर और उपयोग की संपूर्ण गाइड है।

---

## 1. सिस्टम आर्किटेक्चर (High-Level Flow)

```mermaid
flowchart TD
    A["Flutter Mobile App (Splash Screen)"] -->|GET /api/version?version=V1| B["Backend Express API"]
    B -->|1. Check Cache| C[("Redis Memory Cache")]
    C -->|Hit: Return in < 5ms| B
    C -->|Miss: Query DB| D[("MongoDB Atlas")]
    D -->|Return Data| B
    B -->|Save to Redis (TTL 24h)| C
    B -->|Response| A

    E["Fixly Admin Panel (Settings -> App Version & Redis)"] -->|PUT /api/admin/settings/app-version| B
    B -->|Update Record| D
    B -->|Invalidate & Warm Cache| C

    F["AWS / Admin Manual DB Edit"] -->|Direct Edit in Mongo Compass/Shell| D
    F -->|Flush/Clear Cache| G["POST /api/admin/redis/clear/version OR /all"]
    G --> C
```

---

## 2. Flutter मोबाइल ऐप डेवलपर गाइड (Mobile Developer Guide)

मोबाइल ऐप (Flutter) को अपनी **Splash Screen** में यूजर ऑथेंटिकेशन के साथ-साथ ऐप का वर्जन चेक करना है।

### 2.1 API Endpoint
- **URL**: `GET /api/version` (या `GET /api/version/check`)
- **Query Parameters**:
  - `version` (या `apiVersion` / `appVersion`): मोबाइल ऐप का वर्तमान वर्जन (उदा. `V1`, `V2`, या `1.0.0`)
  - `platform` (वैकल्पिक): `android` या `ios` (डिफ़ॉल्ट: `all`)
- **Alternative Headers**: `x-app-version: V1`, `x-platform: android`

### 2.2 Response Examples

#### केस 1: वर्जन मैच हो गया (User can enter app)
जब ऐप `?version=V1` भेजे और बैकएंड/डेटाबेस में भी `apiVersion: "V1"` हो:
```json
{
  "success": true,
  "apiVersion": "V1",
  "appVersion": "1.0.0",
  "minVersion": "V1",
  "forceUpdate": false,
  "isUpdateAvailable": false,
  "isMatch": true,
  "clientVersion": "V1",
  "updateTitle": "Update Available",
  "updateMessage": "A new version of Fixly is available. Please update the app to continue.",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.fixly.app",
  "platform": "all",
  "source": "redis",
  "lastUpdated": "2026-09-11T10:00:00.000Z"
}
```

#### केस 2: नया वर्जन उपलब्ध है / मिसमैच (Update Available)
जब बैकएंड/एडमिन पैनल में वर्जन बदलकर `V2` कर दिया गया हो और यूजर पुराना `V1` चला रहा हो:
```json
{
  "success": true,
  "apiVersion": "V2",
  "appVersion": "2.0.0",
  "minVersion": "V2",
  "forceUpdate": true,
  "isUpdateAvailable": true,
  "isMatch": false,
  "clientVersion": "V1",
  "updateTitle": "Update Available",
  "updateMessage": "Fixly has released a major update with new features. Please update to proceed.",
  "updateUrl": "https://play.google.com/store/apps/details?id=com.fixly.app",
  "platform": "all",
  "source": "redis",
  "lastUpdated": "2026-09-11T10:05:00.000Z"
}
```

### 2.3 Flutter डार्ट कोड उदाहरण (Splash Screen Implementation)

```dart
Future<void> checkAppVersion(BuildContext context) async {
  const String currentAppVersion = "V1"; // आपके ऐप का वर्तमान वर्जन
  
  try {
    final response = await http.get(
      Uri.parse('$baseUrl/api/version?version=$currentAppVersion&platform=android'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      final bool isUpdateAvailable = data['isUpdateAvailable'] ?? false;
      final bool forceUpdate = data['forceUpdate'] ?? false;
      final String updateUrl = data['updateUrl'] ?? '';
      final String title = data['updateTitle'] ?? 'Update Available';
      final String message = data['updateMessage'] ?? '';

      if (isUpdateAvailable) {
        showUpdateDialog(
          context: context,
          title: title,
          message: message,
          updateUrl: updateUrl,
          isMandatory: forceUpdate,
        );
        return;
      }

      // वर्जन मैच है, सामान्य लॉगिन / होम स्क्रीन पर नेविगेट करें
      navigateToNextScreen();
    }
  } catch (e) {
    // इन केस ऑफ़ नेटवर्क एरर, सामान्य रूप से आगे बढ़ने दें या री-ट्राई दिखाएं
    navigateToNextScreen();
  }
}
```

---

## 3. Redis Caching और Cache Invalidation सिस्टम (Redis Guide)

डेटाबेस पर बार-बार लोड न पड़े, इसलिए यह सिस्टम 100% **Redis Caching** पर चलता है:

1. **वर्जन कैश की कुंजी**: `app:version:all`, `app:version:android`, `app:version:ios` (TTL 86400 सेकंड / 24 घंटे)।
2. जब भी कोई यूजर ऐप खोलता है, डेटाबेस कॉल नहीं होता; सीधा **Redis Cache** से रिजल्ट मिलता है (`source: "redis"`).
3. जब एडमिन पैनल से वर्जन अपडेट किया जाता है, तो MongoDB अपडेट होने के तुरंत बाद Redis कैश इनवैलिडेट होकर नया डेटा री-कैश हो जाता है।

### 3.1 Redis Cache Clearing Endpoints
यदि आपने कभी सीधे MongoDB Compass या AWS सर्वर पर डेटा एडिट/डिलीट किया, और आप चाहते हैं कि Redis में पड़ा पुराना डेटा तुरंत डिलीट हो जाए, तो ये एंडपॉइंट्स उपलब्ध हैं:

| Method | Endpoint | काम (Action) |
|---|---|---|
| `POST` / `GET` / `DELETE` | `/api/admin/redis/clear/version` (या `/api/version/redis/clear/version`) | ऐप वर्जन का Redis कैश तुरंत डिलीट करता है |
| `POST` / `GET` / `DELETE` | `/api/admin/redis/clear/user` (या `/api/version/redis/clear/user`) | यूज़र्स के सेशंस, प्रोफाइल्स, और OTPs (`user:*`, `session:*`, `otp:*`) डिलीट करता है |
| `POST` / `GET` / `DELETE` | `/api/admin/redis/clear/booking` (या `/api/version/redis/clear/booking`) | सभी बुकिंग्स और शेड्यूल्ड बुकिंग्स का कैश (`booking:*`) डिलीट करता है |
| `POST` / `GET` / `DELETE` | `/api/admin/redis/clear/categories` (या `/api/version/redis/clear/categories`) | कैटलॉग, कैटेगरीज, और होम डैशबोर्ड का कैश डिलीट करता है |
| `POST` / `GET` / `DELETE` | `/api/admin/redis/flush-all` (या `/api/version/redis/flush-all`) | **FLUSHDB**: पूरा Redis खाली कर देता है |

#### कर्सर हिट उदाहरण:
```bash
curl -X POST http://localhost:8000/api/admin/redis/clear/user
# Response:
# {"success": true, "message": "Redis cache cleared successfully for User sessions, profiles, and OTPs", "type": "user", "deletedCount": 42}
```

---

## 4. एडमिन पैनल गाइड (Admin Panel Guide)

एडमिन पैनल में **Settings** मेन्यू के अंदर दो जगह यह सुविधा दी गई है:

1. **`SettingsPage.jsx` (`/settings?tab=app_version`)**:
   - टॉप टैब बार में दूसरा टैब: **"App Version & Redis"**
   - यहाँ से आप:
     - **Backend API Version** (`V1`, `V2` आदि) बदल सकते हैं।
     - **App Semantic Version** (`1.0.0` आदि) सेट कर सकते हैं।
     - **Force Update** टॉगल कर सकते हैं (अनिवार्य अपडेट)।
     - **Update Notice Title & Message** लिख सकते हैं।
     - **Play Store / App Store URL** सेट कर सकते हैं।
     - बटन दबाते ही डेटाबेस अपडेट होता है और **Redis कैश अपने आप सिंक** हो जाता है।
   - **Redis Cache Control Center**:
     - 4 क्विक बटन: *Clear User Cache*, *Clear Booking Cache*, *Clear Version Cache*, *Clear Catalog Cache*.
     - 1 डेंजर बटन: *Flush Entire Redis Cache (FLUSHDB)*.

2. **`SettingsView.jsx`**:
   - इसमें भी दोनों सेक्शंस (App Version Manager & Redis Cache Control Center) उपलब्ध हैं।

---

## 5. किए गए कोड बदलावों की फ़ाइल सूची (File Changes Summary)

### Backend Files:
1. **[`backend/models/AppVersion.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/backend/models/AppVersion.js)** (नया फ़ाइल)
   - Mongoose मॉडल (फ़ील्ड्स: `apiVersion`, `appVersion`, `minVersion`, `forceUpdate`, `updateTitle`, `updateMessage`, `updateUrl`, `platform`, `isActive`).
   - MongoDB Atlas में इनिशियल रिकॉर्ड क्रिएट किया गया (`apiVersion: "V1"`).
2. **[`backend/controllers/appVersionController.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/backend/controllers/appVersionController.js)** (नया फ़ाइल)
   - `checkAppVersion` (Redis first, fallback to Mongo, zero static mock objects).
   - `updateAppVersion` (MongoDB अपडेट + Redis cache invalidation/pre-warming).
   - `getAppVersionAdmin`, `getAllVersions`.
   - `clearRedisCache` (ग्रैन्यूलर पैटर्न स्कैन + FLUSHDB सपोर्ट).
3. **[`backend/routes/app-version-routes.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/backend/routes/app-version-routes.js)** (नया फ़ाइल)
   - पब्लिक स्प्लैश स्क्रीन राउट्स और रेडिस क्लियरिंग राउट्स.
4. **[`backend/routes/admin-routes.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/backend/routes/admin-routes.js)** (मॉडिफाइड)
   - `/api/admin/settings/app-version` और `/api/admin/redis/clear/:type` राउट्स जोड़े गए.
5. **[`backend/server.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/backend/server.js)** (मॉडिफाइड)
   - `/api/version` और `/api/app-version` माउंट किए गए.
6. **[`backend/tests/appVersion.test.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/backend/tests/appVersion.test.js)** (नया फ़ाइल)
   - यूनिट टेस्ट्स (स्कीमा, रेडिस हिट/मिस, वर्जन मिसमैच फ्लैग्स, और रेडिस फ्लश लॉजिक). सभी 100% पास.

### Admin Panel Files:
1. **[`FIXLY ADMIN PANEL/src/services/api.js`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/FIXLY%20ADMIN%20PANEL/src/services/api.js)** (मॉडिफाइड)
   - `getAppVersion()`, `updateAppVersion()`, `clearRedisCache()` मेथड्स जोड़े गए.
2. **[`FIXLY ADMIN PANEL/src/pages/Settings/SettingsPage.jsx`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/FIXLY%20ADMIN%20PANEL/src/pages/Settings/SettingsPage.jsx)** (मॉडिफाइड)
   - "App Version & Redis" टैब, फॉर्म, और रेडिस इनवैलिडेशन बटन्स जोड़े गए.
3. **[`FIXLY ADMIN PANEL/src/views/SettingsView.jsx`](file:///Users/vaibhavjain/Desktop/Dewashish/SIH-Fixly/FIXLY%20ADMIN%20PANEL/src/views/SettingsView.jsx)** (मॉडिफाइड)
   - ऐप वर्जन और रेडिस फ्लश कंट्रोलर इंटीग्रेट किया गया.

---

## 6. Worker KYC Verification & Fixes (Verification Page Guide)

### 6.1 `mongoose is not defined` एरर का समाधान
- **समस्या**: एडमिन पैनल में `/approvals` (Verification) पेज पर जाते ही `mongoose is not defined` के 4 टोस्ट एरर आ रहे थे।
- **कारण**: `backend/controllers/adminController.js` के अंदर `getWorkerById` (लाइन 515) और `updateWorkerById` (लाइन 676) में `mongoose.Types.ObjectId.isValid(id)` का उपयोग किया गया था, लेकिन फ़ाइल के टॉप पर `import mongoose from 'mongoose';` मिसिंग था।
- **समाधान**: फ़ाइल के टॉप पर `import mongoose from 'mongoose';` जोड़ दिया गया। अब `getWorkerById` बिना किसी एरर के 200 OK रिस्पॉन्स दे रहा है।

### 6.2 वर्कर वेरिफिकेशन टैब्स का डायनामिक फ़िल्टर (Pending Review vs Approved)
- **समस्या**: वर्कर (जैसे "Vaibhav Jain") की KYC डेटाबेस में `isVerified: true` थी, फिर भी वह "Pending review" टैब में दिखाई दे रहा था।
- **कारण**: `adminController.js` के `getWorkers` फ़ंक्शन में `req.query.pendingApproval` और `req.query.kycStatus` का फ़िल्टर लागू नहीं था। परिणामस्वरूप, सभी 4 टैब्स (`Pending review`, `Manual Review`, `Declined`, `Approved`) में वही सारे वर्कर्स अनफ़िल्टर्ड लौट रहे थे।
- **समाधान**: `getWorkers` में अब चारों टैब्स के लिए सटीक डेटाबेस क्वेरी फ़िल्टर जोड़ दिया गया है:
  1. **Pending review (`tab === 'pending'` / `pendingApproval === 'true'`)**:
     - केवल वही वर्कर्स लौटेंगे जिनकी KYC सबमिट है लेकिन अभी अप्रूव नहीं हुई है (`isVerified: false` तथा `kycDocuments.status: 'submitted'` / `'pending'`).
  2. **Manual Review (`tab === 'MANUAL_REVIEW'`)**:
     - केवल वही वर्कर्स जिनकी KYC को एडमिन ने मैनुअल रिव्यू में डाला है (`kycDocuments.status: 'MANUAL_REVIEW'`).
  3. **Declined (`tab === 'rejected'`)**:
     - रिजेक्टेड वर्कर्स (`kycDocuments.status: 'rejected'`).
  4. **Approved (`tab === 'approved'`)**:
     - अप्रूव्ड वर्कर्स (`isVerified: true` अथवा `kycDocuments.status: 'approved'`).

इसके साथ ही डेटाबेस में Vaibhav Jain के रिकॉर्ड को `kycDocuments.status: 'approved'` सिंक कर दिया गया है। अब "Pending review" में 0 पेंडिंग वर्कर्स हैं और "Approved" टैब में 1 अप्रूव्ड वर्कर (Vaibhav Jain) सही जगह दिखाई दे रहा है।

---

## 7. कोऑपरेटिव हायरार्की और वर्कर ऑनबोर्डिंग इंटीग्रेशन (Cooperative Hierarchy & Worker Onboarding Guide)

### 7.1 सिस्टम की 4-स्तरीय कोऑपरेटिव हायरार्की (4-Level Architecture)

Fixly प्लेटफ़ॉर्म में 4 लेयर्स हैं:
1. **सुपर एडमिन (Fixly Platform Admin)**:
   - पूरे प्लेटफ़ॉर्म का स्वामी। यह फ़ेडरेशनों (`Cooperative`) और प्राइमरी सोसाइटीज (`CooperativeSociety`) को अप्रूव या ब्लॉक कर सकता है।
2. **रीजनल फ़ेडरेशन (Regional Federation / Apex Body)**:
   - मॉडल: `Cooperative` (कलेक्शन: `cooperatives`)
   - पूरे राज्य या रीजनल क्लस्टर का शीर्ष संगठन (जैसे: "Delhi NCR Labour Cooperative Federation")।
   - यह मिनिमम वेज फ्लोर (`minimumWageFloor`), वेलफ़ेयर फंड रेट (`welfareContributionRate`), और इंश्योरेंस नीतियां तय करता है।
3. **प्राइमरी कोऑपरेटिव सोसाइटी (Primary Cooperative Society / LACS)**:
   - मॉडल: `CooperativeSociety` (कलेक्शन: `cooperativesocieties`)
   - स्थानीय ज़िला या वार्ड स्तर की लेबर सोसाइटी (जैसे: "South Delhi Electricians Cooperative Society Ltd").
   - प्रत्येक सोसाइटी एक पेरेंट फ़ेडरेशन से संबद्ध होती है (`federation: ObjectId`).
4. **गिग वर्कर (Gig Worker)**:
   - मॉडल: `User` (`role: 'worker'`)
   - वर्कर सीधे अपने ज़िले की प्राइमरी सोसाइटी से जुड़ता है (`workerProfile.society = societyId`).
   - बैकएंड **ऑटोमैटिकली** सोसाइटी के आधार पर वर्कर को पेरेंट फ़ेडरेशन (`user.federation = society.federation`) से लिंक कर देता है और एक यूनिक मेंबर ID (`workerProfile.societyMemberId`) जनरेट करता है।

```
         [ सुपर एडमिन (Fixly Super Admin) ]
                        │
                        ▼
         [ रीजनल कोऑपरेटिव फ़ेडरेशन (Federation) ]
          (राज्य स्तर / क्लस्टर - e.g. Delhi NCR)
                        │
         ┌──────────────┴──────────────┐
         ▼                             ▼
[ प्राइमरी सोसाइटी A ]           [ प्राइमरी सोसाइटी B ]
 (South Delhi Society)            (North Delhi Society)
         │                             │
    ┌────┴────┐                   ┌────┴────┐
    ▼         ▼                   ▼         ▼
[वर्कर 1]  [वर्कर 2]           [वर्कर 3]  [वर्कर 4]
```

---

### 7.2 वर्कर रजिस्ट्रेशन एवं ऑनबोर्डिंग फ्लो (Worker Registration Flow)

```
[ Step 1: साइन-अप / लॉगिन ]
  वर्कर Email, Phone, Password से रजिस्टर करता है -> OTP वेरीफाई होता है -> JWT Access Token मिलता है।
       │
       ▼
[ Step 2: राज्य व ज़िला चयन (State & District Selection) ]
  Flutter ऐप में वर्कर अपना State और District चुनता है।
       │
       ▼
[ Step 3: प्राइमरी सोसाइटी लिस्ट प्राप्त करना ]
  Flutter API कॉल करता है: GET /api/cooperative/societies?state={state}&district={district}
  वर्कर को उस ज़िले में मौजूद अधिकृत सोसाइटीज ड्रॉपडाउन/लिस्ट में दिखती हैं।
       │
       ▼
[ Step 4: प्रोफ़ाइल व सोसाइटी सबमिशन ]
  वर्कर अपनी डिटेल्स + चुनी हुई societyId सबमिट करता है:
  PUT /api/workers/setup-profile (या PUT /api/users/me)
       │
       ▼
[ Step 5: बैकएंड ऑटो-लिंकिंग ]
  1. बैकएंड सोसाइटी ढूँढता है।
  2. वर्कर के user.federation को सोसाइटी की फ़ेडरेशन से ऑटो-लिंक करता है।
  3. वर्कर को एक यूनिक Member ID (जैसे MEM-SOU-4821) जारी करता है।
  4. Redis कैश को ऑटो-रिफ्रेश करता है।
```

---

### 7.3 APIs एवं रिक्वेस्ट/रिस्पॉन्स स्पेसिफिकेशन (API Specs)

#### 1. ज़िला/राज्य के अनुसार सोसाइटीज की सूची प्राप्त करें (Public API)
- **Endpoint**: `GET /api/cooperative/societies`
- **Auth**: None (पब्लिक है ताकि ऑनबोर्डिंग स्क्रीन पर बिना किसी बाधा के लोड हो सके)
- **Query Params**:
  - `state` (Optional): राज्य का नाम (जैसे `Delhi`)
  - `district` (Optional): ज़िले का नाम (जैसे `South Delhi`)
  - `active` (Optional): `true`
- **Example Request**:
  ```http
  GET /api/cooperative/societies?state=Delhi&district=South%20Delhi HTTP/1.1
  Host: localhost:8000
  ```
- **Example Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "_id": "6aa3d8c3da92623ca43b6aef",
        "name": "South Delhi Electricians Cooperative Society Ltd",
        "registrationNumber": "COOP/DL/2024/001",
        "federation": "6bbf8291e0123456789abcde",
        "state": "Delhi",
        "district": "South Delhi",
        "wardOrArea": "Hauz Khas & Saket",
        "contactPhone": "+919876543210",
        "presidentName": "Ramesh Kumar Sharma",
        "fairWageComplianceScore": 98,
        "active": true
      }
    ],
    "total": 1
  }
  ```

---

#### 2. वर्कर प्रोफ़ाइल व सोसाइटी सेटअप API
- **Endpoint**: `PUT /api/workers/setup-profile` (वैकल्पिक: `PUT /api/users/me`)
- **Headers**:
  - `Authorization`: `Bearer <worker_access_token>`
  - `Content-Type`: `application/json` (या फ़ाइल अपलोड के लिए `multipart/form-data`)
- **Request Body (JSON Payload)**:
  ```json
  {
    "state": "Delhi",
    "district": "South Delhi",
    "societyId": "6aa3d8c3da92623ca43b6aef",
    "category": "Electrician",
    "categories": ["Electrician", "Appliance Repair"],
    "rate": 350,
    "hourlyRate": 350,
    "experienceYears": 4,
    "bio": "Certified domestic and commercial electrical repairs expert with 4 years experience.",
    "skills": ["Wiring", "MCB Repair", "Inverter Installation"],
    "workAddress": "Hauz Khas Market, New Delhi",
    "eshramUan": "123456789012",
    "aadhaarNumber": "456789012345",
    "panNumber": "ABCDE1234F",
    "payoutMethod": "upi",
    "upi": {
      "upiId": "worker@upi"
    }
  }
  ```
- **Backend ऑटो-प्रोसेसिंग**:
  - `societyId` से प्राइमरी सोसाइटी सर्च की जाती है।
  - वर्कर के रिकॉर्ड में `workerProfile.society = societyId` सेट होता है।
  - सोसाइटी का पेरेंट फ़ेडरेशन निकाल कर `user.federation = society.federation` स्वतः लिंक हो जाता है।
  - अगर `societyMemberId` खाली है, तो यह ज़िले के कोड के आधार पर यूनिक मेंबर ID बनाता है (उदा. `MEM-SOU-7182`)।
  - `workerProfile.state` और `workerProfile.district` सेव होते हैं।
  - Redis में वर्कर और यूज़र प्रोफ़ाइल का कैश तुरंत इनवैलिडेट व सिंक होता है।

- **Example Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Profile and documents uploaded successfully via queue",
    "user": {
      "_id": "68be9c2394178a9c3905cd12",
      "name": "Rohan Sharma",
      "email": "rohan.worker@fixly.com",
      "phone": "+919811223344",
      "role": "worker",
      "federation": {
        "_id": "6bbf8291e0123456789abcde",
        "name": "Delhi Labour Cooperative Federation",
        "federationName": "Delhi State Apex Labour Federation",
        "state": "Delhi"
      },
      "isVerified": false,
      "workerProfile": {
        "state": "Delhi",
        "district": "South Delhi",
        "society": {
          "_id": "6aa3d8c3da92623ca43b6aef",
          "name": "South Delhi Electricians Cooperative Society Ltd",
          "registrationNumber": "COOP/DL/2024/001",
          "state": "Delhi",
          "district": "South Delhi"
        },
        "societyMemberId": "MEM-SOU-7182",
        "category": "Electrician",
        "rate": 350,
        "experienceYears": 4,
        "eshramUan": "123456789012",
        "isOnline": false
      },
      "kycDocuments": {
        "aadhaarNumber": "456789012345",
        "status": "submitted"
      }
    }
  }
  ```

---

#### 3. वर्कर की अपनी कोऑपरेटिव व फ़ेडरेशन मेंबरशिप देखना
- **Endpoint**: `GET /api/cooperative/my-society`
- **Headers**:
  - `Authorization`: `Bearer <worker_access_token>`
- **Response (200 OK)**:
  - वर्कर को उसकी सोसाइटी का नाम, रजिस्ट्रेशन नंबर, अध्यक्ष का नाम, फ़ेयर वेज स्कोर और फ़ेडरेशन की मिनिमम वेज फ्लोर पॉलिसी व वेलफ़ेयर फंड की जानकारी लौटाता है।

---

### 7.4 Flutter कोड उदाहरण (Dart Implementation Snippet)

Flutter डेवलपर के लिए सोसाइटी फेच और प्रोफ़ाइल सेटअप का आसान तरीका:

```dart
// 1. Fetch Societies for Selected State & District
Future<List<Map<String, dynamic>>> fetchSocieties(String state, String district) async {
  final url = Uri.parse('$baseUrl/api/cooperative/societies?state=$state&district=$district');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    return List<Map<String, dynamic>>.from(body['data'] ?? []);
  }
  return [];
}

// 2. Submit Worker Setup with Society ID
Future<bool> setupWorkerProfile({
  required String token,
  required String state,
  required String district,
  required String societyId,
  required String category,
  required double rate,
  required String aadhaarNumber,
}) async {
  final url = Uri.parse('$baseUrl/api/workers/setup-profile');
  final response = await http.put(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'state': state,
      'district': district,
      'societyId': societyId,
      'category': category,
      'rate': rate,
      'aadhaarNumber': aadhaarNumber,
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    print('Assigned Federation: ${data['user']['federation']}');
    print('Society Member ID: ${data['user']['workerProfile']['societyMemberId']}');
    return true;
  }
  return false;
}
```

---

### 7.5 सारांश (Summary for Team)
1. **फ़्लटर टीम**: ऑनबोर्डिंग में वर्कर से **State** और **District** सेलेक्ट करवाएं, फिर `GET /api/cooperative/societies` कॉल करके उस क्षेत्र की प्राइमरी सोसाइटीज ड्रॉपडाउन में दिखाएं। वर्कर के चयन के बाद `societyId` को `PUT /api/workers/setup-profile` में पास कर दें।
2. **बैकएंड**: बैकएंड `societyId` मिलते ही खुद पेरेंट फ़ेडरेशन से वर्कर को लिंक कर देता है और मेंबर आईडी जारी कर देता है।
3. **एडमिन पैनल**: एडमिन पैनल में फ़ेडरेशन और सोसाइटीज के तहत आने वाले सभी पंजीकृत वर्कर्स सीधे फ़िल्टर होकर लाइव दिखाई देंगे।

---

## 8. सर्विस आइकन अनिवार्यता एवं इंश्योरेंस व ई-श्रम PDF/URL मैनेजमेंट (Services & Welfare Guide)

### 8.1 सर्विस आइकन व इमेज अनिवार्यता (Mandatory Service App Icon)

#### समस्या (Issue):
1. **डमी आइकन का कारण**: डेटाबेस में प्रत्येक सर्विस ("Sink Repair", "electrician", "geyser repair" आदि) के पास Cloudinary इमेज URL पहले से मौजूद था, लेकिन `FIXLY ADMIN PANEL/src/context/AppContext.jsx` के अंदर `fetchServices` मेथड में `image` फ़ील्ड को मैप नहीं किया गया था। परिणामस्वरूप फ़्रंटएंड को इमेज कभी नहीं मिलती थी और वह डमी `Layers` ग्रीन बॉक्स दिखाता था।
2. **बिना इमेज पब्लिश होना**: पहले `AddServiceModal.jsx` में इमेज का वैलिडेशन नहीं था, जिससे कोई भी बिना आइकन/इमेज अपलोड किए सर्विस पब्लिश कर सकता था।

#### समाधान (Solution):
1. **डेटा मैपिंग फ़िक्स**:
   - `AppContext.jsx` में `image: s.image || s.icon || ''` को मैप किया गया। अब सभी 5 सर्विसेज के असली Cloudinary आइकन्स कार्ड के टॉप-लेफ्ट 48x48 बॉक्स में लाइव दिखाई दे रहे हैं।
2. **अनिवार्य आइकन अपलोड (Strict Validation)**:
   - `AddServiceModal.jsx` में इमेज को **Strictly Mandatory** कर दिया गया है।
   - यदि कोई एडमिन बिना इमेज के "Publish to Catalog" पर क्लिक करता है, तो फॉर्म सबमिट नहीं होगा और लाल रंग में साफ़ चेतावनी दिखेगी:
     `Service icon/image is strictly mandatory. Please upload an icon for the app.`
   - अपलोड बॉक्स का बॉर्डर लाल हो जाएगा।
   - फ़ाइल अपलोड होते ही तुरंत इमेज का 54x54 प्रीव्यू और हरा टिक दिखाई देगा।
3. **बैकएंड प्रोटेक्शन**:
   - `backend/controllers/adminController.js` के `createCategory` में चेक लगा दिया गया है। यदि पे-लोड में इमेज नहीं है, तो बैकएंड 400 Bad Request रिटर्न करेगा (`Service icon/image is strictly mandatory`).
   - `backend/routes/admin-routes.js` में `POST /api/admin/upload` को `uploadImage(file)` मेथड के साथ एडमिन पैनल `api.js` से पूरी तरह कनेक्ट कर दिया गया है।

---

### 8.2 इंश्योरेंस एवं वेलफ़ेयर क्रैश फ़िक्स (Crash Bug Fix)

#### समस्या (Issue):
- एडमिन पैनल में साइडबार से **"Insurance & Welfare"** पर क्लिक करने पर पूरी वेब एप्लीकेशन क्रैश होकर ब्लैंक (Blank White Screen) हो जा रही थी।

#### कारण (Root Cause):
- `FIXLY ADMIN PANEL/src/pages/Insurance/InsurancePage.jsx` की पहली लाइन में `useEffect` का इम्पोर्ट मिसिंग था (`import React, { useState } from 'react';`)। जैसे ही पेज रेंडर होता था, लाइन 34 पर `useEffect` कॉल होते ही जावास्क्रिप्ट एरर आता था:
  `ReferenceError: useEffect is not defined`
  जिससे रिएक्ट का पूरा DOM अनमाउंट हो जाता था।

#### समाधान (Solution):
- `InsurancePage.jsx` में टॉप पर `import React, { useState, useEffect } from 'react';` इम्पोर्ट किया गया और `api` को सीधे स्टैटिकली इम्पोर्ट किया गया।
- अब पेज पर क्लिक करते ही बिना किसी क्रैश या रिफ्रेश के तुरंत पूरा डेटा लोड होता है।

---

### 8.3 ई-श्रम PDF डाक्यूमेंट्स व लाइव डायनामिक URLs सिस्टम (e-Shram PDFs & Dynamic URLs)

गिग वर्कर्स को ई-श्रम एक्टिवेशन, आयुष्मान भारत और वेलफ़ेयर स्कीम्स से जोड़ने के लिए दोतरफ़ा सिस्टम बनाया गया है:

#### 1. लाइव इन-ऐप वेबव्यू पोर्टल्स (Dynamic In-App Webview URLs):
- एडमिन पैनल से सीधे आधिकारिक सरकारी पोर्टल्स के लाइव URLs जोड़े जा सकते हैं:
  - **ई-श्रम आधिकारिक पोर्टल**: `https://eshram.gov.in`
  - **आयुष्मान भारत PM-JAY पोर्टल**: `https://beneficiary.nha.gov.in/`
- **मोबाइल ऐप बिहेवियर**:
  - मोबाइल ऐप में जब वर्कर "Register for e-Shram" या "Apply for Ayushman Card" पर क्लिक करता है, तो यह URL सीधे मोबाइल ऐप के अंदर इन-ऐप **WebView** में खुलता है।
  - यदि सरकार का पोर्टल URL कल को बदलता है, तो एडमिन पैनल से URL बदलते ही ऐप में बिना नया ऐप रिलीज़ किए नया पोर्टल खुलने लगेगा!

#### 2. वर्कर वेलफ़ेयर स्कीम PDFs (Uploaded Documents & In-App Preview):
- एडमिन सीधे अपने कंप्यूटर/डेस्कटॉप से **.pdf** फ़ाइलें अपलोड कर सकता है (जैसे: *"e-Shram Registration Step-by-Step Manual.pdf"*, *"Accident Claim Form.pdf"*).
- यह फ़ाइलें सीधे **Cloudinary CDN** पर स्टोर होती हैं।
- **एडमिन पैनल इन-बिल्ट प्रीव्यू**:
  - प्रत्येक PDF के सामने **"👁️ Preview"** बटन दिया गया है।
  - इस पर क्लिक करते ही एडमिन पैनल के अंदर ही एक सुंदर मोडल में PDF का लाइव प्रीव्यू खुल जाता है (बिना नई विंडो खोले)।
  - साथ ही "Open External", "Hide/Show" और "Delete" की सुविधा भी मौजूद है।

---

### 8.4 APIs स्पेसिफिकेशन (Welfare APIs)

#### 1. सभी वेलफ़ेयर स्कीम्स व PDFs प्राप्त करें (Worker Mobile App & Public)
- **Endpoint**: `GET /api/welfare/resources` (या `GET /api/worker/me/welfare/resources`)
- **Headers**: Optional Bearer Token
- **Example Response (200 OK)**:
  ```json
  {
    "success": true,
    "data": [
      {
        "_id": "auto-eshram-link",
        "title": "Register for e-Shram",
        "description": "Get your UAN to unlock government benefits.",
        "type": "link",
        "url": "https://eshram.gov.in",
        "category": "eshram",
        "priority": 100
      },
      {
        "_id": "6aa3ddd04a3b69eea1f7b908",
        "title": "e-Shram Registration & Benefits Official Guide (PDF)",
        "type": "pdf",
        "category": "eshram",
        "url": "https://res.cloudinary.com/.../eShram_User_Manual.pdf",
        "pdfUrl": "https://res.cloudinary.com/.../eShram_User_Manual.pdf",
        "fileName": "eShram_User_Manual_Self_Registration.pdf",
        "fileSize": "1.2 MB",
        "isActive": true
      }
    ]
  }
  ```

#### 2. PDF अपलोड API (Admin)
- **Endpoint**: `POST /api/admin/welfare/resources/upload`
- **Headers**: `Authorization: Bearer <token>`, `Content-Type: multipart/form-data`
- **Body**: `file: <binary_pdf>`
- **Response**: `{ "success": true, "url": "https://res.cloudinary.com/.../document.pdf" }`

#### 3. नया वेलफ़ेयर रिसोर्स क्रिएट करें (Admin)
- **Endpoint**: `POST /api/admin/welfare/resources`
- **Payload (PDF Document)**:
  ```json
  {
    "title": "e-Shram Activation Step-by-Step Guide",
    "type": "pdf",
    "category": "eshram",
    "pdfUrl": "https://res.cloudinary.com/.../document.pdf",
    "fileName": "eshram_guide.pdf",
    "fileSize": "450 KB",
    "description": "Visual guide for unorganised workers to create UAN card",
    "isActive": true
  }
  ```
- **Payload (Dynamic Webview Portal)**:
  ```json
  {
    "title": "PM-JAY Ayushman Bharat Health Card Portal",
    "type": "link",
    "category": "insurance",
    "url": "https://beneficiary.nha.gov.in/",
    "description": "Check eligibility for 5 Lakh cashless insurance",
    "isActive": true
  }
  ```

---

### 8.5 Flutter कोड स्निपेट (Worker App Integration)

```dart
// Fetch Welfare Resources in Worker App
Future<void> loadWelfareResources() async {
  final response = await http.get(Uri.parse('$baseUrl/api/welfare/resources'));
  if (response.statusCode == 200) {
    final List list = jsonDecode(response.body)['data'];

    // 1. Webview Links (e.g. e-Shram portal)
    final portals = list.where((item) => item['type'] == 'link').toList();

    // 2. Downloadable Scheme PDFs
    final pdfDocuments = list.where((item) => item['type'] == 'pdf').toList();

    // To open Webview on button tap:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => InAppWebViewScreen(url: portals[0]['url'])));

    // To view PDF on tap:
    // Navigator.push(context, MaterialPageRoute(builder: (_) => PdfViewerScreen(pdfUrl: pdfDocuments[0]['pdfUrl'])));
  }
}
```

---

### 8.6 Welfare & Insurance Cloudinary Folder Architecture & Fix Details

1. **Dedicated Cloudinary Folder (`insurance_welfare`)**:
   - सभी वेलफेयर एवं इंश्योरेंस स्कीम गाइड PDFs, क्लेम फॉर्म्स और डॉक्यूमेंट्स अब ऑटोमैटिकली `insurance_welfare/` फोल्डर के अंदर अपलोड होते हैं।
   - बैकएंड कंट्रोलर (`uploadAdminFile`) ऑटोमैटिक डिटेक्ट करता है यदि अपलोड वेलफेयर रूट (`/welfare/resources/upload`) या `req.body.folder: 'insurance_welfare'` या PDF डॉक्यूमेंट से आया है।
   - सर्विसेज इमेज और वेलफेयर डॉक्यूमेंट्स अलग-अलग फ़ोल्डर्स में सुरक्षित रहते हैं।

2. **Frontend Upload Button & UX**:
   - बटन स्टेट को यूजर-फ्रेंडली बनाकर केवल **"Uploading..."** (प्रोग्रेस स्पिनर के साथ) रखा गया है।
   - किसी भी थर्ड-पार्टी क्लाउड वेंडर का नाम (जैसे Cloudinary) यूजर-फेसिंग UI में शो नहीं होता है।

3. **Multipart/Form-Data Boundary Resolution**:
   - `adminApi` रिक्वेस्ट इंटरसेप्टर में `config.data instanceof FormData` होने पर `Content-Type: application/json` को ऑटोमैटिक डिलीट कर दिया गया है ताकि ब्राउज़र बाउंड्री (`multipart/form-data; boundary=----...`) सही तरीके से सेंड करे और Multer अपलोड फेल न हो।

4. **Live PDF In-Modal Preview & Direct Open**:
   - डेटाबेस में लाइव क्लाउडनेरी PDF रिसोर्स एक्टिवेटेड है (`https://res.cloudinary.com/vaibhavjain/image/upload/v1789125068/insurance_welfare/yyush4gvrgkn2ypc3n2x.pdf`)।
   - एडमिन पैनल में **Preview** बटन पर क्लिक करते ही इन-मोडल आईफ्रेम व्यूअर खुलता है और **Open** बटन से नई विंडो में डायरेक्ट PDF लोड होती है (शून्य 404 त्रुटि)।
