process.env.NODE_ENV = 'test';
import test from 'node:test';
import assert from 'node:assert/strict';
import AppVersion from '../models/AppVersion.js';
import redis from '../config/redis.js';

test('AppVersion schema has correct configuration and default values', () => {
    assert.ok(AppVersion.schema.path('apiVersion'), 'missing apiVersion field');
    assert.equal(AppVersion.schema.path('apiVersion').defaultValue, 'V1');

    assert.ok(AppVersion.schema.path('appVersion'), 'missing appVersion field');
    assert.equal(AppVersion.schema.path('appVersion').defaultValue, '1.0.0');

    assert.ok(AppVersion.schema.path('minVersion'), 'missing minVersion field');
    assert.equal(AppVersion.schema.path('minVersion').defaultValue, 'V1');

    assert.ok(AppVersion.schema.path('forceUpdate'), 'missing forceUpdate field');
    assert.equal(AppVersion.schema.path('forceUpdate').defaultValue, false);

    assert.ok(AppVersion.schema.path('updateTitle'), 'missing updateTitle field');
    assert.ok(AppVersion.schema.path('updateMessage'), 'missing updateMessage field');
    assert.ok(AppVersion.schema.path('updateUrl'), 'missing updateUrl field');
    assert.ok(AppVersion.schema.path('platform'), 'missing platform field');
    assert.equal(AppVersion.schema.path('isActive').defaultValue, true);
});

test('AppVersion check logic matches correct version and flags update on mismatch', async () => {
    const { checkAppVersion } = await import('../controllers/appVersionController.js');

    let jsonResult = null;
    let statusCode = null;

    const mockRes = {
        status(code) {
            statusCode = code;
            return this;
        },
        json(data) {
            jsonResult = data;
            return this;
        }
    };

    const origGet = redis.get;
    const origSet = redis.set;
    const origFindOne = AppVersion.findOne;

    // Redis get returns null (cache miss), DB returns V1
    redis.get = () => Promise.resolve(null);
    redis.set = () => Promise.resolve('OK');

    AppVersion.findOne = () => ({
        sort: () => ({
            lean: () => Promise.resolve({
                apiVersion: 'V1',
                appVersion: '1.0.0',
                minVersion: 'V1',
                forceUpdate: false,
                updateTitle: 'Update Available',
                updateMessage: 'Test message',
                updateUrl: 'https://example.com',
                platform: 'all',
                isActive: true,
                updatedAt: new Date()
            })
        })
    });

    try {
        // Test 1: Matching version V1
        const mockReq1 = { query: { version: 'V1' }, headers: {} };
        await checkAppVersion(mockReq1, mockRes);
        assert.equal(statusCode, 200);
        assert.equal(jsonResult.success, true);
        assert.equal(jsonResult.apiVersion, 'V1');
        assert.equal(jsonResult.isMatch, true);
        assert.equal(jsonResult.isUpdateAvailable, false);

        // Test 2: Mismatched version (Client V1, DB updated to V2)
        AppVersion.findOne = () => ({
            sort: () => ({
                lean: () => Promise.resolve({
                    apiVersion: 'V2',
                    appVersion: '2.0.0',
                    minVersion: 'V2',
                    forceUpdate: true,
                    updateTitle: 'Critical Update',
                    updateMessage: 'Please update to V2',
                    updateUrl: 'https://example.com/v2',
                    platform: 'all',
                    isActive: true,
                    updatedAt: new Date()
                })
            })
        });

        const mockReq2 = { query: { version: 'V1' }, headers: {} };
        await checkAppVersion(mockReq2, mockRes);
        assert.equal(statusCode, 200);
        assert.equal(jsonResult.success, true);
        assert.equal(jsonResult.apiVersion, 'V2');
        assert.equal(jsonResult.isMatch, false);
        assert.equal(jsonResult.isUpdateAvailable, true);
        assert.equal(jsonResult.forceUpdate, true);

        // Test 3: Cache Hit directly from Redis without DB call
        redis.get = () => Promise.resolve(JSON.stringify({
            apiVersion: 'V2',
            appVersion: '2.0.0',
            minVersion: 'V2',
            forceUpdate: false,
            updateTitle: 'Cached Title',
            updateMessage: 'Cached message',
            updateUrl: '',
            platform: 'all',
            isActive: true
        }));

        AppVersion.findOne = () => {
            throw new Error('Database should not be called on Redis cache hit!');
        };

        const mockReq3 = { query: { version: 'V2' }, headers: {} };
        await checkAppVersion(mockReq3, mockRes);
        assert.equal(statusCode, 200);
        assert.equal(jsonResult.apiVersion, 'V2');
        assert.equal(jsonResult.source, 'redis');
        assert.equal(jsonResult.isMatch, true);

        // Test 4: No static fallback when not found in DB or Cache
        redis.get = () => Promise.resolve(null);
        AppVersion.findOne = () => ({
            sort: () => ({
                lean: () => Promise.resolve(null)
            })
        });

        await checkAppVersion(mockReq3, mockRes);
        assert.equal(statusCode, 404);
        assert.equal(jsonResult.success, false);
        assert.match(jsonResult.message, /No active app version found in database/i);
    } finally {
        redis.get = origGet;
        redis.set = origSet;
        AppVersion.findOne = origFindOne;
    }
});

test('clearRedisCache handles user, booking, and flushdb types cleanly', async () => {
    const { clearRedisCache } = await import('../controllers/appVersionController.js');

    let jsonResult = null;
    let statusCode = null;

    const mockRes = {
        status(code) {
            statusCode = code;
            return this;
        },
        json(data) {
            jsonResult = data;
            return this;
        }
    };

    const origScan = redis.scan;
    const origDel = redis.del;
    const origFlush = redis.flushdb;

    let scannedPatterns = [];
    let flushCalled = false;

    redis.scan = (cursor, matchKey, pattern) => {
        scannedPatterns.push(pattern);
        return Promise.resolve(['0', ['sample_key_1', 'sample_key_2']]);
    };
    redis.del = (...keys) => Promise.resolve(keys.length);
    redis.flushdb = () => {
        flushCalled = true;
        return Promise.resolve('OK');
    };

    try {
        // Test clear user
        scannedPatterns = [];
        await clearRedisCache({ params: { type: 'user' }, query: {}, body: {} }, mockRes);
        assert.equal(statusCode, 200);
        assert.equal(jsonResult.success, true);
        assert.equal(jsonResult.type, 'user');
        assert.ok(scannedPatterns.includes('user:*'));
        assert.ok(scannedPatterns.includes('session:*'));

        // Test clear booking
        scannedPatterns = [];
        await clearRedisCache({ params: { type: 'booking' }, query: {}, body: {} }, mockRes);
        assert.equal(statusCode, 200);
        assert.equal(jsonResult.success, true);
        assert.equal(jsonResult.type, 'booking');
        assert.ok(scannedPatterns.includes('booking:*'));

        // Test flush all
        await clearRedisCache({ params: { type: 'all' }, query: {}, body: {} }, mockRes);
        assert.equal(statusCode, 200);
        assert.equal(jsonResult.success, true);
        assert.equal(flushCalled, true);
    } finally {
        redis.scan = origScan;
        redis.del = origDel;
        redis.flushdb = origFlush;
        try { redis.disconnect(); } catch (_) {}
    }
});
