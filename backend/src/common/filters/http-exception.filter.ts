// Standardized Global HTTP Exception & Error Handler
import { Request, Response, NextFunction } from 'express';

export class AppError extends Error {
  public statusCode: number;
  public errorCode: string;
  public details?: any;

  constructor(message: string, statusCode: number = 400, errorCode: string = 'BAD_REQUEST', details?: any) {
    super(message);
    this.statusCode = statusCode;
    this.errorCode = errorCode;
    this.details = details;
  }
}

export function globalErrorHandler(err: any, req: Request, res: Response, next: NextFunction) {
  const statusCode = err.statusCode || 500;
  const errorCode = err.errorCode || 'INTERNAL_SERVER_ERROR';

  res.status(statusCode).json({
    success: false,
    error: {
      code: errorCode,
      message: err.message || 'An unexpected error occurred',
      details: err.details || null,
      timestamp: new Date().toISOString(),
      path: req.originalUrl
    }
  });
}
