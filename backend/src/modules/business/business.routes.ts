import { Router } from 'express';
import { authenticate } from '../../middlewares/auth.middleware';
import { upload } from '../../middlewares/upload.middleware';
import * as ctrl from './business.controller';

const router = Router();
router.use(authenticate);

router.get('/', ctrl.get);
router.post('/', ctrl.create);
router.put('/', ctrl.update);
router.post('/logo', upload.single('logo'), ctrl.uploadLogo);

export default router;
