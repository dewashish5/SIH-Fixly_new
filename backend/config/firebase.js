
import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';

let firebaseApp = null;

// Docker --env-file quotes aur newlines ko safely clean karne ke liye:
const rawKey = process.env.FCM_PRIVATE_KEY;
const privateKey = rawKey
    ? rawKey.replace(/^["']|["']$/g, '').replace(/\\n/g, '\n').trim()
    : undefined;

const hasEnvironmentCredentials = Boolean(
    process.env.FCM_PROJECT_ID && process.env.FCM_CLIENT_EMAIL && privateKey,
);

try {
    if (getApps().length > 0) {
        firebaseApp = getApps()[0];
    } else if (hasEnvironmentCredentials) {
        firebaseApp = initializeApp({
            credential: cert({
                projectId: process.env.FCM_PROJECT_ID,
                clientEmail: process.env.FCM_CLIENT_EMAIL,
                privateKey,
            }),
        });
        console.log('Firebase Admin initialized successfully ✅');
    } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.FCM_USE_APPLICATION_DEFAULT === 'true') {
        firebaseApp = initializeApp({ credential: applicationDefault() });
    }
} catch (error) {
    console.warn('⚠️ Firebase Admin Initialization Warning:', error.message);
}

export { firebaseApp };
export const isFirebaseConfigured = () => firebaseApp !== null;
// import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';

// let firebaseApp = null;

// const privateKey = process.env.FCM_PRIVATE_KEY?.replace(/\\n/g, '\n');
// const hasEnvironmentCredentials = Boolean(
//     process.env.FCM_PROJECT_ID && process.env.FCM_CLIENT_EMAIL && privateKey,
// );

// if (getApps().length > 0) {
//     firebaseApp = getApps()[0];
// } else if (hasEnvironmentCredentials) {
//     firebaseApp = initializeApp({
//         credential: cert({
//             projectId: process.env.FCM_PROJECT_ID,
//             clientEmail: process.env.FCM_CLIENT_EMAIL,
//             privateKey,
//         }),
//     });
// } else if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.FCM_USE_APPLICATION_DEFAULT === 'true') {
//     firebaseApp = initializeApp({ credential: applicationDefault() });
// }

// export { firebaseApp };
// export const isFirebaseConfigured = () => firebaseApp !== null;