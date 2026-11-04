const { test, before, after, afterEach, mock } = require('node:test');
const assert = require('node:assert/strict');
const http = require('node:http');
const { gzipSync } = require('node:zlib');

process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgres://unused:unused@localhost/unused';
process.env.JWT_SECRET = 'test-only-placeholder-never-used-for-real-auth';
// Replace only Redis's network boundary. The actual app, parsers, JWT middleware
// and rate-limit middleware are exercised; no database or WhatsApp is contacted.
const redis = { exists: async () => 0 };
const redisPath = require.resolve('../dist/config/redis');
require.cache[redisPath] = { id: redisPath, filename: redisPath, loaded: true, exports: { redis } };
const app = require('../dist/app').default;
const authService = require('../dist/modules/auth/auth.service');
const { generateToken } = require('../dist/middlewares/auth.middleware');
let server, port;
before(async () => {
  server = app.listen(0, '127.0.0.1');
  await new Promise(resolve => server.once('listening', resolve));
  port = server.address().port;
});
after(async () => { await new Promise(resolve => server.close(resolve)); });
afterEach(() => mock.restoreAll());
function request(path, { body, headers = {}, method = 'GET' } = {}) {
  return new Promise((resolve, reject) => {
    const req = http.request({ host: '127.0.0.1', port, path, method, headers }, res => {
      let text = '';
      res.on('data', chunk => { text += chunk; });
      res.on('end', () => resolve({ status: res.statusCode, headers: res.headers, text }));
    });
    req.on('error', reject);
    req.end(body);
  });
}
test('actual app accepts valid gzip JSON and urlencoded bodies', async () => {
  const login = mock.method(authService, 'loginWithPassword', async (phone, password) => {
    assert.equal(phone, '00000000');
    assert.equal(password, 'test');
    return { token: 'mock-token', user: { id: 'test-user' } };
  });
  for (const [contentType, body] of [
    ['application/json', JSON.stringify({ phone: '00000000', password: 'test' })],
    ['application/x-www-form-urlencoded', 'phone=00000000&password=test'],
  ]) {
    const res = await request('/v1/auth/login', { method: 'POST', body: gzipSync(body), headers: { 'Content-Type': contentType, 'Content-Encoding': 'gzip' } });
    assert.equal(res.status, 200);
    assert.equal(JSON.parse(res.text).token, 'mock-token');
  }
  assert.equal(login.mock.callCount(), 2);
});
test('malformed gzip returns 400 and leaves the process serving requests', async () => {
  const res = await request('/v1/auth/login', { method: 'POST', body: Buffer.from('invalid-gzip'), headers: { 'Content-Type': 'application/json', 'Content-Encoding': 'gzip' } });
  assert.equal(res.status, 400);
  assert.equal((await request('/health')).status, 200);
});
test('gzip with trailing garbage cannot terminate the actual app', async () => {
  for (const contentType of ['application/json', 'application/x-www-form-urlencoded']) {
    const valid = contentType === 'application/json' ? '{}' : 'a=b';
    const body = Buffer.concat([gzipSync(valid), Buffer.from('trailing-invalid-frame')]);
    const res = await request('/nonexistent', { method: 'POST', body, headers: { 'Content-Type': contentType, 'Content-Encoding': 'gzip' } });
    assert.ok([400, 404].includes(res.status), `Unexpected status ${res.status}`);
    await new Promise(resolve => setTimeout(resolve, 30));
    assert.equal((await request('/health')).status, 200);
  }
});
test('one trusted proxy hop keys OTP rate limiting by nearest forwarded address', async () => {
  assert.equal(app.get('trust proxy'), 1);
  const send = mock.method(authService, 'requestOtp', async () => ({}));
  for (let i = 0; i < 4; i++) {
    const res = await request('/v1/auth/request-otp', {
      method: 'POST', body: JSON.stringify({ phone: '00000000' }),
      headers: { 'Content-Type': 'application/json', 'X-Forwarded-For': `198.51.100.${i + 1}, 203.0.113.10` },
    });
    assert.equal(res.status, i < 3 ? 200 : 429);
  }
  assert.equal(send.mock.callCount(), 3);
});
test('JWT middleware rejects invalid tokens and expired Redis sessions', async () => {
  assert.equal((await request('/v1/auth/me')).status, 401);
  assert.equal((await request('/v1/auth/me', { headers: { Authorization: 'Bearer invalid' } })).status, 401);
  const session = mock.method(redis, 'exists', async key => { assert.equal(key, 'session:test-user'); return 0; });
  const res = await request('/v1/auth/me', { headers: { Authorization: `Bearer ${generateToken({ id: 'test-user', phone: '00000000' })}` } });
  assert.equal(res.status, 401);
  assert.equal(JSON.parse(res.text).code, 'SESSION_EXPIRED');
  assert.equal(session.mock.callCount(), 1);
});
