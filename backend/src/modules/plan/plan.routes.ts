import { Router } from 'express';
import { authenticate } from '../../middlewares/auth.middleware';
import { getMe } from './plan.controller';

const router = Router();
router.get('/me', authenticate, getMe);
export default router;
