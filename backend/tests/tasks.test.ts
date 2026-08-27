// Integration Tests for Phase 04: Task Engine & Dynamic Catalog
import { describe, it, expect, beforeAll } from 'vitest';
import { DatabaseService } from '../src/db/connection';
import { seedDatabase } from '../src/db/seeds';
import { TasksService } from '../src/modules/tasks/tasks.controller';

describe('Phase 04: Task Engine & Dynamic Catalog', () => {
  let defaultUserId: string;

  beforeAll(() => {
    DatabaseService.resetDbForTesting();
    const seeded = seedDatabase();
    defaultUserId = seeded.defaultUserId;
  });

  it('aggregates task categories and returns counts', () => {
    const categories = TasksService.getCategories();
    expect(categories.length).toBeGreaterThan(0);
    const morningCat = categories.find((c) => c.category === 'morning');
    expect(morningCat).toBeDefined();
    expect(morningCat?.count).toBeGreaterThan(0);
    expect(morningCat?.label).toBe('Morning Order');
  });

  it('filters starter tasks by category', () => {
    const morningTasks = TasksService.getAll({ category: 'morning' });
    expect(morningTasks.length).toBeGreaterThan(0);
    morningTasks.forEach((task) => {
      expect(task.category.toLowerCase()).toBe('morning');
    });
  });

  it('filters starter tasks by difficulty', () => {
    const hardTasks = TasksService.getAll({ difficulty: 'HARD' });
    expect(hardTasks.length).toBeGreaterThan(0);
    hardTasks.forEach((task) => {
      expect(task.difficulty).toBe('HARD');
    });
  });

  it('creates and retrieves a custom user physical mission', () => {
    const customTask = TasksService.createCustomTask({
      userId: defaultUserId,
      title: '25 Kettlebell Swings',
      description: 'Explosive hip hinge movement to wake up posterior chain.',
      category: 'physical',
      difficulty: 'HARD',
      proofType: 'VIDEO',
      baseXp: 80,
      instructions: [
        'Prop phone up 6ft away',
        'Perform 25 unbroken kettlebell swings',
        'Submit 20s recording'
      ]
    });

    expect(customTask).toBeDefined();
    expect(customTask?.title).toBe('25 Kettlebell Swings');
    expect(customTask?.difficulty).toBe('HARD');
    expect(customTask?.baseXp).toBe(80);
    expect(customTask?.instructions.length).toBe(3);
    expect(customTask?.isStarter).toBe(false);

    // Verify it appears in user's query
    const userTasks = TasksService.getAll({ userId: defaultUserId });
    const found = userTasks.find((t) => t.id === customTask?.id);
    expect(found).toBeDefined();
  });

  it('prohibits deleting system starter tasks and allows deleting custom tasks', () => {
    const starterTask = TasksService.getAll()[0];
    
    expect(() => {
      TasksService.deleteCustomTask(starterTask.id, defaultUserId);
    }).toThrow('Cannot delete system starter tasks.');

    // Create and delete custom task
    const custom = TasksService.createCustomTask({
      userId: defaultUserId,
      title: 'Temporary Task',
      description: 'Short term',
      category: 'mind',
      proofType: 'PHOTO',
      instructions: ['Read one page']
    });

    const deleted = TasksService.deleteCustomTask(custom!.id, defaultUserId);
    expect(deleted).toBe(true);

    const check = TasksService.getById(custom!.id);
    expect(check).toBeNull();
  });
});
