// Error Handling Middleware
import { Request, Response, NextFunction } from 'express';
import { InvalidStateTransitionError } from '../../domain/stateMachine';
import { ZodError } from 'zod';

export function errorHandler(
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  console.error('[API Error]:', err);

  if (err instanceof ZodError) {
    res.status(400).json({
      success: false,
      error: 'Validation Error',
      details: err.errors
    });
    return;
  }

  if (err instanceof InvalidStateTransitionError) {
    res.status(422).json({
      success: false,
      error: 'Invalid State Transition',
      message: err.message
    });
    return;
  }

  res.status(500).json({
    success: false,
    error: 'Internal Server Error',
    message: err.message || 'An unexpected error occurred.'
  });
}
