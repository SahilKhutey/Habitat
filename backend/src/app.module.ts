// NestJS/Express Modular Application Routing Root with Scheduling & Alarms
import { Router } from 'express';
import { authController } from './modules/auth/auth.controller';
import { usersController } from './modules/users/users.controller';
import { tasksController } from './modules/tasks/tasks.controller';
import { alarmsController } from './modules/alarms/alarms.controller';
import { schedulingController } from './modules/scheduling/scheduling.controller';
import { missionsController } from './modules/missions/missions.controller';
import { proofsController } from './modules/proofs/proofs.controller';
import { gamificationController } from './modules/gamification/gamification.controller';
import { syncController } from './modules/sync/sync.controller';
import { routinesController } from './modules/routines/routines.controller';
import { accountabilityController } from './modules/accountability/accountability.controller';
import { healthController } from './modules/health/health.controller';
import { squadsController } from './modules/squads/squads.controller';
import { coachController } from './modules/coach/coach.controller';
import { challengesController } from './modules/challenges/challenges.controller';
import { anchorsController } from './modules/anchors/anchors.controller';
import { audioController } from './modules/audio/audio.controller';
import { lockdownController } from './modules/lockdown/lockdown.controller';
import { meshController } from './modules/mesh/mesh.controller';

export const appRouter = Router();

// Mount all modules under /api/v1/
appRouter.use('/auth', authController);
appRouter.use('/users', usersController);
appRouter.use('/tasks', tasksController);
appRouter.use('/alarms', alarmsController);
appRouter.use('/alarm-schedules', schedulingController);
appRouter.use('/missions', missionsController);
appRouter.use('/missions', proofsController);
appRouter.use('/proofs', proofsController);
appRouter.use('/gamification', gamificationController);
appRouter.use('/sync', syncController);
appRouter.use('/routines', routinesController);
appRouter.use('/accountability', accountabilityController);
appRouter.use('/health', healthController);
appRouter.use('/squads', squadsController);
appRouter.use('/coach', coachController);
appRouter.use('/challenges', challengesController);
appRouter.use('/anchors', anchorsController);
appRouter.use('/audio', audioController);
appRouter.use('/lockdown', lockdownController);
appRouter.use('/mesh', meshController);
