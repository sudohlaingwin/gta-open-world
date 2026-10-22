# PHASE 1 — COMPLETE PROJECT AUDIT

**Project:** Myanmar GTA Open World (peaceful, third-person, mobile, Godot)
**Audited commit:** `be34d31` (Slice 36 — bicycle driving-physics polish), branch `main`
**Audit date:** 2026-10-22
**Method:** Read-only inspection of a separate worktree (`gta-audit-wt`, detached at
`be34d31`) with the real Godot 4.3 stable binary. Every "broken" claim below has
file/line evidence or a reproduced headless test. Nothing in this report is based
on the live clone (a Slice 37 Mindon-district worker is building there), and
nothing here covers the in-flight Mindon district — its absence is NOT counted
as a gap. Headless load/simulation tests are NOT phone playtests; phone-only
items are listed explicitly at the end.

## 0. Baseline facts (verified)

- Engine: Godot 4.3 stable, renderer **GL Compatibility**
  (`project.godot`: `config/features=PackedStringArray("4.3", "GL Compatibility")`,
  `renderer/rendering_method="gl_compatibility"`).
- Entry scene: `scenes/ui/main_menu.tscn`. Application name
  `config/name="Myanmar GTA Open World"`; in-menu title is "Myanmar Open World".
- **No `export_presets.cfg` in the repo** (it is gitignored). A fresh clone cannot
  export Android without recreating the preset locally. The export also needs
  `rendering/textures/vram_compression/import_etc2_astc=true` in `project.godot`
  at export time or the export fails blank — that setting is **not committed**;
  it is applied locally at export time and reverted. This is a release-process
  gap, not a gameplay bug.
- **No InputMap actions exist** (`project.godot` has no `[input]` section). All
  keyboard input is hardcoded physical-key checks (see §3.5).
- World: one scene, `main.tscn` — **1537 `[node]` lines, 1166 MeshInstance3D,
  48 CollisionShape3D, 18 StaticBody3D, 572 top-level children,
  `load_steps=431`** (header count verified: 20 ext + 410 sub + 1).
- Code: 27 scripts, 5318 lines. `player.gd` alone is **2338 lines** (world
  controller: movement, HUD, all 36 quest interactions, minimap, map, guidance,
  pause, photo, audio). Autoloads: `SaveManager`, `MissionManager`
  (`mission_data.gd` holds the 36-stage chain as data).
