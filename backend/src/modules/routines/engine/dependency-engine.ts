// Task Dependency Engine & Cycle Detection
import { TaskDependencyEntity } from '../domain/schedule-rule.entity';

export class DependencyEngine {
  /**
   * Validates a set of dependencies for circular cycles (A -> B -> C -> A)
   * Throws Error with DEPENDENCY_CYCLE if a cycle is found.
   */
  public static validateNoCycles(dependencies: TaskDependencyEntity[]): boolean {
    const adjList = new Map<string, string[]>();

    for (const dep of dependencies) {
      if (!adjList.has(dep.prerequisiteId)) {
        adjList.set(dep.prerequisiteId, []);
      }
      adjList.get(dep.prerequisiteId)!.push(dep.dependentId);
    }

    const visited = new Set<string>();
    const recStack = new Set<string>();

    const hasCycle = (node: string): boolean => {
      visited.add(node);
      recStack.add(node);

      const neighbors = adjList.get(node) || [];
      for (const neighbor of neighbors) {
        if (!visited.has(neighbor)) {
          if (hasCycle(neighbor)) return true;
        } else if (recStack.has(neighbor)) {
          return true;
        }
      }

      recStack.delete(node);
      return false;
    };

    for (const node of adjList.keys()) {
      if (!visited.has(node)) {
        if (hasCycle(node)) {
          throw new Error('DEPENDENCY_CYCLE: Circular dependency detected in routine task flow');
        }
      }
    }

    return true;
  }

  /**
   * Checks if a dependent task is unlocked given completed task IDs
   */
  public static isTaskUnlocked(params: {
    taskId: string;
    completedTaskIds: Set<string>;
    dependencies: TaskDependencyEntity[];
  }): { isUnlocked: boolean; pendingPrerequisites: string[]; isHardBlock: boolean } {
    const relevantDeps = params.dependencies.filter((d) => d.dependentId === params.taskId);
    const pendingPrerequisites: string[] = [];
    let isHardBlock = false;

    for (const dep of relevantDeps) {
      if (!params.completedTaskIds.has(dep.prerequisiteId)) {
        pendingPrerequisites.push(dep.prerequisiteId);
        if (dep.dependencyType === 'HARD') {
          isHardBlock = true;
        }
      }
    }

    return {
      isUnlocked: pendingPrerequisites.length === 0,
      pendingPrerequisites,
      isHardBlock
    };
  }
}
