import multer from 'multer';
import type { Request, Response, NextFunction } from 'express';

const storage = multer.memoryStorage();

const allowedMimeTypes = [
  'image/jpeg',
  'image/png',
  'image/webp',
  'image/gif',
  'image/jpg',
];

const upload = multer({
  storage,
  limits: {
    fileSize: 5 * 1024 * 1024, // 5MB
  },
  fileFilter: (_req, file, cb) => {
    if (allowedMimeTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Chỉ chấp nhận file hình ảnh (JPEG, PNG, WEBP, GIF)'));
    }
  },
});

export function uploadMultipleImagesMiddleware(fieldName = 'images', maxFiles = 5) {
  return (req: Request, res: Response, next: NextFunction) => {
    const uploadHandler = upload.array(fieldName, maxFiles);

    uploadHandler(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof multer.MulterError) {
          if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ error: 'Kích thước file ảnh vượt quá giới hạn tối đa 5MB' });
          }
          if (err.code === 'LIMIT_UNEXPECTED_FILE') {
            return res.status(400).json({ error: `Chỉ được đính kèm tối đa ${maxFiles} ảnh` });
          }
          return res.status(400).json({ error: `Lỗi upload file: ${err.message}` });
        }
        if (err instanceof Error) {
          return res.status(400).json({ error: err.message });
        }
        return res.status(400).json({ error: 'Lỗi tải file không xác định' });
      }

      return next();
    });
  };
}

export function uploadAvatarMiddleware(fieldName = 'avatar') {
  return (req: Request, res: Response, next: NextFunction) => {
    const uploadHandler = upload.fields([
      { name: fieldName, maxCount: 1 },
      { name: 'file', maxCount: 1 },
      { name: 'image', maxCount: 1 },
    ]);

    uploadHandler(req, res, (err: unknown) => {
      if (err) {
        if (err instanceof multer.MulterError) {
          if (err.code === 'LIMIT_FILE_SIZE') {
            return res.status(400).json({ error: 'Kích thước file ảnh vượt quá giới hạn tối đa 5MB' });
          }
          return res.status(400).json({ error: `Lỗi upload file: ${err.message}` });
        }
        if (err instanceof Error) {
          return res.status(400).json({ error: err.message });
        }
        return res.status(400).json({ error: 'Lỗi tải file không xác định' });
      }

      const files = req.files as Record<string, Express.Multer.File[]> | undefined;
      if (files) {
        const found = files[fieldName]?.[0] || files['file']?.[0] || files['image']?.[0];
        if (found) {
          req.file = found;
        }
      }

      return next();
    });
  };
}