- Baseline verification (real binary, this worktree): all 27 scripts pass
  `--check-only`; `main.tscn` and `main_menu.tscn` load + instantiate headlessly
  with zero script/scene errors (only headless dummy-renderer RID noise at exit);
  every `ext_resource` path in `main.tscn` + UI scenes resolves to a real file;
  zero `#` comment lines in any `.tscn` (the old corruption family is gone on
  Muse's branch); zero TODO/FIXME/placeholder markers in any script.
- No combat anywhere: grep finds no weapons, enemies, wanted levels, or combat
  HUDs. The peaceful rule is satisfied by construction, not just by policy.

## 1. Working correctly

1. **Save/load foundation** (`autoload/save_manager.gd`, 186 lines). Versioned
   JSON (`SAVE_VERSION = 1`); saves position + rotation, quest stage, talked
   villagers by node NAME (not instance id), stamina, 10 reward flags, 22
   counters, crop/rice growth, settings snapshot. Load path is defensive:
   `load_save()` rejects missing files, unparseable JSON, wrong versions, and
   missing `quest_stage`/`player` keys; `player.gd` `_apply_pending_load()`
   (lines 1970–2010) type-checks every nested field and clamps stamina.
   Settings load validates HTML colours and clamps every numeric setting to
   its range, so a hand-edited file cannot produce an unusable HUD or a dead
   joystick. Old-format files fall back to defaults. Verified by test: a valid
   save round-trips (stage 36 in, stage 36 out).
2. **Mission framework** (`autoload/mission_manager.gd` + `mission_data.gd`).
   36-stage chain as data; `advance()` fires only on a matching from-stage
   (out-of-order = silent no-op); a reward flag never re-applies; label/tracker/
   counter text rendering lives in one place; load maps old saves unchanged.
   Free roam is never gated by missions.
3. **Touch-first controls.** Joystick + on-screen buttons (Talk, Sprint, Jump,
   Vehicle, yaw, zoom, camera reset, help, map) are the primary path; keyboard
   exists only as desktop-debug fallback (see §3.5 for the one exception).
   Joystick deadzone is a single shared setting (S32) read live by every
   vehicle through the driver's deadzone-filtered `touch_vector`.
4. **Camera collision avoidance** (`camera.gd`, S24). Both ray directions
   (eye→camera and camera→eye), fast shorten (14 m/s) / slow recovery
   (2.5 m/s), minimum distance 1.2 m, 0.4 m wall margin, layer mask 1+2, and
   non-StaticBody3D bodies excluded so villagers/vehicles never yank the view.
   Layer-2-only blocker volumes cover collision-less houses for the camera.
5. **Vehicle physics polish, 4 of 11 vehicles** (car S26, motorcycle S31,
   tuk-tuk S33, bicycle S36). Each has a measured before/after table from a
   harness driving the real script: soft-launch accel curve, real braking that
   never rolls the vehicle backwards by itself, speed-dependent steering,
   8.0/s steering smoothing, longer coast, wheels rolling at ground speed via
   `rotate_object_local` (the old `rotate_y` bug — wheels yawing instead of
   rolling — was caught by harness basis math and fixed in all four).
   Enter/exit contracts verified per vehicle (driver set/cleared, camera
   retargets, speed zeroed, step-out beside the vehicle).
6. **Traffic AI** (`traffic_manager.gd` + `traffic_car.gd`). 6-slot mixed
   car/van fleet on waypoint loops, stop-only avoidance (own half-length +
   2.2 + 0.4 gap), 15 s stuck-timeout despawn + refill from a 25–45 m band
   (never on top of the player), time-of-day density/speed scaling from the
   single shared `daylight()` value, headlights exactly when daylight < 0.15,
   pause truly freezes traffic. Not enterable, not saved — both stated.
7. **Villager schedules, all 18** (`npc.gd`, S29). `day_anchor` workplaces by
   day, homes at night, walk-not-teleport shifts, mid-conversation deferral,
   circle-steering obstacle avoidance (36 mapped circles). No teleporting.
8. **World map + waypoint guidance** (`world_map.gd`, S28 + S34). Landmarks
   from real world positions, tap-to-set waypoint, zoom 0.5–3× + drag-pan,
   player marker clamped, camera-relative 8-way arrow + live distance,
   arrived state at 5.0 m, guidance labelled as guidance-only (no routing
   claimed). Pause state is recorded and restored exactly on open/close.
9. **Settings that all genuinely work** (`scenes/ui/settings_panel.gd`):
   mute, master volume, camera sensitivity 50–200%, HUD size 80–125%, joystick
   deadzone 0–40%, reset-to-defaults restoring every key. Outfit (S30) and
   vehicle paint (S35) persist in `settings.json` and apply at world spawn
   with duplicated materials (shared-material trap handled: player/villager
   and motorcycle/bicycle isolation verified by test).
10. **Menu / pause / audio.** Continue visible only with a valid save
    (else honest "no save yet" label); pause overlay (Resume / Save /
    Settings / Quit to Menu, saves first); generated sine-tone audio where
    mute genuinely gates every tone (`player.gd` `_play_tone`, line 1554).
11. **Visual atmosphere pass** (S25): material identities (dirt/stone/grass/
    mud roughness), glossy vehicle paint, golden-hour sun colour, night
    window lights on one shared emissive material toggled by the < 0.15 rule,
    genuinely transparent pond water (alpha blend mode, not the broken
    alpha-without-blend approach).

## 2. Working but needing improvement

1. **Player controller monolith.** `player.gd` (2338 lines, ~100 functions)
   owns movement, camera wiring, every quest interaction, HUD, minimap, map,
   guidance, pause, photo, and audio. It works, but every future slice edits
   the same file, and the per-frame `_physics_process` runs ~25 `_update_*`
   calls (lines 234–395), including `_update_minimap()` every physics frame:
   ~60 `get_node_or_null` lookups, a `get_nodes_in_group("villagers")` scan,
   string formatting, and ~60 dot position writes per frame. Not a proven
   bottleneck (never profiled on device), but it is the largest per-frame
   cost centre and the first place to look if frame pacing is bad.
2. **Minimap/world-map transform assumes a ±50 m world**
   (`player.gd` `_update_minimap`: `(wpos + 50) / 100 * 170`, clamped).
   Any district beyond ±50 m (the in-flight Mindon district) piles its dots
   at the map edge unless the transform is generalised. Forward-compat work,
   not a be34d31 defect.
3. **Vehicle coverage is 4 of 11.** Cart, airplane, helicopter, cow, boat,
   elephant, horse still run their original unpolished handling (no accel
   curve, no real brake, no speed-dependent steering, no wheel-roll fix).
   The four polished vehicles are the reference standard; the rest are not
   broken, just visibly less refined by comparison.
4. **Traffic is stop-only and not enterable.** A car stopped behind a parked
   player vehicle waits out the 15 s timeout and despawns — correct behaviour
   for the design, but it reads as a "vanishing car" to a player who does not
   know the rule. No signals, no intersection priority, no steering-around.
5. **Day length is 120 s for a full cycle** (`day_night.gd`
   `day_length_seconds = 120.0`). Villager commutes (~21 s) fit inside the
   ~54 s daylight band, but a 2-minute day/night cycle makes schedules and
   golden hour feel rushed. Tuning, not a bug.
6. **Dialogue is a 4-second Label3D bubble** (`npc.gd` `talk_seconds = 4.0`).
   No subtitle system, no dialogue history, no readable-text option. Works
   for one-line greetings; insufficient for anything longer.
7. **Icon is programmatic** (256×256 PIL-generated PNG, stated, not
   hand-drawn). Acceptable as a placeholder; not store-grade art.
8. **HUD has no safe-area inset.** Buttons anchor to screen edges
   (`main.tscn`: TalkButton anchors 0.78–0.97, Sprint/Jump 0.60–0.74, joystick
   offset 30 px) with no notch/rounded-corner margin. Unverified on device
   whether any control sits under a cutout — flag for the device test, not
   asserted as broken.

## 3. Broken or unreliable

1. **(FIXED in this audit — see §8) Interrupted save destroyed all progress.**
   `save_manager.gd` `save_game()` opened the live file for WRITE and
   streamed JSON into it. A kill/crash/power loss mid-write left a truncated
   file, and `load_save()` treats unparseable JSON as "no save" — total,
   silent progress loss. Reproduced headlessly: a valid save (stage 36)
   truncated to half its bytes loads as `{}`; no `.bak` existed. Same
   pattern in `save_settings()`. Root cause: no atomic write. Fixed by
   `_atomic_write()` (temp file + rename); see §8 for before/after evidence.
2. **The player walks through houses and walls.** Houses are bare
   MeshInstance3D with no physics body: `House1` at (-8, 2, -8) has no
   StaticBody3D/CollisionShape3D anywhere near it, and the whole world has
   only 18 StaticBody3D against 1166 meshes. Reproduced headlessly: a
   CharacterBody3D walking east from (-14, 3, -8) at 5 m/s crossed House1's
   footprint to x = -7.85 with **0 slide collisions**. The Slice 24 camera
   blockers only stop the *camera*, not the player. Villagers steer around
   houses (obstacle circles) but the player does not. This is the largest
   gameplay-feel defect in the build: walls are decoration for the player.
3. **No world bounds.** Nothing in `player.gd` or any vehicle script clamps
   position to the ~100×100 m village. A player can walk/drive past the field
   edge into empty space (ground plane extent permitting) with no fence,
   water edge, or "you are leaving" response. Unverified how far the ground
   plane extends — the failure mode is "empty void", not a crash.
4. **Vehicle exit has no clearance check.** Every vehicle exit is a fixed
   offset (e.g. `car.gd:133`: `p.global_position = global_position +
   Vector3(2.0, 0.5, 0.0)`), with no check for a wall, water, or traffic at
   the landing spot. Harmless today only because walls have no collision
   (§3.2) and traffic has no body — the moment §3.2 is fixed, exits into
   walls become a real stuck-player bug. Fix §3.2 and §3.4 together.
5. **Keyboard keys still exist as input paths (minor, by design).**
   `KEY_SHIFT` (sprint), `KEY_CTRL` (descend), `KEY_Q`/`KEY_E` (orbit/yaw),
   `KEY_J` (jump), `KEY_E` (dialogue fallback with edge detection,
   `player.gd:386`) are hardcoded physical-key checks; there is no InputMap.
   On a phone these keys do nothing (no keyboard), so this is not a
   mobile-first violation — but the E-key dialogue path is exactly the one
   the owner corrected in Slice 6/7, and it must stay fallback-only. No new
   KEY_ input was found in this audit.
6. **Save snapshot staleness (cosmetic).** `collect_save_data()` writes a
   `settings` snapshot (muted/volume) into `savegame.json`, but the
   authority for settings is `settings.json`. The snapshot is redundant,
   not harmful; a future reader could mistake it for the source of truth.
   Note for the next save-system touch, not a standalone fix.

## 4. Not implemented

1. **No graphics options, no FPS limit.** Settings offers mute, volume,
   camera sensitivity, HUD size, deadzone — no quality tier, no shadow
   toggle, no resolution scale, no FPS cap. `project.godot` sets no vsync
   or `max_fps` anywhere. On a low-end phone there is no lever to pull.
2. **No LOD, occlusion culling, or district streaming.** 1166 meshes draw
   with no distance culling strategy; the only culling is Godot's default
   frustum culling. Shadows are on (`main.tscn:1465`
   `shadow_enabled = true`) with no documented shadow-distance budget.
3. **No FPS / frame-time measurement on any real device, ever.** All
   verification to date is headless load/simulation testing. The 30 FPS
   baseline target from the master prompt is unmeasured, and no profiling
   hook exists in the project.
4. **No new mission types.** The framework supports them (format fields for
   waypoints/timers/checkpoints exist in `mission_data.gd`) but no playable
   sightseeing, delivery, taxi, parking, time-trial, or photography mission
   exists. The 36-stage chain is the only content.
5. **No driving assistance modes.** The master prompt asks for arcade /
   balanced / realistic handling modes with meaningful, tested differences.
   None exists; the four polished vehicles each have one fixed tune.
6. **No vehicle stuck-recovery.** No reset-to-road, no "unstick" button, no
   recovery when a vehicle ends up in water, against a (future) wall, or
   off the playable area. Currently masked by §3.2/§3.3 (no colliders, no
   bounds), so it becomes urgent the moment those are fixed.
7. **No city districts at be34d31** (village only). Not counted as a gap
   for this audit: the Mindon town-centre district is in flight in Slice 37.
8. **No accessibility options.** No reduced motion, no subtitle system, no
   control-layout customisation, no colour-independent indicators beyond
   the existing text labels.
9. **No owned-vehicle / garage progression, no unlockable locations, no
   exploration rewards beyond the 10 quest rewards.** All world vehicles
   are free to use; nothing is collected or unlocked.
10. **No store-readiness artefacts in the repo.** No release signing config
    (the shipped APKs use Godot's default debug certificate), no store
    screenshots/description/metadata, no privacy note, no third-party
    asset/license document (all art is primitive meshes + generated tones,
    so the license surface is small — but it is undocumented).

## 5. Performance risks

1. **1166 meshes, no LOD/culling strategy, shadows on.** Draw-call and
   shadow-map cost on a low-end Mali GPU is the top unmeasured risk. The
   world is small (~100×100 m), which bounds the problem, but nothing in
   the project measures it.
2. **Per-frame HUD update cost** (§2.1): ~25 `_update_*` calls per physics
   frame in `player.gd`, ~60 node lookups + group scan in the minimap
   alone, plus label text writes every frame. Likely fine on a modern
   phone, unproven on a low-end one.
3. **Traffic + NPC per-frame cost is small but unmeasured**: 6 traffic
   vehicles + 18 villagers with steering math each frame. No distant-AI
   throttling exists (all NPCs simulate at full rate regardless of
   distance). Fine at current counts; a risk only if counts grow with new
   districts.
4. **Particle systems are always simulated when visible**: rain (400 drops),
   fireflies, birds/clouds/butterflies (`skylife.gd`). No quality scaling.
5. **No texture budget exists** because there are no textures (flat
   colours + primitive meshes). This is a strength for performance and a
   weakness for visual quality — see §6.
6. **A single 415 KB `main.tscn` with 1537 nodes** loads as one unit; load
   time on a low-end phone is unmeasured, and every edit risks merge-style
   conflicts between duel sides (already the pattern of this project).

## 6. Visual and UX quality issues

1. **Flat colours + primitive meshes everywhere.** Coherent stylised
   low-poly is achievable (S25 material/lighting pass helps), but the
   current look is boxes and cylinders with flat colours — not the
   "premium" bar the master prompt sets, and not verifiable as attractive
   without a device screenshot.
2. **Obvious asset repetition.** The same BoxMesh/CylinderMesh primitives
   repeat for every house, tree, stall, and fence. Fine for background
   dressing; prominent locations (pagoda, market, festival ground) reuse
   the same vocabulary as background houses.
3. **No sidewalks, curbs, or intersection dressing.** Roads are flat strips;
   there is no kerb height, crossing marking, or pavement edge — the
   village reads as buildings on a plain, not a town plan.
4. **Feet/wheels grounding is approximate.** Vehicles and animals sit at
   hand-tuned y offsets (e.g. vehicles at y = 0.5, houses at y = 2.0);
   there is no ground-snap, so slopes, bridges, and decks can show
   floating or sinking by small amounts. Unverified visually headlessly.
5. **HUD density.** The counter line carries 22 emoji counters, the quest
   tracker, speed, compass, clock, day label, stamina bar, guidance strip,
   minimap, and up to ~10 contextual buttons. Readable at 1280×720 in the
   editor; on a small phone with HUD scale 80% it may be cramped — device
   test required, not asserted.
6. **No visual feedback for several interactions.** Buying, donating,
   picking, and feeding show a counter increment and (sometimes) a timed
   label, but there is no consistent "success" animation or sound pattern
   across all 36 stages.

## 7. High-priority release blockers

Ordered by "would stop a release", not by ease:

1. **Interrupted-save progress loss** — FIXED in this audit (§8). Was the
   only data-loss defect found. Any build shipping without the fix risks a
   one-star "lost all my progress" report from a single interrupted save.
2. **Player walks through walls** (§3.2). The single largest feel/correctness
   defect. A player who notices they can walk through a house stops
   believing the world is solid. Fix: add StaticBody3D colliders to houses
   and other solid structures (layer 1), reusing the Slice 24 blocker
   volumes where they already exist — then fix vehicle exit clearance
   (§3.4) in the same change, or exits into walls become the next bug.
3. **No real-device test of any kind.** No FPS measurement, no touch
   ergonomics check, no notch/safe-area check, no screenshot of the actual
   look. The Slice 35 APK is on Drive awaiting the owner's vivo V60 verdict;
   until that verdict lands, every "works" claim in this report is
   headless-only. The first device run is a blocker for any release claim.
4. **Export configuration is not in the repo** (§0). No
   `export_presets.cfg`, no committed etc2_astc setting, debug-certificate
   signing only. A release build is not reproducible from a fresh clone,
   and a store build cannot ship on the debug certificate.
5. **No world bounds + no stuck-recovery** (§3.3 + §4.6). Today masked by
   missing colliders; becomes a visible "fell off the world / stuck"
   defect as soon as §7.2 lands. Fix bounds + recovery in the same round
   as colliders.
6. **No graphics/FPS lever for low-end phones** (§4.1). If the first
   device test shows sub-30 FPS, there is nothing to turn down without a
   code change. A single quality toggle (shadows on/off + particle scale)
   is cheap insurance and should land before the next APK.

## PRIORITIZED IMPROVEMENT PLAN

Ordered: release blockers first, then highest player-visible impact. Each
item states the change, the files it touches, and how it is verified. No
working system is rewritten; no branding/marketing work is proposed while
gameplay blockers remain (per the prompt's Phase 2 rule).

1. **Atomic saves** (DONE in this audit, §8). Files: `autoload/save_manager.gd`
   only. Verified headlessly (see §8). Land it first — it is the only
   data-loss fix and it touches no scene.
2. **Solid houses + exit clearance + world bounds + stuck recovery**
   (one round, because they interact). Change: add StaticBody3D colliders
   to houses and solid structures in `main.tscn` (reusing Slice 24
   blocker-volume positions where they exist); add a clearance check to
   each vehicle exit path (`car.gd`, `motorcycle.gd`, `tuktuk.gd`,
   `bicycle.gd`, and the unpolished vehicles' exit paths) so the step-out
   picks a free spot; clamp the player and vehicles to the playable area
   (or fence it visibly); add a "reset to road" recovery for stuck
   vehicles. Verify: headless walk-through test (player must NOT cross a
   house footprint, collisions > 0), exit test (exit beside every vehicle
   lands on free ground), bounds test (player cannot leave the area);
   then the owner's device verdict on feel.
3. **Commit the Android export configuration.** Change: add a checked-in
   `export_presets.cfg` (or a documented export script) with the etc2_astc
   setting committed in `project.godot`, and record the signing state
   (debug cert today, release keystore as an owner decision). Verify: a
   fresh worktree exports a debug APK headlessly with exit 0. This makes
   every future APK reproducible.
4. **One graphics quality toggle + FPS measurement hook.** Change: a
   "Graphics: High / Low" setting in `settings.json` + settings panel
   (Low = shadows off + rain/firefly particle counts halved) and a tiny
   FPS readout (toggleable, off by default) so the owner's device test
   can report a number instead of "feels slow". Files:
   `autoload/save_manager.gd`, `scenes/ui/settings_panel.gd`,
   `scenes/ui/settings_panel.tscn`, `player.gd` (readout only). Verify:
   headless (setting persists, shadow flag flips); device (owner reports
   FPS on High vs Low).
5. **Finish vehicle physics parity (7 remaining vehicles).** Change: apply
   the S26/S31/S33/S36 pattern (accel curve, real brake, speed-dependent
   steering, smoothing, ground-speed wheels) to cart, airplane, helicopter,
   cow, boat, elephant, horse — one vehicle per round, measured
   before/after tables, same harness method. Verify per vehicle as in S36.
6. **Generalise the minimap/world-map transform.** Change: replace the
   hardcoded ±50 m mapping with a world-bounds value shared by minimap,
   world map, and guidance, so the Mindon district (and any future
   district) renders correctly instead of clamping at the edge. Files:
   `player.gd` (`_update_minimap`), `world_map.gd`. Verify: headless map
   sim with a landmark beyond ±50 m lands at the correct pixel.
7. **Throttle per-frame HUD work.** Change: cache minimap dot nodes once
   (already partially done via `minimap_dots`), move static landmark dots
   to update only when the landmark moves or every N frames, and set
   label text only when it changes. Files: `player.gd` only. Verify:
   headless (same minimap output, fewer node lookups per frame — count
   via instrumentation in the test, not by feel).
8. **New mission types (one at a time, after §2–§4).** Sightseeing
   (visit landmarks) first — it reuses the map/guidance systems — then
   delivery, then taxi. Each as data in `mission_data.gd` + world triggers
   in `player.gd`, with rewards through the existing manager. Verify:
   headless full-chain sim + device feel.
9. **Driving assistance modes** (arcade / balanced / realistic) as a
   setting that scales the polished vehicles' steering/brake/coast
   parameters. Only meaningful after §5 (parity), otherwise the modes
   would differ on 4 vehicles and do nothing on 7. Verify: measured
   tables per mode per vehicle.
10. **Visual dressing pass for prominent locations** (pagoda, market,
    festival ground, guest house): distinct silhouettes/materials so they
    do not read as background houses. Only after §2–§4; beauty work must
    not precede solidity work. Verify: device screenshots from the owner.

## 8. FIRST IMPROVEMENT — ATOMIC SAVES (implemented, UNCOMMITTED)

**Problem (reproduced, §3.1):** `save_game()`/`save_settings()` streamed
JSON into the live file. A kill/crash/power loss mid-write left a truncated
file; `load_save()` treats that as "no save" — total silent progress loss.
Repro: valid save (stage 36) truncated to half its bytes → `load_save()`
returns `{}`; no backup file existed.

**Change (one file, no scene touched, fully reversible):**
`autoload/save_manager.gd` — new `_atomic_write(path, text)` helper
(writes `path + ".tmp"`, closes, then `DirAccess.rename_absolute(tmp, path)`)
used by both `save_game()` and `save_settings()`. Rename is atomic, so the
live file is always either the complete old save or the complete new save,
never a half-write. The old file is never opened for WRITE at all.

**Before/after evidence (real Godot 4.3 binary, headless, worktree):**
- BEFORE (original code): save stage 36 → load stage 36 → truncate file to
  half → load `{}` (progress lost), no `.bak`.
- AFTER (this change): save stage 36 → load 36, no `.tmp` left behind;
  poison the `.tmp` file with garbage → load still 36 (tmp garbage never
  touches the live file); save stage 10 → load 10, no `.tmp` left;
  settings round-trip (muted=true, volume=0.5) persists and reloads.
  All 27 scripts still pass `--check-only` (including the edited file).
- Honest limit: this prevents FUTURE corruption from interrupted saves. It
  does NOT recover a save file that is already truncated, and the
  kill-during-rename instant was not literally reproduced (rename
  atomicity is a filesystem guarantee, not something a headless test can
  interrupt mid-syscall). A device test that force-stops the app during a
  save would be the final confirmation.

**Status:** left UNCOMMITTED in the audit worktree (`git status` shows only
`M autoload/save_manager.gd`, +24/−11). The parent can land it with a plain
commit; no push was made from this audit, and the live clone was never
touched.

## NOT VERIFIABLE HEADLESSLY (phone-only items)

- Driving/walking FEEL, steering feel, camera feel, control ergonomics,
  button reachability, HUD readability at phone sizes, notch/safe-area
  behaviour, icon quality, visual beauty, sound quality.
- FPS, frame pacing, memory, load time, thermal behaviour on any real
  device (including the owner's vivo V60).
- Whether the world reads as a town/village on a small screen.
- Touch multi-finger behaviour (joystick + camera drag + button together).
- Real interrupted-save behaviour on Android (force-stop during save).

These need the owner's device verdict or a device test run; nothing in this
audit claims them.
