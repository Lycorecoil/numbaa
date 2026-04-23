import { Router } from 'express';
import { authenticate } from '../../middlewares/auth.middleware';
import { upload } from '../../middlewares/upload.middleware';
import * as ctrl from './product.controller';

const router = Router({ mergeParams: true });
router.use(authenticate);

router.get('/', ctrl.getAll);
router.post('/', ctrl.create);
router.put('/:productId', ctrl.update);
router.delete('/:productId', ctrl.remove);
router.post('/:productId/image', upload.single('image'), ctrl.uploadImage);

export default router;
