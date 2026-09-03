// Production Task Service orchestrating task lifecycle and persistence
import {
  ITaskRepository,
  TaskEntity,
  CreateTaskInput
} from '../../../repositories/task.repository';
import { DatabaseFactory } from '../../../db/database.factory';

export class TaskService {
  constructor(private readonly repository?: ITaskRepository) {}

  private getRepo(): ITaskRepository {
    if (this.repository) return this.repository;
    return DatabaseFactory.getTaskRepository();
  }

  public async createTask(params: CreateTaskInput): Promise<TaskEntity> {
    if (!params.title || params.title.trim() === '') {
      throw new Error('INVALID_TASK: Task title cannot be empty.');
    }
    if (!params.slug || params.slug.trim() === '') {
      params.slug = params.title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '');
    }
    return this.getRepo().create(params);
  }

  public async getTask(id: string): Promise<TaskEntity | null> {
    return this.getRepo().findById(id);
  }

  public async getTaskBySlug(slug: string): Promise<TaskEntity | null> {
    return this.getRepo().findBySlug(slug);
  }

  public async getUserTasks(userId: string): Promise<TaskEntity[]> {
    return this.getRepo().getUserTasks(userId);
  }

  public async updateTask(id: string, patch: Partial<TaskEntity>): Promise<TaskEntity | null> {
    const existing = await this.getRepo().findById(id);
    if (!existing) {
      throw new Error(`TASK_NOT_FOUND: Task with id ${id} not found.`);
    }
    return this.getRepo().update(id, patch);
  }

  public async deleteTask(id: string): Promise<boolean> {
    const existing = await this.getRepo().findById(id);
    if (!existing) {
      throw new Error(`TASK_NOT_FOUND: Task with id ${id} not found.`);
    }
    return this.getRepo().delete(id);
  }

  public async findActive(userId: string): Promise<TaskEntity[]> {
    return this.getRepo().findActive(userId);
  }
}
