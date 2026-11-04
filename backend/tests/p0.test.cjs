const { test, afterEach, mock } = require('node:test');
const assert = require('node:assert/strict');
process.env.NODE_ENV = 'test';
process.env.DATABASE_URL = 'postgres://unused:unused@localhost/unused';
process.env.JWT_SECRET = 'test-only-placeholder-never-used-for-real-auth';
const db = require('../dist/config/database');
const sites = require('../dist/modules/site/site.service');
const products = require('../dist/modules/product/product.service');
const blob = require('../dist/storage/blob.storage');
const siteController = require('../dist/modules/site/site.controller');
const controller = require('../dist/modules/product/product.controller');
afterEach(() => mock.restoreAll());
const site = { id: 'site-a', business_id: 'business-a', sections: [] };
const product = { id: 'product-a', site_id: 'site-a', name: 'Item', price: '12.00' };
const section = { id: 'section-a', type: 'hero', title: 'Hello', content: '', order: 0 };
function request(overrides = {}) {
  return { user: { id: 'user-a' }, params: { siteId: 'site-a', productId: 'product-a' }, body: {}, ...overrides };
}
async function invoke(handler, req) {
  let error;
  const res = { statusCode: 200, status(code) { this.statusCode = code; return this; }, json(body) { this.body = body; return this; } };
  await handler(req, res, err => { error = err; });
  if (error) throw error;
  return res;
}
function transaction(handler = async () => ({ rows: [] })) {
  const calls = [];
  const release = mock.fn();
  const client = { release, query: async (sql, params) => { calls.push({ sql, params }); return handler(sql, params); } };
  mock.method(db.pool, 'connect', async () => client);
  mock.method(db.pool, 'query', async () => { throw Error('Transaction escaped to pool.query'); });
  return { client, calls, release };
}
test('transaction commits on the same client and releases it', async () => {
  const tx = transaction();
  assert.equal(await db.withTransaction(async client => { assert.equal(client, tx.client); await client.query('WORK'); return 42; }), 42);
  assert.deepEqual(tx.calls.map(c => c.sql), ['BEGIN', 'WORK', 'COMMIT']);
  assert.deepEqual(tx.release.mock.calls[0].arguments, [false]);
});
for (const failure of ['BEGIN', 'WORK', 'COMMIT']) {
  test(`transaction rolls back and releases after ${failure} failure`, async () => {
    const error = Error(failure);
    const tx = transaction(async sql => { if (sql === failure) throw error; return { rows: [] }; });
    await assert.rejects(db.withTransaction(client => client.query('WORK')), err => err === error);
    assert.equal(tx.calls.at(-1).sql, 'ROLLBACK');
    assert.equal(tx.release.mock.callCount(), 1);
  });
}
test('rollback failure discards connection and preserves original error', async () => {
  const error = Error('original');
  const tx = transaction(async sql => { if (sql === 'ROLLBACK') throw Error('rollback'); return { rows: [] }; });
  await assert.rejects(db.withTransaction(async () => { throw error; }), err => err === error);
  assert.deepEqual(tx.release.mock.calls[0].arguments, [true]);
});
test('connection acquisition failure does not execute work', async () => {
  mock.method(db.pool, 'connect', async () => { throw Error('offline'); });
  const work = mock.fn();
  await assert.rejects(db.withTransaction(work), /offline/);
  assert.equal(work.mock.callCount(), 0);
});
test('SEC-01 owner creates site and sections on one transaction', async () => {
  const tx = transaction(async (sql, params) => {
    if (sql.startsWith('SELECT id FROM businesses')) { assert.deepEqual(params, ['business-a', 'user-a']); return { rows: [{ id: 'business-a' }] }; }
    if (sql.includes('INSERT INTO sites')) return { rows: [{ ...site }] };
    if (sql.startsWith('SELECT * FROM site_sections')) return { rows: [section] };
    return { rows: [] };
  });
  const result = await sites.create('user-a', { businessId: 'business-a', templateId: 'template', websiteType: 'showcase', sections: [section] });
  assert.deepEqual(result.sections, [section]);
  assert.equal(tx.calls.at(-1).sql, 'COMMIT');
  assert.ok(tx.calls.some(c => c.sql.includes('INSERT INTO site_sections')));
});
test('SEC-01 foreign or missing business refused before insertion', async () => {
  const tx = transaction();
  await assert.rejects(sites.create('user-b', { businessId: 'business-a', sections: [] }), { status: 403 });
  assert.equal(tx.calls.some(c => c.sql.includes('INSERT')), false);
  assert.equal(tx.calls.at(-1).sql, 'ROLLBACK');
});
test('SEC-01 absent identity refused by controller and service', async () => {
  const create = mock.method(sites, 'create');
  assert.equal((await invoke(siteController.create, request({ user: undefined }))).statusCode, 401);
  assert.equal(create.mock.callCount(), 0);
  create.mock.restore();
  await assert.rejects(sites.create(undefined, {}), { status: 401 });
});
test('SEC-01 controller forwards authenticated identity and preserves response', async () => {
  const create = mock.method(sites, 'create', async () => site);
  const res = await invoke(siteController.create, request({ body: { businessId: 'business-a' } }));
  assert.equal(res.statusCode, 201);
  assert.equal(res.body.site.businessId, 'business-a');
  assert.deepEqual(create.mock.calls[0].arguments, ['user-a', { businessId: 'business-a', sections: [], templateId: undefined, websiteType: undefined }]);
});
for (const operation of ['create', 'update']) {
  test(`DATA-01 ${operation} rolls back after section insertion fails`, async () => {
    const tx = transaction(async sql => {
      if (sql.includes('INSERT INTO site_sections')) throw Error('section failure');
      return { rows: [{ ...site }] };
    });
    const data = { businessId: 'business-a', sections: [section] };
    await assert.rejects(operation === 'create' ? sites.create('user-a', data) : sites.updateSite('site-a', data), /section failure/);
    assert.equal(tx.calls.at(-1).sql, 'ROLLBACK');
    assert.equal(tx.calls.some(c => c.sql === 'COMMIT'), false);
    assert.equal(tx.release.mock.callCount(), 1);
  });
}
test('DATA-01 clearing sections commits atomically', async () => {
  const tx = transaction(async () => ({ rows: [{ ...site }] }));
  await sites.updateSite('site-a', { sections: [] });
  assert.ok(tx.calls.some(c => c.sql.startsWith('DELETE FROM site_sections')));
  assert.equal(tx.calls.at(-1).sql, 'COMMIT');
});
test('DATA-01 missing site does not delete or insert sections', async () => {
  const tx = transaction();
  assert.equal(await sites.updateSite('missing', { sections: [section] }), null);
  assert.equal(tx.calls.some(c => /DELETE|INSERT/.test(c.sql)), false);
});
test('DATA-01 deletion uses one cascading statement', async () => {
  const query = mock.method(db, 'query', async () => ({ rows: [], rowCount: 1 }));
  await sites.deleteSite('site-a');
  assert.deepEqual(query.mock.calls.map(c => c.arguments), [['DELETE FROM sites WHERE id = $1', ['site-a']]]);
});
test('SEC-02 SQL mutations and lookup bind both product and site', async () => {
  const calls = [];
  mock.method(db, 'query', async (sql, params) => { calls.push({ sql, params }); return { rows: [], rowCount: 0 }; });
  assert.equal(await products.update('site-a', 'foreign', { name: 'Changed' }), null);
  assert.equal(await products.remove('site-a', 'foreign'), false);
  assert.equal(await products.updateImage('site-a', 'foreign', 'url'), false);
  assert.equal(await products.getById('site-a', 'foreign'), null);
  for (const { sql, params } of calls) {
    assert.match(sql, /WHERE id = \$1 AND site_id = \$\d/);
    assert.equal(params[0], 'foreign');
    assert.equal(params.at(-1), 'site-a');
  }
});
for (const operation of ['update', 'remove', 'uploadImage']) {
  test(`SEC-02 ${operation} refuses a product outside the authorized site`, async () => {
    mock.method(sites, 'assertSiteOwner', async () => site);
    const target = mock.method(products, operation === 'uploadImage' ? 'getById' : operation, async () => operation === 'remove' ? false : null);
    const upload = mock.method(blob, 'uploadImageToBlob', async () => { throw Error('Must not upload'); });
    assert.equal((await invoke(controller[operation], request({ file: {} }))).statusCode, 404);
    assert.deepEqual(target.mock.calls[0].arguments.slice(0, 2), ['site-a', 'product-a']);
    assert.equal(upload.mock.callCount(), 0);
  });
  test(`SEC-02 ${operation} stops when site ownership denied`, async () => {
    mock.method(sites, 'assertSiteOwner', async () => { throw Object.assign(Error('denied'), { status: 404 }); });
    const target = mock.method(products, operation === 'uploadImage' ? 'getById' : operation);
    const upload = mock.method(blob, 'uploadImageToBlob');
    await assert.rejects(invoke(controller[operation], request()), { status: 404 });
    assert.equal(target.mock.callCount(), 0);
    assert.equal(upload.mock.callCount(), 0);
  });
}
test('SEC-02 authorized update preserves API response', async () => {
  mock.method(sites, 'assertSiteOwner', async () => site);
  mock.method(products, 'update', async () => product);
  const res = await invoke(controller.update, request({ body: { name: 'Item', price: 12 } }));
  assert.equal(res.statusCode, 200);
  assert.equal(res.body.product.siteId, 'site-a');
  assert.equal(res.body.product.price, 12);
});
test('SEC-02 authorized deletion succeeds', async () => {
  mock.method(sites, 'assertSiteOwner', async () => site);
  mock.method(products, 'remove', async () => true);
  assert.deepEqual((await invoke(controller.remove, request())).body, { success: true });
});
test('SEC-02 upload checks target before transfer and scopes image update', async () => {
  const order = [];
  mock.method(sites, 'assertSiteOwner', async () => { order.push('owner'); return site; });
  mock.method(products, 'getById', async () => { order.push('product'); return product; });
  mock.method(blob, 'uploadImageToBlob', async () => { order.push('upload'); return 'https://example.test/image'; });
  const update = mock.method(products, 'updateImage', async () => { order.push('update'); return true; });
  const res = await invoke(controller.uploadImage, request({ file: {} }));
  assert.deepEqual(order, ['owner', 'product', 'upload', 'update']);
  assert.deepEqual(update.mock.calls[0].arguments, ['site-a', 'product-a', 'https://example.test/image']);
  assert.equal(res.body.imageUrl, 'https://example.test/image');
});
test('SEC-02 upload reports concurrent deletion instead of success', async () => {
  mock.method(sites, 'assertSiteOwner', async () => site);
  mock.method(products, 'getById', async () => product);
  mock.method(blob, 'uploadImageToBlob', async () => 'https://example.test/image');
  mock.method(products, 'updateImage', async () => false);
  assert.equal((await invoke(controller.uploadImage, request({ file: {} }))).statusCode, 404);
});
