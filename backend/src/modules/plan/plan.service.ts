import { query } from '../../config/database';

export interface PlanRow {
  id: string;
  user_id: string;
  name: string;
  expires_at: Date;
  sms_remaining: number;
  total_sms: number;
  data_remaining_mb: number;
  data_total_mb: number;
}

export async function getByUserId(userId: string): Promise<PlanRow | null> {
  const r = await query<PlanRow>('SELECT * FROM plans WHERE user_id = $1', [userId]);
  return r.rows[0] ?? null;
}
