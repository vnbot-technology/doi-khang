# DoiKhang Anime — Fighting Game Design Spec
Date: 2026-05-29

## Overview

A 2D anime-themed fighting game with LAN and internet multiplayer support. Built with Godot 4 (GDScript), featuring characters from popular anime series: Dragon Ball, Naruto, One Piece, Detective Conan, and Doraemon.

## Technology Stack

- **Engine:** Godot 4 (GDScript)
- **Visual Style:** 2D Cartoon/Anime (cel-shaded, smooth vectors)
- **Networking:** ENet (UDP) via Godot 4 built-in `ENetMultiplayerPeer`
- **Relay Server:** Node.js WebSocket server for internet play
- **LAN:** UDP broadcast for local network discovery
- **Platform Target:** Windows, macOS, Linux (desktop)

## Project Structure

```
doiKhang/
├── godot_project/
│   ├── project.godot
│   ├── scenes/
│   │   ├── MainMenu.tscn
│   │   ├── CharacterSelect.tscn
│   │   ├── LobbyRoom.tscn
│   │   ├── GameArena.tscn
│   │   └── ResultScreen.tscn
│   ├── scripts/
│   │   ├── networking/
│   │   │   ├── NetworkManager.gd      # ENet host/join, room management
│   │   │   ├── RollbackManager.gd     # Input buffer, predict/rollback
│   │   │   └── RelayClient.gd         # WebSocket relay connection
│   │   ├── characters/
│   │   │   ├── CharacterBase.gd       # Base state machine, physics
│   │   │   ├── Goku.gd
│   │   │   ├── Naruto.gd
│   │   │   ├── Luffy.gd
│   │   │   ├── Conan.gd
│   │   │   ├── Doraemon.gd
│   │   │   └── Sakura.gd
│   │   ├── ui/
│   │   │   ├── HUD.gd                 # HP bars, timer, round display
│   │   │   └── CharacterSelectUI.gd
│   │   └── game/
│   │       ├── GameManager.gd         # Round logic, win conditions
│   │       └── AIController.gd        # AI for 2v2 vs AI mode
│   ├── assets/
│   │   ├── characters/                # Sprite sheets per character
│   │   ├── backgrounds/               # Arena backgrounds
│   │   ├── sfx/                       # Sound effects
│   │   └── ui/                        # UI elements
│   └── addons/
└── relay_server/
    ├── package.json
    ├── server.js                      # WebSocket relay (~100 LOC)
    └── README.md
```

## Game Modes

### 1v1 PvP
- 2 players fight each other (local or network)
- Best of 3 rounds, 90 seconds per round
- Win: reduce opponent HP to 0, or highest HP when timer ends

### 2v2 Coop vs AI
- 2 human players vs 2 AI-controlled enemies
- Wave-based: 3 waves, each wave harder
- Shared HP pool for AI enemies

### 2v2 PvP
- Team A (2 players) vs Team B (2 players) over network
- Tag-team style: one active fighter per team at a time
- Switch partner with dedicated button (costs 1 second stun)

## Characters

### Goku (Dragon Ball)
- **Normal:** 3-hit punch combo, short range
- **Special (Q):** Kamehameha — charged beam, 1.5s charge, horizontal projectile
- **Ultimate (E):** Super Saiyan burst — 3s aura, +20% damage, +10% speed
- **Passive:** Ki charge — hold S to fill Ki meter faster

### Naruto (Naruto)
- **Normal:** Shuriken throw at range + close kick
- **Special (Q):** Rasengan — spiraling orb, close range, high damage
- **Ultimate (E):** Shadow Clone Jutsu — summon 2 clones that mirror attacks for 5s
- **Passive:** Chakra recovery — regenerates special meter faster

### Luffy (One Piece)
- **Normal:** Gum-Gum Pistol — long-range extending punch
- **Special (Q):** Gum-Gum Rocket — dash across arena
- **Ultimate (E):** Gear Second — 8s speed boost, all attacks faster and stronger
- **Passive:** Rubber body — immune to lightning/electric effects

### Conan (Detective Conan)
- **Normal:** Powered kick with shoe booster
- **Special (Q):** Stun gun wristwatch — short range, stuns 1.5s
- **Ultimate (E):** Soccer kick combo — 5-hit ball combo
- **Passive:** Deduction — can see opponent's next move (brief outline flash)

