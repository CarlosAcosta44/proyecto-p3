import { Router } from 'express';
import { sincronizar } from '../controladores/sincronizacion';

const router = Router();

router.post('/sync', sincronizar);

export default router;
