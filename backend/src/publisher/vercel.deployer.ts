import https from 'https';
import { env } from '../config/env';

export async function deployToVercel(businessId: string, html: string): Promise<string> {
  const encoded = Buffer.from(html).toString('base64');

  const body = JSON.stringify({
    name: `numbaa-${businessId}`,
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
            const url: string = json.alias?.[0] ?? json.url;
            if (!url) {
              reject(new Error('Vercel response missing deployment URL'));
              return;
            }
            resolve(url.startsWith('http') ? url : `https://${url}`);
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