### Doraemon (Doraemon)
- **Normal:** Random gadget throw (3 types: boomerang, mini-bomb, rope)
- **Special (Q):** Anywhere Door — teleport to cursor position
- **Ultimate (E):** Bamboo Copter spin — spinning hitbox, invincible during spin
- **Passive:** Pocket — can store one item to use later

### Sakura (Naruto)
- **Normal:** Ground-shattering punch (creates shockwave)
- **Special (Q):** Healing jutsu — restores 15% HP (self or teammate in 2v2)
- **Ultimate (E):** Cherry Blossom Impact — massive AoE punch
- **Passive:** Medical nin — heals 5 HP/sec when not taking damage

## Networking Architecture

### LAN Play
1. Host clicks "Create LAN Room" → starts ENet server on port 7777
2. Host broadcasts room info via UDP on LAN
3. Other players click "Find LAN Rooms" → receive broadcast, join directly

### Internet Play
1. Both players connect to relay server via WebSocket
2. Host creates room → receives 6-char room code (e.g. `AB12XZ`)
3. Guest enters room code → relay connects both
4. Game data flows: Client → Relay → Host (and vice versa)
5. Relay only forwards binary packets, no game logic

### Rollback Netcode
- Input history buffer: 8 frames
- Each frame: send local input, predict remote input (repeat last input)
- On mismatch: rollback to divergence frame, re-simulate
- Max rollback: 8 frames (~133ms at 60fps)
- If lag > 8 frames: stall one frame (classic delay-based fallback)

### Packet Structure
```
Frame #  | Player ID | Input bitmask | Checksum
4 bytes  | 1 byte    | 2 bytes       | 2 bytes
```

## Input Mapping

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| Move Left | A / Arrow Left | D-pad Left |
| Move Right | D / Arrow Right | D-pad Right |
| Jump | W / Arrow Up | A button |
| Crouch | S / Arrow Down | D-pad Down |
| Normal Attack | J / Z | X button |
| Special (Q) | K / X | Y button |
| Ultimate (E) | L / C | RB button |
| Block | Shift / V | LB button |
| Tag Switch (2v2) | Tab | Select |

Player 2 uses numpad or second gamepad.

## Scene Flow

```
MainMenu
  ├── Play Local (1v1 same keyboard/gamepad)
  ├── Play LAN
  │   ├── Create Room → LobbyRoom
  │   └── Find Rooms → Room List → LobbyRoom
  ├── Play Internet
  │   ├── Create Room → Room Code → LobbyRoom
  │   └── Join Room → Enter Code → LobbyRoom
  └── Settings

LobbyRoom
  ├── CharacterSelect (each player picks character)
  └── Mode Select (1v1 / 2v2 PvP / 2v2 vs AI)
      └── GameArena
          └── ResultScreen → MainMenu or Rematch
```

## HUD Layout

```
[Player 1 Avatar] [████████░░] HP  ROUND 2  HP [████████░░] [Player 2 Avatar]
[Char Name]       [████░░░░░░] SP            SP [████░░░░░░] [Char Name]
                                  [01:23]
                         [FIGHT! / ROUND 1 / KO!]
```

## AI Controller (2v2 vs AI Mode)
- 3 difficulty states: Easy / Medium / Hard
- State machine: Idle → Approach → Attack → Retreat → Block
- Reaction time delay: Easy=500ms, Medium=200ms, Hard=80ms
- Hard AI can use specials and ultimates

## Relay Server

Node.js WebSocket server:
- Room creation with 6-char codes
- Max 4 players per room
- Forward binary game packets between room members
- Heartbeat ping/pong to detect disconnects
- Auto-cleanup rooms when empty
- Deploy on Railway or Render (free tier)

## Visual Assets Required

Per character: idle, walk, jump, crouch, normal_attack (3 frames), special, ultimate, hurt, death — ~40 frames total.

Backgrounds (5 arenas):
1. Hyperbolic Time Chamber (Dragon Ball)
2. Hidden Leaf Village (Naruto)
3. Thousand Sunny deck (One Piece)
4. Beika Town street (Conan)
5. Nobita's room (Doraemon)

## Success Criteria (MVP)

- [ ] 5 playable characters with distinct moves
- [ ] 1v1 local play working
- [ ] 2v2 coop vs AI working
- [ ] LAN multiplayer (2 players on same network)
- [ ] Internet multiplayer via relay server room code
- [ ] Basic sound effects (hit, special, music)
- [ ] Character select screen
- [ ] Win/lose screen
