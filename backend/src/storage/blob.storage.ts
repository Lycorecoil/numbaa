import path from 'path';
import { put } from '@vercel/blob';

// The "numbaa-blob" store is connected to this project with the custom
// env var prefix "umbaa_media_" (visible via `vercel env ls`) instead of the
// default unprefixed BLOB_READ_WRITE_TOKEN, so the SDK can't auto-detect it —
// it must be passed explicitly.
const BLOB_TOKEN = process.env['umbaa_media_READ_WRITE_TOKEN'];

export async function uploadImageToBlob(folder: string, id: string, file: Express.Multer.File): Promise<string> {
  const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
  const blob = await put(`${folder}/${id}${ext}`, file.buffer, {
    access: 'public',
    contentType: file.mimetype,
    token: BLOB_TOKEN,
  });
  return blob.url;
}
