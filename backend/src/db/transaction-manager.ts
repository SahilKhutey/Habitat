// SQLite & Database Transaction Manager
import { DatabaseService } from './connection';

export class TransactionManager {
  /**
   * Executes a synchronous callback atomically within a SQLite BEGIN / COMMIT transaction block.
   * If any error is thrown, the transaction is immediately ROLLED BACK.
   */
  public static run<T>(operation: () => T): T {
    const db = DatabaseService.getDb();
    db.exec('BEGIN IMMEDIATE;');
    try {
      const result = operation();
      db.exec('COMMIT;');
      return result;
    } catch (error) {
      try {
        db.exec('ROLLBACK;');
      } catch (rollbackErr) {
        // Rollback error secondary
      }
      throw error;
    }
  }

  /**
   * Executes an async operation with transaction boundaries
   */
  public static async runAsync<T>(operation: () => Promise<T>): Promise<T> {
    const db = DatabaseService.getDb();
    db.exec('BEGIN IMMEDIATE;');
    try {
      const result = await operation();
      db.exec('COMMIT;');
      return result;
    } catch (error) {
      try {
        db.exec('ROLLBACK;');
      } catch (rollbackErr) {
        // Rollback error secondary
      }
      throw error;
    }
  }
}
