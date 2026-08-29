// Wellness Metric Domain Entity
export interface WellnessMetricEntity {
  id: string;
  userId: string;
  type: string;
  value: number;
  unit: string;
  timestamp: Date;
  source: string;
  externalId?: string;
  metadata?: Record<string, any>;
  createdAt: Date;
}
