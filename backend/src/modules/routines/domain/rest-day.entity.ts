// Rest Day Domain Entity
export interface RestDayEntity {
  id: string;
  userId: string;
  date: string;
  reason?: string;
  createdAt: Date;
}
