import test from 'node:test';
import assert from 'node:assert/strict';

import Notification from '../models/Notification.js';
import PushToken from '../models/PushToken.js';

test('PushToken stores one active device token per user', () => {
    assert.equal(PushToken.schema.path('user').options.ref, 'User');
    assert.equal(PushToken.schema.path('token').options.required, true);
    assert.equal(PushToken.schema.path('deviceId').options.required, true);
    assert.equal(PushToken.schema.path('isActive').defaultValue, true);
    assert.ok(PushToken.schema.indexes().some(([fields, options]) =>
        fields.token === 1 && options?.unique === true));
});

test('Notification stores event and delivery orchestration metadata', () => {
    for (const path of [
        'eventType',
        'entityType',
        'entityId',
        'dedupeKey',
        'channel',
        'deliveryStatus',
        'deliveryAttempts',
        'lastDeliveryError',
        'sentAt',
    ]) {
        assert.ok(Notification.schema.path(path), `missing ${path}`);
    }
    assert.ok(Notification.schema.indexes().some(([fields, options]) =>
        fields.dedupeKey === 1 && options?.unique === true));
});

test('notification templates resolve English and Hindi copy', async () => {
    const { resolveTemplate } = await import('../services/notificationTemplates.js');
    const en = resolveTemplate('BOOKING_ACCEPTED', 'en');
    const hi = resolveTemplate('BOOKING_ACCEPTED', 'hi');
    assert.equal(en.category, 'BOOKING');
    assert.equal(en.action, 'booking_details');
    assert.notEqual(en.title, hi.title);
});