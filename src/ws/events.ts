// Real-Time WebSocket Event Protocols
import { Mission, ProofAsset } from '../domain/types';

export type WsEventType =
  | 'CLIENT_REGISTER'
  | 'MISSION_TRIGGERED'
  | 'MISSION_ESCALATED'
  | 'MISSION_IN_PROGRESS'
  | 'PROOF_SUBMITTED'
  | 'PROOF_VERIFIED'
  | 'MISSION_COMPLETED'
  | 'MISSION_FAILED'
  | 'STATE_SYNC';

export interface WsMessage<T = any> {
  type: WsEventType;
  payload: T;
  timestamp: string;
}

export interface MissionTriggerPayload {
  mission: Mission;
  taskTitle: string;
  taskCategory: string;
  proofType: string;
  instructions: string[];
  sirenVolume: number;
  urgencyLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'MAX';
  attemptIndex: number;
}

export interface MissionEscalatePayload {
  missionId: string;
  attemptIndex: number;
  sirenVolume: number;
  urgencyLevel: 'LOW' | 'MEDIUM' | 'HIGH' | 'MAX';
  message: string;
}

export interface MissionCompletePayload {
  missionId: string;
  resistanceSeconds: number;
  resistanceMinutes: number;
  xpAwarded: number;
  currentStreak: number;
  disciplineScore: number;
  firstAlarmBonus: boolean;
}
