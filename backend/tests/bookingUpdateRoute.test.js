import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';

test('booking routes expose the customer booking update endpoint', () => {
    const routes = fs.readFileSync(new URL('../routes/booking-routes.js', import.meta.url), 'utf8');

    assert.match(routes, /router\.patch\('\/:bookingId',\s*protect,\s*updateBooking\)/);
});
