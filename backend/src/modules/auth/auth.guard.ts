// JWT Authentication Guard Middleware
import { Request, Response, NextFunction } from 'express';
import { AuthService } from './auth.service';

export interface AuthenticatedRequest extends Request {
  user?: {
    sub: string;
    email: string;
    displayName: string;
  };
}

export function authGuard(req: AuthenticatedRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ success: false, error: 'Unauthorized. Bearer token required.' });
    return;
  }

  const token = authHeader.substring(7);
  const payload = AuthService.verifyToken(token);

  if (!payload) {
    res.status(401).json({ success: false, error: 'Invalid or expired token.' });
    return;
  }

  req.user = payload;
  next();
}
