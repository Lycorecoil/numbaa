import { Request, Response, NextFunction } from 'express';
import { validationResult } from 'express-validator';
import * as authService from './auth.service';

export async function requestOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(422).json({ success: false, errors: errors.array() });
    return;
  }
  try {
    const { debugCode } = await authService.requestOtp(req.body.phone);
    res.json({
      success: true,
      message: 'Code OTP envoyé via WhatsApp.',
      ...(debugCode !== undefined && { debugCode }),
    });
  } catch (err) {
    next(err);
  }
}

export async function verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(422).json({ success: false, errors: errors.array() });
    return;
  }
  try {
    const { phone, code, language } = req.body;
    const { token, user, needsPassword } = await authService.verifyOtpAndLogin(phone, code, language ?? 'french');
    res.json({
      success: true,
      token,
      needsPassword,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        language: user.language,
        hasCompletedOnboarding: user.has_completed_onboarding,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function loginWithPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(422).json({ success: false, errors: errors.array() });
    return;
  }
  try {
    const { phone, password } = req.body;
    const { token, user } = await authService.loginWithPassword(phone, password);
    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        language: user.language,
        hasCompletedOnboarding: user.has_completed_onboarding,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function setPassword(req: Request, res: Response, next: NextFunction): Promise<void> {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(422).json({ success: false, errors: errors.array() });
    return;
  }
  try {
    await authService.setPassword(req.user!.id, req.body.password);
    res.json({ success: true, message: 'Mot de passe défini.' });
  } catch (err) {
    next(err);
  }
}

export async function logout(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await authService.logout(req.user!.id);
    res.json({ success: true, message: 'Déconnecté.' });
  } catch (err) {
    next(err);
  }
}

export async function me(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const user = await authService.getMe(req.user!.id);
    if (!user) {
      res.status(404).json({ success: false, message: 'Utilisateur introuvable.' });
      return;
    }
    res.json({
      success: true,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        language: user.language,
        hasCompletedOnboarding: user.has_completed_onboarding,
      },
    });
  } catch (err) {
    next(err);
  }
}

export async function markOnboarding(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await authService.markOnboardingComplete(req.user!.id);
    res.json({ success: true, message: 'Onboarding complété.' });
  } catch (err) {
    next(err);
  }
}
