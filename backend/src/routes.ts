import { Router } from 'express';
import authRoutes from './modules/auth/auth.routes';
import businessRoutes from './modules/business/business.routes';
import siteRoutes from './modules/site/site.routes';
import productRoutes from './modules/product/product.routes';
import templateRoutes from './modules/template/template.routes';
import planRoutes from './modules/plan/plan.routes';

const router = Router();

router.use('/auth', authRoutes);
router.use('/business', businessRoutes);
router.use('/sites', siteRoutes);
router.use('/sites/:siteId/products', productRoutes);
router.use('/templates', templateRoutes);
router.use('/plans', planRoutes);

export default router;
