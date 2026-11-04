const { test, afterEach, mock } = require('node:test');
const assert = require('node:assert/strict');
const { EventEmitter } = require('node:events');
const http = require('node:http');
const https = require('node:https');
const { createRequire } = require('node:module');
const { MockAgent, setGlobalDispatcher, getGlobalDispatcher } = require('undici');

process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgres://unused:unused@localhost/unused';
process.env.JWT_SECRET = 'test-only-placeholder-never-used-for-real-auth';
process.env.umbaa_media_READ_WRITE_TOKEN = 'vercel_blob_rw_test_dummy';
process.env.VERCEL_TOKEN = 'test-only-placeholder';
process.env.VERCEL_TEAM_ID = 'test-team';
afterEach(() => mock.restoreAll());

test('real Blob SDK uploads through a blocked-network mock dispatcher', async () => {
  const previous = getGlobalDispatcher();
  const agent = new MockAgent();
  agent.disableNetConnect();
  setGlobalDispatcher(agent);
  process.env.VERCEL_BLOB_API_URL = 'https://blob-api.example.test';
  const url = 'https://test.public.blob.vercel-storage.com/products/test.png';
  const upload = agent.get('https://blob-api.example.test').intercept({
    method: 'PUT', path: /products/,
    headers: headers => headers.authorization === 'Bearer vercel_blob_rw_test_dummy',
  }).reply(200, { url, downloadUrl: `${url}?download=1`, pathname: 'products/test.png', contentType: 'image/png', contentDisposition: 'inline', size: 3 }, { headers: { 'content-type': 'application/json' } });
  try {
    const { uploadImageToBlob } = require('../dist/storage/blob.storage');
    assert.equal(await uploadImageToBlob('products', 'test', { originalname: 'photo.png', mimetype: 'image/png', buffer: Buffer.from('png') }), url);
    agent.assertNoPendingInterceptors();
  } finally {
    delete process.env.VERCEL_BLOB_API_URL;
    setGlobalDispatcher(previous);
    await agent.close();
  }
});

test('OIDC resolves a synthetic unexpired request token without contacting Vercel', async () => {
  const oidc = require('@vercel/oidc');
  const token = `eyJhbGciOiJub25lIn0.${Buffer.from(JSON.stringify({ exp: Math.floor(Date.now() / 1000) + 3600 })).toString('base64url')}.dummy`;
  const contextKey = Symbol.for('@vercel/request-context');
  const previousContext = globalThis[contextKey];
  const agent = new MockAgent();
  agent.disableNetConnect();
  const previousDispatcher = getGlobalDispatcher();
  setGlobalDispatcher(agent);
  globalThis[contextKey] = { get: () => ({ headers: { 'x-vercel-oidc-token': token } }) };
  try {
    assert.equal(oidc.getVercelOidcTokenSync(), token);
    assert.equal(await oidc.getVercelOidcToken(), token);
  } finally {
    if (previousContext === undefined) delete globalThis[contextKey]; else globalThis[contextKey] = previousContext;
    setGlobalDispatcher(previousDispatcher);
    await agent.close();
  }
});

test('overridden Vercel config preserves auth/global schema contracts', () => {
  // Resolve the exact cli-config consumed by oidc, even when npm nests it.
  const fromOidc = createRequire(require.resolve('@vercel/oidc'));
  const config = fromOidc('@vercel/cli-config');
  assert.equal(config.parseAuthConfig({ token: 'test-token', expiresAt: 42 }).token, 'test-token');
  assert.equal(config.parseGlobalConfig({ currentTeam: 'test-team', telemetry: { enabled: false } }).currentTeam, 'test-team');
  assert.equal(config.authConfigSchema.safeParse({ expiresAt: 'invalid' }).success, false);
  assert.equal(config.globalConfigSchema.safeParse({ telemetry: { enabled: 'invalid' } }).success, false);
});

