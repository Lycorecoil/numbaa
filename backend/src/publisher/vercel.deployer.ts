import https from 'https';
import { env } from '../config/env';

function slugify(name: string): string {
  return name
    .toLowerCase()
    .normalize('NFD').replace(/[̀-ͯ]/g, '')
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 40);
}

export async function deployToVercel(businessId: string, businessName: string, html: string): Promise<string> {
  const encoded = Buffer.from(html).toString('base64');
  const projectName = `numbaa-${slugify(businessName)}-${businessId.slice(0, 8)}`;

  const body = JSON.stringify({
    name: projectName,
    files: [{ file: 'index.html', data: encoded, encoding: 'base64' }],
    projectSettings: { framework: null },
    target: 'production',
  });

  return new Promise((resolve, reject) => {
    const req = https.request(
      {
        hostname: 'api.vercel.com',
        path: '/v13/deployments',
        method: 'POST',
        headers: {
          Authorization: `Bearer ${env.VERCEL_TOKEN}`,
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try {
            const json = JSON.parse(data);
            if (res.statusCode && res.statusCode >= 400) {
              reject(new Error(`Vercel API error ${res.statusCode}: ${json.error?.message ?? data}`));
              return;
            }
            // Prefer the clean production alias (e.g. numbaa-xxx.vercel.app)
            // over the per-deployment URL that includes a hash and account slug.
            const aliases: string[] = json.alias ?? [];
            const cleanAlias = aliases.find((a: string) => a.endsWith('.vercel.app') && !a.includes('now.sh'));
            const rawUrl: string = cleanAlias ?? json.url;
            if (!rawUrl) {
              reject(new Error(`Vercel response missing url. Response: ${data}`));
              return;
            }
            resolve(rawUrl.startsWith('http') ? rawUrl : `https://${rawUrl}`);
          } catch {
            reject(new Error(`Failed to parse Vercel response: ${data}`));
          }
        });
      },
    );

    req.on('error', reject);
    req.write(body);
    req.end();
  });
}
