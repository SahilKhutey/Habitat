// Authoritative Server-Side XP Calculator & Difficulty Multipliers

export class XpCalculator {
  public static readonly multipliers: Record<number, number> = {
    1: 1.0,  // Easy
    2: 1.25, // Moderate
    3: 1.5,  // Challenging
    4: 2.0,  // Hard
    5: 2.5   // Extreme
  };

  public static calculateXp(baseXp: number, difficulty: number): number {
    const clampedDiff = Math.max(1, Math.min(5, Math.round(difficulty)));
    const mult = this.multipliers[clampedDiff] ?? 1.0;
    return Math.round(baseXp * mult);
  }
}