test('Axios redirects preserve responses and strip credentials across origins', async () => {
  const axios = require('axios');
  let receivedAuthorization;
  const destination = http.createServer((req, res) => { receivedAuthorization = req.headers.authorization; res.setHeader('Content-Type', 'application/json'); res.end('{"ok":true}'); });
  await new Promise(resolve => destination.listen(0, '127.0.0.1', resolve));
  const source = http.createServer((_req, res) => { res.writeHead(302, { Location: `http://127.0.0.1:${destination.address().port}/result` }); res.end(); });
  await new Promise(resolve => source.listen(0, '127.0.0.1', resolve));
  try {
    const url = `http://localhost:${source.address().port}/redirect`;
    // Source uses IPv4 explicitly; destination hostname differs, testing the
    // library's cross-origin credential stripping rather than a production API.
    const result = await axios.get(url, { proxy: false, family: 4, headers: { Authorization: 'Bearer dummy' } });
    assert.equal(result.data.ok, true);
    assert.equal(receivedAuthorization, undefined);
  } finally {
    await Promise.all([new Promise(resolve => source.close(resolve)), new Promise(resolve => destination.close(resolve))]);
  }
});

test('Baileys still imports and its updated image/media dependencies parse fixtures', async () => {
  const sdk = await import('@whiskeysockets/baileys');
  assert.equal(typeof sdk.makeWASocket, 'function');
  assert.equal(typeof sdk.useMultiFileAuthState, 'function');
  const sharp = require('sharp');
  const image = await sharp({ create: { width: 2, height: 2, channels: 3, background: '#ff7900' } }).png().toBuffer();
  const metadata = await sharp(image).metadata();
  assert.equal(metadata.width, 2);
  assert.equal(metadata.format, 'png');
  const wav = Buffer.alloc(46);
  wav.write('RIFF'); wav.writeUInt32LE(38, 4); wav.write('WAVEfmt ', 8);
  wav.writeUInt32LE(16, 16); wav.writeUInt16LE(1, 20); wav.writeUInt16LE(1, 22);
  wav.writeUInt32LE(8000, 24); wav.writeUInt32LE(16000, 28); wav.writeUInt16LE(2, 32); wav.writeUInt16LE(16, 34);
  wav.write('data', 36); wav.writeUInt32LE(2, 40);
  const { parseBuffer } = await import('music-metadata');
  assert.equal((await parseBuffer(wav, 'audio/wav')).format.sampleRate, 8000);
});

test('OTP generation stores expiry and calls only a mocked WhatsApp sender', async () => {
  const entries = [];
  const redisPath = require.resolve('../dist/config/redis');
  const senderPath = require.resolve('../dist/whatsapp/baileys.client');
  const sender = mock.fn(async () => {});
  require.cache[redisPath] = { id: redisPath, filename: redisPath, loaded: true, exports: { redis: { ttl: async () => -2, set: async (...args) => entries.push(args) } } };
  require.cache[senderPath] = { id: senderPath, filename: senderPath, loaded: true, exports: { sendWhatsAppMessage: sender } };
  const { env } = require('../dist/config/env');
  env.BYPASS_WHATSAPP = false;
  const otp = require('../dist/whatsapp/otp.service');
  await otp.generateAndSendOtp('00000000');
  assert.equal(entries.length, 1);
  assert.equal(entries[0][0], 'otp:00000000');
  const stored = JSON.parse(entries[0][1]);
  assert.match(stored.code, /^\d{4}$/);
  assert.deepEqual(entries[0].slice(2), ['EX', 300]);
  assert.equal(sender.mock.callCount(), 1);
  assert.ok(sender.mock.calls[0].arguments[1].includes(stored.code));
});

test('publication uses only mocked HTTPS and preserves alias response handling', async () => {
  let body = '';
  const request = mock.method(https, 'request', (options, callback) => {
    assert.equal(options.hostname, 'api.vercel.com');
    assert.equal(options.path, '/v13/deployments?teamId=test-team');
    const req = new EventEmitter();
    req.write = chunk => { body += chunk; };
    req.end = () => {
      const res = new EventEmitter();
      res.statusCode = 200;
      callback(res);
      res.emit('data', JSON.stringify({ alias: ['test-only.vercel.app'], url: 'test-only-hash.vercel.app' }));
      res.emit('end');
    };
    return req;
  });
  const { deployToVercel } = require('../dist/publisher/vercel.deployer');
  assert.equal(await deployToVercel('12345678-test', 'Test', '<h1>Fixture</h1>'), 'https://test-only.vercel.app');
  assert.equal(Buffer.from(JSON.parse(body).files[0].data, 'base64').toString(), '<h1>Fixture</h1>');
  assert.equal(request.mock.callCount(), 1);
});
