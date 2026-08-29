// Generic Repository Interface
export interface IRepository<T, ID = string> {
  findById(id: ID): Promise<T | null> | (T | null);
  create(entity: Partial<T>): Promise<T> | T;
  update(id: ID, patch: Partial<T>): Promise<void> | void;
  delete(id: ID): Promise<void> | void;
}
