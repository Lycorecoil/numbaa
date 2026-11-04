const { test } = require('node:test');
const assert = require('node:assert/strict');
const { randomUUID } = require('node:crypto');
const { readFileSync } = require('node:fs');
const path = require('node:path');
const { Pool } = require('pg');

// Opt in with a disposable test database. Never use application/production credentials.
test('PostgreSQL P0 integration in an isolated schema', {
  skip: !process.env.TEST_DATABASE_URL && 'Set TEST_DATABASE_URL to a dedicated PostgreSQL test database',
}, async t => {
  const schema = `p0_${randomUUID().replaceAll('-', '')}`;
  const admin = new Pool({ connectionString: process.env.TEST_DATABASE_URL });
  const url = new URL(process.env.TEST_DATABASE_URL);
  url.searchParams.set('options', `-c search_path=${schema},public`);
  process.env.DATABASE_URL = url.toString();
  process.env.NODE_ENV = 'test';
  process.env.JWT_SECRET = 'test-only-placeholder-never-used-for-real-auth';
  const db = require('../dist/config/database');
  db.pool.options.max = 1; // Expose leaked transaction clients on subsequent queries.
  const sites = require('../dist/modules/site/site.service');
  const products = require('../dist/modules/product/product.service');
  let created = false;
  try {
    await admin.query(`CREATE SCHEMA "${schema}"`);
    created = true;
    // Use the actual schema without installing an extension into the test database.
    const migration = readFileSync(path.join(__dirname, '../src/db/migrations/001_init.sql'), 'utf8')
      .replace('CREATE EXTENSION IF NOT EXISTS "pgcrypto";', '');
    await db.query(migration);
    const userA = randomUUID(), userB = randomUUID();
    const businessA = randomUUID(), businessB = randomUUID();
    await db.query('INSERT INTO users (id, phone) VALUES ($1, $2), ($3, $4)', [userA, 'test-a', userB, 'test-b']);
    await db.query("INSERT INTO businesses (id, user_id, name, category) VALUES ($1, $2, 'A', 'shop'), ($3, $4, 'B', 'shop')", [businessA, userA, businessB, userB]);
    await db.query("INSERT INTO templates (id, name, website_type, default_sections) VALUES ('test', 'Test', 'showcase', '{}')");
    const section = { id: randomUUID(), type: 'hero', title: 'Original', content: '', order: 0 };
    const data = { businessId: businessA, templateId: 'test', websiteType: 'showcase', sections: [section] };
    let siteA, siteB;
    await t.test('foreign business refused with no inserted site', async () => {
      await assert.rejects(sites.create(userB, data), { status: 403 });
      assert.equal((await db.query('SELECT * FROM sites')).rowCount, 0);
    });
    await t.test('failed creation leaves neither site nor sections', async () => {
      await assert.rejects(sites.create(userA, { ...data, sections: [section, section] }), { code: '23505' });
      assert.equal((await db.query('SELECT * FROM sites')).rowCount, 0);
      assert.equal((await db.query('SELECT * FROM site_sections')).rowCount, 0);
      // A pool with max=1 would hang here if the failed transaction leaked its client.
      assert.equal((await db.query('SELECT 1 AS ok')).rows[0].ok, 1);
    });
    await t.test('owner creation commits site and sections', async () => {
      siteA = await sites.create(userA, data);
      assert.equal(siteA.sections[0].title, 'Original');
      assert.equal((await db.query('SELECT * FROM sites')).rowCount, 1);
      siteB = await sites.create(userB, { ...data, businessId: businessB, sections: [] });
    });
    await t.test('failed replacement restores site fields and original sections', async () => {
      const replacement = { ...section, id: randomUUID(), title: 'Replacement' };
      await assert.rejects(sites.updateSite(siteA.id, { primaryColor: '#123456', sections: [replacement, replacement] }), { code: '23505' });
      const persisted = await sites.getByBusinessId(businessA);
      assert.equal(persisted.primary_color, null);
      assert.equal(persisted.sections.length, 1);
      assert.equal(persisted.sections[0].id, section.id);
      assert.equal(persisted.sections[0].title, 'Original');
    });
    await t.test('successful replacement commits fields and sections together', async () => {
      const replacement = { ...section, id: randomUUID(), title: 'Replacement' };
      await sites.updateSite(siteA.id, { primaryColor: '#123456', sections: [replacement] });
      const persisted = await sites.getByBusinessId(businessA);
      assert.equal(persisted.primary_color, '#123456');
      assert.equal(persisted.sections[0].id, replacement.id);
    });
    await t.test('cross-site mutations leave product untouched; authorized mutations succeed', async () => {
      const item = await products.create({ site_id: siteB.id, name: 'Original', description: '', price: 10, image_url: null, category: '' });
      assert.equal(await products.update(siteA.id, item.id, { name: 'Attack' }), null);
      assert.equal(await products.remove(siteA.id, item.id), false);
      assert.equal(await products.getById(siteA.id, item.id), null);
      assert.equal(await products.updateImage(siteA.id, item.id, 'https://example.test/attack'), false);
      const unchanged = await products.getById(siteB.id, item.id);
      assert.equal(unchanged.name, 'Original');
      assert.equal(unchanged.image_url, null);
      assert.equal((await products.update(siteB.id, item.id, { name: 'Allowed' })).name, 'Allowed');
      assert.equal(await products.updateImage(siteB.id, item.id, 'https://example.test/allowed'), true);
      assert.equal(await products.remove(siteB.id, item.id), true);
    });
    await t.test('site deletion cascades to sections and products', async () => {
      await products.create({ site_id: siteA.id, name: 'Item', description: '', price: 1, image_url: null, category: '' });
      await sites.deleteSite(siteA.id);
      assert.equal(await sites.getByBusinessId(businessA), null);
      assert.equal((await db.query('SELECT * FROM site_sections WHERE site_id = $1', [siteA.id])).rowCount, 0);
      assert.equal((await products.getAll(siteA.id)).length, 0);
    });
  } finally {
    await db.pool.end();
    if (created) await admin.query(`DROP SCHEMA "${schema}" CASCADE`);
    await admin.end();
  }
});
