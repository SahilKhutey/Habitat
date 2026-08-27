// Anti-Cheat & Sensor Authenticity Validator

export class AntiCheatValidator {
  /**
   * Evaluates hardware capture timestamp freshness (must be <= 180s old)
   */
  public static validateFreshness(capturedAt: string, maxAgeSeconds: number = 180): { valid: boolean; ageSeconds: number } {
    const captureTime = new Date(capturedAt).getTime();
    if (isNaN(captureTime)) {
      return { valid: false, ageSeconds: 9999 };
    }
    const ageSeconds = Math.max(0, Math.floor((Date.now() - captureTime) / 1000));
    return {
      valid: ageSeconds <= maxAgeSeconds,
      ageSeconds
    };
  }

  /**
   * Evaluates ambient lux illumination (rejects pitch-black captures)
   */
  public static validateIllumination(ambientLux?: number, minLux: number = 25): { valid: boolean; lux: number } {
    const lux = ambientLux ?? 50; // default acceptable if not provided
    return {
      valid: lux >= minLux,
      lux
    };
  }

  /**
   * Evaluates optical entropy (rejects covered camera lens / blank solid colors)
   */
  public static validateOpticalEntropy(entropyScore?: number, minEntropy: number = 0.15): { valid: boolean; score: number } {
    const score = entropyScore ?? 0.85; // default acceptable if not provided
    return {
      valid: score >= minEntropy,
      score
    };
  }

  /**
   * Evaluates live sensor stream flag (blocks gallery injection)
   */
  public static validateLiveStream(isGalleryUpload?: boolean): boolean {
    return isGalleryUpload !== true;
  }
}
