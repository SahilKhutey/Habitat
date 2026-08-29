// Feature Flag Express Middleware Guard
import { Request, Response, NextFunction } from 'express';
import { FlagService } from './flag.service';
import { FeatureFlagKey } from './flag.types';

export function requireFeatureFlag(key: FeatureFlagKey) {
  return (req: Request, res: Response, next: NextFunction) => {
    const userId = (req as any).user?.id || (req.query?.userId as string) || (req.body?.userId as string);
    if (!FlagService.isEnabled(key, userId)) {
      return res.status(403).json({
        success: false,
        error: `Feature ${key} is not currently enabled for your account.`
      });
    }
    next();
  };
}
