// Authentication Guard Middleware
import { Request, Response, NextFunction } from 'express';
import { AuthSecurity } from '../../modules/auth/auth.security';

export interface AuthenticatedRequest extends Request {
  user?: {
    userId: string;
    email: string;
  };
}

export function authGuard(req: AuthenticatedRequest, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      success: false,
      error: {
        code: 'UNAUTHORIZED',
        message: 'Authentication token required in Authorization header.'
      }
    });
    return;
  }

  const token = authHeader.substring(7).trim();
  try {
    const payload = AuthSecurity.verifyJwt(token);
    if (payload.type !== 'access') {
      res.status(401).json({
        success: false,
        error: { code: 'INVALID_TOKEN_TYPE', message: 'Expected access token.' }
      });
      return;
    }

    req.user = {
      userId: payload.userId,
      email: payload.email
    };

    next();
  } catch (err: any) {
    res.status(401).json({
      success: false,
      error: {
        code: 'INVALID_TOKEN',
        message: err.message || 'Token verification failed.'
      }
    });
  }
}
