import { Router } from 'express';
import { authenticate } from '../../middlewares/auth.middleware';
import * as ctrl from './site.controller';

const router = Router();
router.use(authenticate);

router.get('/:businessId', ctrl.getByBusiness);
router.post('/', ctrl.create);
router.put('/:siteId', ctrl.update);
router.delete('/:siteId', ctrl.remove);
router.post('/:siteId/publish', ctrl.publish);

export default router;
