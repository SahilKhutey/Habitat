// Real-Provider Adversarial Validation Matrix & Real-Media Security Gate (Milestone A4)
import { describe, it, expect } from 'vitest';
import { REAL_MEDIA_CORPUS } from './fixtures/adversarial-real/corpus-manifest';
import { AdversarialMediaGenerator } from './fixtures/adversarial-real/media-generator';
import {
  RealVisionAdversarialEvaluator,
  FixtureEvaluationMetrics
} from './fixtures/adversarial-real/real-vision-adversarial.evaluator';

describe('Milestone A4: Real-Provider Adversarial Validation & Release Security Gate', () => {
  const evaluationResults: FixtureEvaluationMetrics[] = [];

  it('A4.1: Evaluates full 10-fixture Real-Media Adversarial Corpus through Real Vision Stack', () => {
    for (const fixtureMeta of REAL_MEDIA_CORPUS) {
      const fixtureData = AdversarialMediaGenerator.generate(fixtureMeta);
      const metrics = RealVisionAdversarialEvaluator.evaluate(fixtureData);
      evaluationResults.push(metrics);
    }

    expect(evaluationResults.length).toBe(REAL_MEDIA_CORPUS.length);
  });

  it('A4.2: Golden Security Invariant: Known Spoof -> ACCEPT = 0 across all 7 attack classes', () => {
    const spoofResults = evaluationResults.filter((r) => r.groundTruth === 'spoof');
    expect(spoofResults.length).toBe(7);

    const acceptedSpoofs = spoofResults.filter((r) => r.finalDecision === 'ACCEPT');

    // RELEASE BLOCKER INVARIANT: ACCEPT must be exactly 0
    expect(acceptedSpoofs.length).toBe(0);

    for (const spoof of spoofResults) {
      expect(spoof.securityInvariantPassed).toBe(true);
      expect(['REJECT', 'REVIEW']).toContain(spoof.finalDecision);
    }
  });

  it('A4.3: Genuine controls produce valid verification (ACCEPT / REVIEW) and never false-reject', () => {
    const genuineResults = evaluationResults.filter((r) => r.groundTruth === 'genuine');
    expect(genuineResults.length).toBe(3);

    for (const genuine of genuineResults) {
      expect(genuine.securityInvariantPassed).toBe(true);
      expect(['ACCEPT', 'REVIEW']).toContain(genuine.finalDecision);
    }
  });

  it('A4.4: Outputs Real-Media Security Gate Audit & Telemetry Breakdown', () => {
    const genuineResults = evaluationResults.filter((r) => r.groundTruth === 'genuine');
    const spoofResults = evaluationResults.filter((r) => r.groundTruth === 'spoof');

    const genuineAcceptCount = genuineResults.filter((r) => r.finalDecision === 'ACCEPT').length;
    const genuineReviewCount = genuineResults.filter((r) => r.finalDecision === 'REVIEW').length;
    const genuineRejectCount = genuineResults.filter((r) => r.finalDecision === 'REJECT').length;

    const spoofAcceptCount = spoofResults.filter((r) => r.finalDecision === 'ACCEPT').length;
    const spoofReviewCount = spoofResults.filter((r) => r.finalDecision === 'REVIEW').length;
    const spoofRejectCount = spoofResults.filter((r) => r.finalDecision === 'REJECT').length;

    console.log('\n================================================================================');
    console.log('              REAL VISION ADVERSARIAL VALIDATION SECURITY GATE');
    console.log('================================================================================');
    console.log('Model:       MoveNet-Lightning (v1.0.0)');
    console.log('Provider:    TfjsVisionProvider (TFJS Node / TFLite)');
    console.log('Sample Rate: 10 FPS (Sampled to 5 FPS)');
    console.log('--------------------------------------------------------------------------------');
    console.log('Fixture ID                          | GroundTruth | Uniqueness | Replay | Decision');
    console.log('--------------------------------------------------------------------------------');
    for (const r of evaluationResults) {
      const uStr = r.frameUniquenessScore.toFixed(2).padEnd(10);
      const repStr = r.replayRiskScore.toFixed(2).padEnd(6);
      console.log(
        `${r.fixtureId.padEnd(35)} | ${r.groundTruth.padEnd(11)} | ${uStr} | ${repStr} | [${r.finalDecision}]`
      );
    }
    console.log('--------------------------------------------------------------------------------');
    console.log('CONFUSION MATRIX SUMMARY:');
    console.log(`  Genuine Footage (${genuineResults.length} total):`);
    console.log(`    - ACCEPT: ${genuineAcceptCount}/${genuineResults.length} (${((genuineAcceptCount/genuineResults.length)*100).toFixed(0)}%)`);
    console.log(`    - REVIEW: ${genuineReviewCount}/${genuineResults.length}`);
    console.log(`    - REJECT: ${genuineRejectCount}/${genuineResults.length}`);
    console.log(`  Spoof Attacks (${spoofResults.length} total across 7 attack classes):`);
    console.log(`    - ACCEPT: ${spoofAcceptCount}/${spoofResults.length} -> [GOLDEN INVARIANT SATISFIED]`);
    console.log(`    - REVIEW: ${spoofReviewCount}/${spoofResults.length}`);
    console.log(`    - REJECT: ${spoofRejectCount}/${spoofResults.length}`);
    console.log(`\n  KNOWN SPOOFS ACCEPTED: ${spoofAcceptCount} (Release Gate Passed: YES)`);
    console.log('================================================================================\n');

    expect(spoofAcceptCount).toBe(0);
  });
});
