import {
  makeWASocket,
  useMultiFileAuthState,
  DisconnectReason,
  WASocket,
  fetchLatestBaileysVersion,
  makeCacheableSignalKeyStore,
} from '@whiskeysockets/baileys';
import { Boom } from '@hapi/boom';
import qrcode from 'qrcode-terminal';
import path from 'path';
import pino from 'pino';

const SESSION_DIR = path.resolve(process.cwd(), 'whatsapp-session');

let sock: WASocket | null = null;
let isConnected = false;
let reconnectAttempts = 0;
const MAX_RECONNECT = 5;

export async function initBaileysClient(): Promise<void> {
  console.log('[WhatsApp] Initialisation de la connexion Baileys...');
  await connect();
}

async function connect(): Promise<void> {
  const { state, saveCreds } = await useMultiFileAuthState(SESSION_DIR);
  const { version } = await fetchLatestBaileysVersion();

  sock = makeWASocket({
    version,
    auth: {
      creds: state.creds,
      keys: makeCacheableSignalKeyStore(state.keys, pino({ level: 'silent' })),
    },
    printQRInTerminal: false,
    logger: pino({ level: 'silent' }),
    browser: ['NUMBAA', 'Chrome', '1.0.0'],
  });

  sock.ev.on('creds.update', saveCreds);

  sock.ev.on('connection.update', async (update) => {
    const { connection, lastDisconnect, qr } = update;

    if (qr) {
      console.log('\n[WhatsApp] Scanne ce QR code avec le numéro dédié NUMBAA :\n');
      qrcode.generate(qr, { small: true });
    }

    if (connection === 'open') {
      isConnected = true;
      reconnectAttempts = 0;
      console.log('[WhatsApp] ✅ Connecté avec succès');
    }

    if (connection === 'close') {
      isConnected = false;
      const reason = (lastDisconnect?.error as Boom)?.output?.statusCode;

      if (reason === DisconnectReason.loggedOut) {
        console.log('[WhatsApp] Déconnecté (loggedOut). Suppression de la session...');
        const fs = await import('fs');
        fs.rmSync(SESSION_DIR, { recursive: true, force: true });
        reconnectAttempts = 0;
        await connect();
        return;
      }

      if (reconnectAttempts < MAX_RECONNECT) {
        reconnectAttempts++;
        const delay = Math.min(reconnectAttempts * 2000, 10000);
        console.log(`[WhatsApp] Reconnexion dans ${delay / 1000}s (tentative ${reconnectAttempts}/${MAX_RECONNECT})...`);
        setTimeout(connect, delay);
      } else {
        console.error('[WhatsApp] ❌ Impossible de reconnecter après', MAX_RECONNECT, 'tentatives.');
      }
    }
  });
}

/**
 * Envoie un message WhatsApp.
 * @param phone - Numéro avec indicatif, sans +. Ex: 22670000000
 * @param text - Contenu du message
 */
export async function sendWhatsAppMessage(phone: string, text: string): Promise<void> {
  if (!sock || !isConnected) {
    throw new Error('WhatsApp non connecté. Réessaie dans quelques instants.');
  }

  // Formatage: 22670000000 → 22670000000@s.whatsapp.net
  const jid = `${phone.replace(/^\+/, '')}@s.whatsapp.net`;

  await sock.sendMessage(jid, { text });
}

export function getConnectionStatus(): boolean {
  return isConnected;
}
