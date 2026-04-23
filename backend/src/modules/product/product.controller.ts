import { Request, Response, NextFunction } from 'express';
import path from 'path';
import * as svc from './product.service';

function fmt(p: svc.ProductRow) {
  return {
    id: p.id,
    siteId: p.site_id,
    name: p.name,
    description: p.description,
    price: Number(p.price),
    imagePath: p.image_url,
    category: p.category,
  };
}

export async function getAll(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const products = await svc.getAll(req.params['siteId']!);
    res.json({ success: true, products: products.map(fmt) });
  } catch (err) { next(err); }
}

export async function create(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { name, description, price, category } = req.body;
    const product = await svc.create({
      site_id: req.params['siteId']!,
      name, description: description ?? '', price: Number(price),
      image_url: null, category: category ?? '',
    });
    res.status(201).json({ success: true, product: fmt(product) });
  } catch (err) { next(err); }
}

export async function update(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    const { name, description, price, category } = req.body;
    const product = await svc.update(req.params['productId']!, {
      name, description, price: price !== undefined ? Number(price) : undefined, category,
    });
    if (!product) { res.status(404).json({ success: false, message: 'Produit introuvable.' }); return; }
    res.json({ success: true, product: fmt(product) });
  } catch (err) { next(err); }
}

export async function remove(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    await svc.remove(req.params['productId']!);
    res.json({ success: true });
  } catch (err) { next(err); }
}

export async function uploadImage(req: Request, res: Response, next: NextFunction): Promise<void> {
  try {
    if (!req.file) { res.status(400).json({ success: false, message: 'Aucun fichier fourni.' }); return; }
    const imageUrl = `/uploads/${path.basename(req.file.path)}`;
    await svc.updateImage(req.params['productId']!, imageUrl);
    res.json({ success: true, imageUrl });
  } catch (err) { next(err); }
}
