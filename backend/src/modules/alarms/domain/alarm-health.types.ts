// Alarm Health & Reliability Diagnostic Domain Types
export type DiagnosticStatus = 'CONFIRMED' | 'ACTION_RECOMMENDED' | 'CANNOT_VERIFY';

export type OEMVendor = 'Samsung' | 'Xiaomi' | 'OnePlus' | 'Oppo' | 'Vivo' | 'Realme' | 'Stock/Pixel' | 'Other';

export interface OEMGuidance {
  oemName: OEMVendor;
  batterySaverRisk: 'HIGH' | 'MEDIUM' | 'LOW';
  specificSteps: string[];
  settingsIntentAction?: string;
}

export interface DeviceDiagnosticInput {
  platform: 'android' | 'ios' | 'web';
  osVersion: string;
  manufacturer?: string;
  canScheduleExactAlarms?: boolean;
  notificationsEnabled?: boolean;
  isIgnoringBatteryOptimizations?: boolean;
  backgroundExecutionRestricted?: boolean;
}

export interface AlarmHealth {
  canScheduleExactAlarms: DiagnosticStatus;
  notificationsEnabled: DiagnosticStatus;
  batteryOptimizationStatus: DiagnosticStatus;
  backgroundExecution: DiagnosticStatus;
  platform: 'android' | 'ios' | 'web';
  osVersion: string;
  manufacturer: string;
  overallReliability: 'EXCELLENT' | 'GOOD' | 'NEEDS_ATTENTION' | 'CRITICAL';
  oemGuidance?: OEMGuidance;
  lastTestAlarm?: {
    scheduledAt: string;
    deliveredAt?: string;
    confirmed: boolean;
  };
}

export interface TestAlarmSession {
  testId: string;
  scheduledAt: string;
  fireAt: string;
  status: 'SCHEDULED' | 'DELIVERED' | 'CONFIRMED' | 'FAILED';
  expiresAt: string;
}
