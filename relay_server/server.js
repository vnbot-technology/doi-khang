const { WebSocketServer, WebSocket } = require('ws');

const PORT = process.env.PORT || 8765;
const wss = new WebSocketServer({ port: PORT });

// rooms: Map<code, { players: Map<peerId, WebSocket>, created: number }>
const rooms = new Map();
let nextPeerId = 1000;

function generateCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 6; i++) code += chars[Math.floor(Math.random() * chars.length)];
  return code;
}

function cleanupRooms() {
  const now = Date.now();
  for (const [code, room] of rooms) {
    for (const [pid, ws] of room.players) {
      if (ws.readyState !== WebSocket.OPEN) room.players.delete(pid);
    }
    if (room.players.size === 0 || now - room.created > 7200000) {
      rooms.delete(code);
    }
  }
}

setInterval(cleanupRooms, 30000);

wss.on('connection', (ws) => {
  const peerId = nextPeerId++;
  ws.peerId = peerId;
  ws.roomCode = null;

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw.toString()); } catch { return; }

    switch (msg.action) {
      case 'create': {
        let code = generateCode();
        while (rooms.has(code)) code = generateCode();
        rooms.set(code, { players: new Map([[peerId, ws]]), created: Date.now() });
        ws.roomCode = code;
        ws.send(JSON.stringify({ type: 'room_created', code, peer_id: peerId }));
        break;
      }

      case 'join': {
        const code = (msg.code || '').toUpperCase().trim();
        if (!code || !rooms.has(code)) {
          ws.send(JSON.stringify({ type: 'error', message: 'Room not found' }));
          return;
        }
        const room = rooms.get(code);
        if (room.players.size >= 4) {
          ws.send(JSON.stringify({ type: 'error', message: 'Room full' }));
          return;
        }
        room.players.set(peerId, ws);
        ws.roomCode = code;
        ws.send(JSON.stringify({ type: 'joined', code, peer_id: peerId }));
        for (const [pid, other] of room.players) {
          if (pid !== peerId && other.readyState === WebSocket.OPEN) {
            other.send(JSON.stringify({ type: 'peer_joined', peer_id: peerId }));
          }
        }
        break;
      }

      case 'relay': {
        const code = ws.roomCode;
        if (!code || !rooms.has(code)) return;
        const room = rooms.get(code);
        for (const [pid, other] of room.players) {
          if (pid !== peerId && other.readyState === WebSocket.OPEN) {
            other.send(JSON.stringify({ type: 'relay', from: peerId, data: msg.data }));
          }
        }
        break;
      }

      case 'ping':
        ws.send(JSON.stringify({ type: 'pong' }));
        break;
    }
  });

  ws.on('close', () => {
    if (ws.roomCode && rooms.has(ws.roomCode)) {
      const room = rooms.get(ws.roomCode);
      room.players.delete(peerId);
      for (const [pid, other] of room.players) {
        if (other.readyState === WebSocket.OPEN) {
          other.send(JSON.stringify({ type: 'peer_left', peer_id: peerId }));
        }
      }
    }
  });

  ws.on('error', (err) => console.error(`WS error peer ${peerId}:`, err.message));
});

wss.on('listening', () => console.log(`Relay server running on port ${PORT}`));
