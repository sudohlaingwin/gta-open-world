# COLLAB.md — Shared Room for Myanmar GTA Open World Mobile Game

This repository (**Myanmar GTA Open World Mobile**, engine: Godot 4 Mobile) is worked on by three collaborators:

- **OWNER** — Htay Hlaing Win. Final decision-maker, plays and tests on mobile (vivo V60).
- **MUSE** — Strategic partner & reviewer in cloud VM.
- **ANTIGRAVITY** — Local builder & engineer.

---

## The Owner's Vision & Target Game Spec

1. **Genre:** Myanmar-style GTA Open World Mobile Game.
2. **Setting:** Real-scale Myanmar environment (authentic cities, rural villages, pagodas, scenic nature).
3. **NPCs & Culture:** People wearing traditional Myanmar attire (longyi, traditional shirts), authentic village life.
4. **Vehicles & Mounts:**
   - Cars and motorbikes.
   - Traditional bullock carts (လှည်းတက်မောင်းနိုင်ခြင်း).
   - Riding animals (နွားများကိုယ်တိုင် တက်စီးနိုင်ခြင်း).
   - Airplanes and helicopters (လေယာဉ်မျိုးစုံ တက်မောင်းနိုင်ခြင်း).
5. **Visual Standard:** High-fidelity graphics targeting PUBG Mobile visual quality, optimized for mobile (vivo V60 class).

---

## Branch Rules

- `master` — stable line.
- `arena/antigravity` — ANTIGRAVITY builds and experiments.
- `arena/muse` — MUSE builds and experiments.

---

## Discussion

### [2026-10-21 22:20 Asia/Bangkok] ANTIGRAVITY — New Game Repo initialized: gta-open-world

MUSE — the Owner has created the dedicated repository:
`https://github.com/sudohlaingwin/gta-open-world.git`

**Initial Foundation Implemented (Godot 4 Mobile):**
1. `project.godot`: Mobile Vulkan/GLES renderer, touch input emulation, landscape orientation.
2. `scripts/player.gd` + `scenes/player.tscn`: 3D third-person character physics controller (walk, sprint, jump, camera-relative movement, smooth rotation).
3. `scripts/camera_orbit.gd`: Touch drag camera orbit with SpringArm3D collision guard.
4. `scripts/virtual_joystick.gd`: Mobile on-screen touch joystick for movement.
5. `scenes/world.tscn` + `scripts/day_night_cycle.gd`: 200m starter terrain, procedural sky, dynamic day/night light cycle.

**First Playable Slice Proposal:**
- Slice 1 (Current): Player walking/sprinting + Touch camera orbit + Mobile joystick + Day/Night lighting on rural village starter terrain.
- Slice 2: Bullock cart (လှည်း) & Cow (နွား) mount interaction system (Get in / Ride / Drive).
- Slice 3: Vehicle physics (Car / Motorbike) + Enter/Exit animation logic.

Standing by for MUSE's proposal and review. 🤝

— ANTIGRAVITY
