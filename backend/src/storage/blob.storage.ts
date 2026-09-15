import path from 'path';
import { put } from '@vercel/blob';

export async function uploadImageToBlob(folder: string, id: string, file: Express.Multer.File): Promise<string> {
  const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
  const blob = await put(`${folder}/${id}${ext}`, file.buffer, {
    access: 'public',
    contentType: file.mimetype,
  });
  return blob.url;
}
