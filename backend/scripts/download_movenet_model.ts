#!/usr/bin/env node
// Habitat MoveNet Model Pre-Cache Download Script (Track E)
// Downloads MoveNet Lightning weights from TF Hub for offline / container builds.
import * as fs from 'fs';
import * as path from 'path';
import * as https from 'https';

const MODEL_DEST_DIR = process.env.MOVENET_MODEL_DIR || path.resolve(__dirname, '..', 'models', 'movenet');
const TFHUB_MODEL_URL = 'https://tfhub.dev/google/tfjs-model/movenet/singlepose/lightning/4/default/1/model.json?tfjs-format=file';

async function downloadFile(urlStr: string, destPath: string): Promise<void> {
  return new Promise((resolve, reject) => {
    const file = fs.createWriteStream(destPath);
    const req = https.get(urlStr, { timeout: 10000 }, (res) => {
      if (res.statusCode && res.statusCode >= 300 && res.statusCode < 400 && res.headers.location) {
        // Follow redirect
        return downloadFile(res.headers.location, destPath).then(resolve).catch(reject);
      }
      if (res.statusCode !== 200) {
        file.close();
        fs.unlinkSync(destPath);
        return reject(new Error(`HTTP ${res.statusCode}: Failed to download ${urlStr}`));
      }
      res.pipe(file);
      file.on('finish', () => {
        file.close();
        resolve();
      });
    });

    req.on('timeout', () => {
      req.destroy();
      reject(new Error(`Network timeout connecting to ${urlStr}`));
    });

    req.on('error', (err) => {
      if (fs.existsSync(destPath)) {
        try { fs.unlinkSync(destPath); } catch {}
      }
      reject(err);
    });
  });
}

export async function preCacheMoveNetModel(): Promise<boolean> {
  console.log(`[MoveNet Cache] Target directory: ${MODEL_DEST_DIR}`);

  if (fs.existsSync(path.join(MODEL_DEST_DIR, 'model.json'))) {
    console.log('[MoveNet Cache] model.json already cached.');
    return true;
  }

  fs.mkdirSync(MODEL_DEST_DIR, { recursive: true });
  const targetFile = path.join(MODEL_DEST_DIR, 'model.json');

  try {
    console.log(`[MoveNet Cache] Fetching MoveNet Lightning from ${TFHUB_MODEL_URL}...`);
    await downloadFile(TFHUB_MODEL_URL, targetFile);
    console.log('[MoveNet Cache] Download complete.');
    return true;
  } catch (err: any) {
    console.warn(`[MoveNet Cache] Warning: Failed to pre-fetch model (${err.message}). Engine will use runtime fallback or mock.`);
    return false;
  }
}

if (require.main === module) {
  preCacheMoveNetModel().then((success) => {
    process.exit(success ? 0 : 0); // Non-fatal in airgapped environments
  });
}
