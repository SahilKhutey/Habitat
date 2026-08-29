// Behavioral Insight Domain Entity
export interface InsightEntity {
  id: string;
  userId: string;
  type: string;
  title: string;
  content: string;
  confidence: number;
  category: 'STRENGTH' | 'FRICTION' | 'OPPORTUNITY';
  createdAt: Date;
}
