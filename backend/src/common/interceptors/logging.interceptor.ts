// Structured Request Logging & Performance Interceptor
import { Request, Response, NextFunction } from 'express';
import { v4 as uuidv4 } from 'uuid';

export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const correlationId = (req.headers['x-correlation-id'] as string) || uuidv4();
  const startTime = Date.now();

  res.setHeader('x-correlation-id', correlationId);

  res.on('finish', () => {
    const duration = Date.now() - startTime;
    if (process.env.NODE_ENV !== 'test') {
      console.log(`[HTTP] ${req.method} ${req.originalUrl} -> ${res.statusCode} (${duration}ms) [CID: ${correlationId}]`);
    }
  });

  next();
}
