import fs from 'fs';
import path from 'path';
import { pool } from '../config/database';
import '../config/env'; // charge les variables

async function migrate(): Promise<void> {
  const migrationFile = path.resolve(__dirname, 'migrations/001_init.sql');
  const sql = fs.readFileSync(migrationFile, 'utf-8');

  console.log('[Migrate] Running 001_init.sql...');
  await pool.query(sql);
  console.log('[Migrate] Done.');
  await pool.end();
}

migrate().catch((err) => {
  console.error('[Migrate] Error:', err);
  process.exit(1);
});
