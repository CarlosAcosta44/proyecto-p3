import { Request, Response, NextFunction } from 'express';
import { sincronizarDatos } from '../servicios/sincronizacion';

export const sincronizar = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
  try {
    const { ultimaSync, cambiosLocales } = req.body;
    
    if (!ultimaSync || !cambiosLocales) {
      res.status(400).json({ error: 'Payload de sincronización inválido.' });
      return;
    }

    const resultado = await sincronizarDatos(new Date(ultimaSync), cambiosLocales);
    res.json(resultado);
  } catch (error) {
    next(error);
  }
};
