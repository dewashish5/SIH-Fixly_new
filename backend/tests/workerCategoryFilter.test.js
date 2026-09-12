import test from 'node:test';
import assert from 'node:assert/strict';

import { buildCategoryCondition } from '../utils/workerCategoryFilter.js';

const matches = (condition, profile) =>
    condition.$or.some((entry) => {
        const [path, value] = Object.entries(entry)[0];
        const field = path.split('.').reduce((current, key) => {
            if (Array.isArray(current)) return current.flatMap((item) => item?.[key] ?? []);
            return current?.[key];
        }, profile);
        const regex = value.$regex;
        return Array.isArray(field) ? field.some((item) => regex.test(item)) : regex.test(field ?? '');
    });

test('category filter matches primary, offered, and rated categories using category ids', () => {
    const condition = buildCategoryCondition('plumber');

    assert.equal(matches(condition, { workerProfile: { category: 'Plumbing' } }), true);
    assert.equal(matches(condition, { workerProfile: { categories: ['Plumbing', 'Electrician'] } }), true);
    assert.equal(matches(condition, { workerProfile: { categoryRates: [{ category: 'Plumbing' }] } }), true);
});

test('category filter does not match an unrelated category', () => {
    const condition = buildCategoryCondition('plumber');

    assert.equal(matches(condition, { workerProfile: { category: 'Cleaning' } }), false);
});
