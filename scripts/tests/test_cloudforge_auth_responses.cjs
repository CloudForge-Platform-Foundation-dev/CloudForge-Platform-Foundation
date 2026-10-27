'use strict';
const test = require('node:test');
const assert = require('node:assert');
// C-2 unit tests. Run locally: node --test scripts/tests/test_cloudforge_auth_responses.cjs
// (not wired into CI; no workflow calls scripts/tests)
const { check: run } = require('../../functions/cloudforgeAuthResponses.js');
const ok = { 200: {}, 401: {}, 403: {} };
const sec = [{ bearerAuth: [] }];
const n = (d) => run(d).length;

test('op-level security with both 401+403 -> pass', () =>
  assert.strictEqual(n({ paths: { '/a': { get: { security: sec, responses: ok } } } }), 0));
test('op-level security missing 403 -> 1 finding naming 403', () => {
  const r = run({ paths: { '/a': { get: { security: sec, responses: { 200: {}, 401: {} } } } } });
  assert.strictEqual(r.length, 1); assert.match(r[0].message, /403/); assert.doesNotMatch(r[0].message, /401,/);
});
test('missing both -> one finding listing both', () =>
  assert.match(run({ paths: { '/a': { post: { security: sec, responses: { 200: {} } } } } })[0].message, /401, 403/));
test('root security inherited, op lacks 401/403 -> finding', () =>
  assert.strictEqual(n({ security: sec, paths: { '/a': { get: { responses: { 200: {} } } } } }), 1));
test('root security but op security: [] (public, e.g. health) -> pass', () =>
  assert.strictEqual(n({ security: sec, paths: { '/health': { get: { security: [], responses: { 200: {} } } } } }), 0));
test('no security anywhere -> pass', () =>
  assert.strictEqual(n({ paths: { '/a': { get: { responses: { 200: {} } } } } }), 0));
test('security: [] at root only (Ops style) -> pass', () =>
  assert.strictEqual(n({ security: [], paths: { '/a': { get: { responses: { 200: {} } } } } }), 0));
test('optional auth ({} entry) -> not enforced -> pass', () =>
  assert.strictEqual(n({ paths: { '/a': { get: { security: [{}, { bearerAuth: [] }], responses: { 200: {} } } } } }), 0));
test('4XX / default do not satisfy', () =>
  assert.strictEqual(n({ paths: { '/a': { get: { security: sec, responses: { '4XX': {}, default: {} } } } } }), 1));
test('only operations inspected, not path-level parameters/summary', () =>
  assert.strictEqual(n({ paths: { '/a': { parameters: [], summary: 'x', get: { security: sec, responses: ok } } } }), 0));
test('malformed docs do not throw', () => {
  assert.strictEqual(n(null), 0); assert.strictEqual(n({}), 0); assert.strictEqual(n({ paths: { '/a': null } }), 0);
  assert.strictEqual(n({ paths: { '/a': { get: { security: sec } } } }), 1); // no responses at all
});

// --- additional cases (added beyond the original 11) ---
test('root security: [] but operation declares its own security and lacks 401/403 -> finding', () =>
  assert.strictEqual(n({ security: [], paths: { '/a': { get: { security: sec, responses: { 200: {} } } } } }), 1));
test('every HTTP method is inspected; non-method keys are ignored', () => {
  const methods = ['get', 'put', 'post', 'delete', 'options', 'head', 'patch', 'trace'];
  const item = { 'x-extension': { security: sec }, servers: [], description: 'd' };
  for (const m of methods) item[m] = { security: sec, responses: { 200: {} } };
  assert.strictEqual(n({ paths: { '/a': item } }), methods.length);
});
test('finding path points at the operation responses (used by Spectral for location)', () => {
  const r = run({ paths: { '/orders': { delete: { security: sec, responses: { 200: {} } } } } });
  assert.deepStrictEqual(r[0].path, ['paths', '/orders', 'delete', 'responses']);
});
