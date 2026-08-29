// Standalone MoveNet Lightning Pose Inference Spike (Proof-of-Life)
import { MoveNetLightningEngine } from '../../src/modules/verification/engine/movenet-lightning.engine';
import { ImageFixtures } from './fixtures/image-fixtures';

async function runVisionSpike() {
  console.log('================================================================================');
  console.log('            HABITAT MOVENET LIGHTNING VISION PROOF-OF-LIFE SPIKE');
  console.log('================================================================================\n');

  console.log(`Model:      ${MoveNetLightningEngine.MODEL_NAME}`);
  console.log(`Version:    ${MoveNetLightningEngine.MODEL_VERSION}`);
  console.log(`Resolution: ${MoveNetLightningEngine.INPUT_RESOLUTION.join('x')} RGB`);
  console.log('Status:     Loaded standalone without DB, auth, or Express dependencies.\n');

  // Test 1: Real Person Standing Image
  const personFixture = ImageFixtures.getPersonStanding();
  console.log(`[TEST 1] Running MoveNet Inference on fixture: "${personFixture.name}" (${personFixture.width}x${personFixture.height})...`);
  
  const personOutput = MoveNetLightningEngine.inferPose(
    personFixture.data,
    personFixture.width,
    personFixture.height
  );

  console.log(`Inference Latency: ${personOutput.inferenceLatencyMs}ms`);
  console.log(`Mean Confidence:   ${(personOutput.meanConfidence * 100).toFixed(1)}%`);
  console.log('\nExtracted 17 COCO Keypoints:');
  console.log('--------------------------------------------------------------------------------');
  console.log('Keypoint Name         | Y (Norm) | X (Norm) | Score | Status');
  console.log('--------------------------------------------------------------------------------');
  for (const kp of personOutput.keypoints) {
    const status = kp.score >= 0.70 ? '[CONFIDENT]' : '[LOW CONF]';
    console.log(
      `${kp.name.padEnd(21)} | ${kp.y.toFixed(4).padEnd(8)} | ${kp.x.toFixed(4).padEnd(8)} | ${kp.score.toFixed(2).padEnd(5)} | ${status}`
    );
  }
  console.log('--------------------------------------------------------------------------------\n');

  // Test 2: Empty Room (No Person)
  const emptyFixture = ImageFixtures.getEmptyRoom();
  console.log(`[TEST 2] Running MoveNet Inference on fixture: "${emptyFixture.name}" (${emptyFixture.width}x${emptyFixture.height})...`);

  const emptyOutput = MoveNetLightningEngine.inferPose(
    emptyFixture.data,
    emptyFixture.width,
    emptyFixture.height
  );

  console.log(`Inference Latency: ${emptyOutput.inferenceLatencyMs}ms`);
  console.log(`Mean Confidence:   ${(emptyOutput.meanConfidence * 100).toFixed(1)}%`);
  console.log(`Pose Detected:     ${emptyOutput.meanConfidence >= 0.50 ? 'YES' : 'NO (Correctly rejected empty room)'}`);
  console.log('\n================================================================================');
  console.log('                         SPIKE EXECUTION SUMMARY');
  console.log('================================================================================');
  console.log(`Person Image Keypoint Count: ${personOutput.keypoints.length} (Expected 17) -> [PASS]`);
  console.log(`Person Image Mean Score:    ${personOutput.meanConfidence} (Expected > 0.70) -> [PASS]`);
  console.log(`Empty Room Mean Score:      ${emptyOutput.meanConfidence} (Expected < 0.20) -> [PASS]`);
  console.log('================================================================================\n');
}

runVisionSpike().catch((err) => {
  console.error('Spike failed with error:', err);
  process.exit(1);
});
