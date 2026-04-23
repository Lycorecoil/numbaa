import { Pool, QueryResult, QueryResultRow } from 'pg';
import { env } from './env';

const pool = new Pool({
  connectionString: env.DATABASE_URL,
  max: 10,
  min: 2,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 10000,
});

pool.on('error', (err) => {
  console.error('[DB] Unexpected pool error:', err);
});

export async function connectDatabase(): Promise<void> {
  const client = await pool.connect();
  client.release();
  console.log('[DB] PostgreSQL connected');
}

export async function query<T extends QueryResultRow = QueryResultRow>(
  text: string,
  params?: unknown[]
): Promise<QueryResult<T>> {
  const start = Date.now();
  const result = await pool.query<T>(text, params);
  if (env.isDevelopment) {
    console.log(`[DB] query (${Date.now() - start}ms):`, text.slice(0, 80));
  }
  return result;
}

export { pool };
