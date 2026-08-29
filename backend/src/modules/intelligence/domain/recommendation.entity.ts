// Recommendation Domain Entity for Intelligence Layer
export interface IntelligenceRecommendationEntity {
  id: string;
  userId: string;
  type: string;
  title: string;
  message: string;
  confidence: number;
  evidence?: string[];
  status: 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'EXPIRED';
  expiresAt?: Date;
  createdAt: Date;
}
