import { Router } from 'express';
import { body } from 'express-validator';
import { authenticate } from '../../middlewares/auth.middleware';
import * as ctrl from './auth.controller';

const router = Router();

// POST /v1/auth/request-otp
router.post(
  '/request-otp',
  [
    body('phone')
      .trim()
      .notEmpty().withMessage('Le numéro de téléphone est requis.')
      .matches(/^\+?[0-9]{8,15}$/).withMessage('Numéro de téléphone invalide.'),
  ],
  ctrl.requestOtp
);

// POST /v1/auth/verify-otp
router.post(
  '/verify-otp',
  [
    body('phone').trim().notEmpty().withMessage('Téléphone requis.'),
    body('code')
      .trim()
      .notEmpty().withMessage('Code OTP requis.')
      .isLength({ min: 4, max: 4 }).withMessage('Le code doit faire 4 chiffres.'),
    body('language').optional().isIn(['french', 'moore']),
  ],
  ctrl.verifyOtp
);

// POST /v1/auth/logout
router.post('/logout', authenticate, ctrl.logout);

// GET /v1/auth/me
router.get('/me', authenticate, ctrl.me);

// PATCH /v1/auth/onboarding
router.patch('/onboarding', authenticate, ctrl.markOnboarding);

export default router;
