import { applicationDefault, cert, getApps, initializeApp } from 'firebase-admin/app';

let firebaseApp = null;

const privateKey = process.env.FCM_PRIVATE_KEY?.replace(/\\n/g, '\n');
const hasEnvironmentCredentials = Boolean(
    process.env.FCM_PROJECT_ID && process.env.FCM_CLIENT_EMAIL && privateKey,
);

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
} else if (process.env.GOOGLE_APPLICATION_CREDENTIALS || process.env.FCM_USE_APPLICATION_DEFAULT === 'true') {
    firebaseApp = initializeApp({ credential: applicationDefault() });
}

export { firebaseApp };
export const isFirebaseConfigured = () => firebaseApp !== null;