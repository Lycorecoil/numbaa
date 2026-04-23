import { Request, Response, NextFunction } from 'express';
import * as svc from './plan.service';

export async function getMe(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const plan = await svc.getByUserId(req.user!.id);
    if (!plan) { res.status(404).json({ success: false, message: 'Aucun forfait trouvé.' }); return; }
    res.json({
      success: true,
      plan: {
        name: plan.name,
        expiresAt: plan.expires_at,
        smsRemaining: plan.sms_remaining,
        totalSms: plan.total_sms,
        dataRemainingMb: plan.data_remaining_mb,
        dataTotalMb: plan.data_total_mb,
      },
    });
  } catch (err) { next(err); }
}
