// Storage HTTP Controller for Local Uploads & Downloads
import { Router, Request, Response } from 'express';
import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { StorageFactory } from './storage.factory';
import { LocalStorageProvider } from './infrastructure/local-storage.provider';

export const storageController = Router();

const upload = multer({
  limits: { fileSize: 100 * 1024 * 1024 } // 100MB max
});

// PUT /api/v1/storage/upload - Direct binary upload for LocalStorageProvider
storageController.put('/upload', (req: Request, res: Response) => {
  try {
    const key = req.query.key as string;
    if (!key) {
      res.status(400).json({ success: false, error: 'Storage object key is required' });
      return;
    }

    const provider = StorageFactory.getProvider();
    if (provider.providerType !== 'LOCAL') {
      res.status(400).json({ success: false, error: 'Direct local upload is only active on LOCAL storage provider' });
      return;
    }

    const localProvider = provider as LocalStorageProvider;
    const filePath = localProvider.getFilePath(key);
    const dir = path.dirname(filePath);

    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }

    const writeStream = fs.createWriteStream(filePath);
    req.pipe(writeStream);

    writeStream.on('finish', () => {
      res.status(200).json({ success: true, message: 'Upload completed' });
    });

    writeStream.on('error', (err) => {
      res.status(500).json({ success: false, error: err.message });
    });
  } catch (e: any) {
    res.status(500).json({ success: false, error: e.message });
  }
});

// GET /api/v1/storage/file - Stream file content
storageController.get('/file', (req: Request, res: Response) => {
  try {
    const key = req.query.key as string;
    if (!key) {
      res.status(400).json({ success: false, error: 'Storage object key is required' });
      return;
    }

    const provider = StorageFactory.getProvider();
    if (provider.providerType !== 'LOCAL') {
      res.status(400).json({ success: false, error: 'File streaming route only available on LOCAL storage provider' });
      return;
    }

    const localProvider = provider as LocalStorageProvider;
    const filePath = localProvider.getFilePath(key);

    if (!fs.existsSync(filePath)) {
      res.status(404).json({ success: false, error: 'Object not found' });
      return;
    }

    res.sendFile(filePath);
  } catch (e: any) {
    res.status(500).json({ success: false, error: e.message });
  }
});
