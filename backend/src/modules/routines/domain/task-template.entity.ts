// Task Template Domain Entity
export interface TaskTemplateEntity {
  id: string;
  userId?: string | null;
  name: string;
  description?: string;
  category: string;
  difficulty: number;
  proofType: string;
  baseXp: number;
  durationSeconds?: number;
  isActive: boolean;
  createdAt: Date;
}
