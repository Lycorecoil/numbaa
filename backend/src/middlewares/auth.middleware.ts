import { Request, Response, NextFunction } from 'express';
import jwt, { TokenExpiredError, JsonWebTokenError } from 'jsonwebtoken';
import { env } from '../config/env';
import { redis } from '../config/redis';

interface JwtPayload {
  id: string;
  phone: string;
  iat?: number;
  exp?: number;
}

export function authenticate(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({
      success: false,
      code: 'MISSING_TOKEN',
      message: 'Authorization header missing or malformed. Expected: Bearer <token>',
    });
    return;
  }

  const token = authHeader.slice(7);

  try {
    const decoded = jwt.verify(token, env.JWT_SECRET) as JwtPayload;

    // Vérifier que la session est encore active dans Redis
    redis.exists(`session:${decoded.id}`).then((exists) => {
      if (!exists) {
        res.status(401).json({
          success: false,
          code: 'SESSION_EXPIRED',
          message: 'Session expirée. Veuillez vous reconnecter.',
        });
        return;
      }
      req.user = { id: decoded.id, phone: decoded.phone };
      next();
    }).catch(next);
  } catch (err) {
    if (err instanceof TokenExpiredError) {
      res.status(401).json({ success: false, code: 'TOKEN_EXPIRED', message: 'Token expiré.' });
      return;
    }
    if (err instanceof JsonWebTokenError) {
      res.status(401).json({ success: false, code: 'INVALID_TOKEN', message: 'Token invalide.' });
      return;
    }
    next(err);
  }
}

export function generateToken(payload: { id: string; phone: string }): string {
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: env.JWT_EXPIRY as jwt.SignOptions['expiresIn'],
  });
}
