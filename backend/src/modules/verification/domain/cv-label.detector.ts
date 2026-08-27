// Task-Specific Computer Vision & Object Recognition Evaluator

export class CvLabelDetector {
  /**
   * Matches detected labels against task required target objects
   */
  public static evaluateLabels(
    detectedLabels: string[],
    requiredLabels: string[],
    minConfidenceThreshold: number = 0.70
  ): {
    matched: boolean;
    confidence: number;
    matchedObjects: string[];
    missingObjects: string[];
  } {
    if (!requiredLabels || requiredLabels.length === 0) {
      return {
        matched: true,
        confidence: 0.95,
        matchedObjects: detectedLabels,
        missingObjects: []
      };
    }

    const normalizedDetected = detectedLabels.map((l) => l.toLowerCase().trim());
    const matchedObjects: string[] = [];
    const missingObjects: string[] = [];

    for (const req of requiredLabels) {
      const normalizedReq = req.toLowerCase().trim();
      const isFound = normalizedDetected.some(
        (det) => det.includes(normalizedReq) || normalizedReq.includes(det)
      );
      if (isFound) {
        matchedObjects.push(req);
      } else {
        missingObjects.push(req);
      }
    }

    const matched = matchedObjects.length > 0;
    const matchRatio = matchedObjects.length / requiredLabels.length;
    const confidence = matched ? Math.min(1.0, 0.75 + matchRatio * 0.24) : 0.20;

    return {
      matched: matched && confidence >= minConfidenceThreshold,
      confidence,
      matchedObjects,
      missingObjects
    };
  }
}
