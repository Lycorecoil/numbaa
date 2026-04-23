import { query } from '../../config/database';

export interface ProductRow {
  id: string;
  site_id: string;
  name: string;
  description: string;
  price: number;
  image_url: string | null;
  category: string;
}

export async function getAll(siteId: string): Promise<ProductRow[]> {
  const r = await query<ProductRow>('SELECT * FROM products WHERE site_id = $1', [siteId]);
  return r.rows;
}

export async function create(data: Omit<ProductRow, 'id'>): Promise<ProductRow> {
  const r = await query<ProductRow>(
    `INSERT INTO products (site_id, name, description, price, image_url, category)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING *`,
    [data.site_id, data.name, data.description, data.price, data.image_url ?? null, data.category]
  );
  return r.rows[0];
}

export async function update(productId: string, data: Partial<ProductRow>): Promise<ProductRow | null> {
  const r = await query<ProductRow>(
    `UPDATE products SET
       name = COALESCE($2, name),
       description = COALESCE($3, description),
       price = COALESCE($4, price),
       image_url = COALESCE($5, image_url),
       category = COALESCE($6, category)
     WHERE id = $1 RETURNING *`,
    [productId, data.name, data.description, data.price, data.image_url, data.category]
  );
  return r.rows[0] ?? null;
}

export async function remove(productId: string): Promise<void> {
  await query('DELETE FROM products WHERE id = $1', [productId]);
}

export async function updateImage(productId: string, imageUrl: string): Promise<void> {
  await query('UPDATE products SET image_url = $2 WHERE id = $1', [productId, imageUrl]);
}
