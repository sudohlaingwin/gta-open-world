# Myanmar GTA — Open World Mobile Game

Owner vision (told directly by Htay Hlaing Win, 2026-10-21):
a Myanmar-style GTA open world game, set in the real Myanmar, with
people in Myanmar traditional dress, carts and cows in the world,
and a player who can drive cars, drive carts, ride motorcycles,
ride cows, and fly various airplanes. Target quality: very good,
PUBG-like graphics. This repo is SEPARATE from H2W Photo Lab.

## Duel

Muse and Google Antigravity build this game together in the open,
alternating review-and-improve rounds. The owner watches and judges
who is best by playing it. No fake claims: a slice is done only when
it runs, and graphics claims match what is actually on screen.

## Slice 1 — playable village block (MUSE entry, 2026-10-21)

Engine: Godot 4, 3D. This first slice is deliberately small and
honest — it is NOT PUBG graphics yet, and it is NOT the whole
country. It proves the loop: walk, enter a car, drive, exit.

What works in Slice 1:
- Third-person walk around a small Myanmar village block
  (ground, houses, cart and cow as scenery for now).
- Walk up to the car and press Enter/Space (ui_accept) to get in,
  drive with arrow keys / WASD, press Enter/Space again to get out.
- Day lighting, third-person follow camera.

What is NOT yet in Slice 1 (next slices, in order):
- Drivable cart, motorcycle, cow riding, airplanes.
- Traditional-dress character models (placeholder capsule for now).
- More areas, traffic, NPCs, quests, mobile touch controls,
  Android APK export (needs Godot + export templates installed).

Run it (desktop, once Godot 4 is installed):
`godot --path . main.tscn` — walk with arrow keys/WASD,
Enter/Space to enter/exit the car.

## Files

- `project.godot` — Godot 4 project, main scene `main.tscn`.
- `main.tscn` — village block scene.
- `player.gd` — third-person walk + enter/exit car.
- `car.gd` — simple drivable car (walk mode off while driving).
- `cart.gd`, `cow.gd` — scenery stubs for Slice 1, drivable in
  later slices (their scripts say so plainly, no fake behaviour).

## Slice 2 — beat the opponent's entry (MUSE, 2026-10-21)

Reviewed the opponent's `master` entry (71485f2) line by line.
Credit where due: camera-relative movement, touch-joystick concept,
day/night concept, mobile renderer settings — good ideas, ported
here as working implementations (not copies).

Concrete defects found in 71485f2 (all from its own files):
- No vehicles at all: no car/cart/motorcycle/cow/airplane code,
  despite the owner spec requiring them.
- Touch joystick is dead code: `virtual_joystick.gd` exists, but no
  scene instantiates it and nothing connects its signal to the
  player, so it cannot move the player.
- Jump/sprint are dead code: `jump()` / `set_sprint()` are defined
  but never called from input or UI.
- Camera "pinch-zoom" is claimed in comments and exports
  (zoom_speed/min/max) but no zoom code exists; orbit is
  touch-drag only, no mouse/keyboard orbit.
- Day/night only rotates the sun; light energy never changes, so
  night is never dark.
- `project.godot` references `res://icon.svg`, which is not in the
  repo (missing-file warning).

Slice 2 fixes/ports all of the above while keeping Slice 1:
- WIRED touch joystick (Joystick UI in main.tscn, writes directly
  to player.touch_vector; mouse works too via emulate_touch).
- Working sprint (Shift) and jump (J, on floor only).
- Day/night WITH darkness (sun energy follows sun angle).
- Keyboard camera orbit (Q/E) in addition to follow view.
- DRIVABLE CART (second vehicle, slower than the car) — player can
  enter the nearest vehicle, car or cart, with Enter/Space.
- Still honest gaps: motorcycle, cow riding, airplanes, real
  traditional-dress models, Android APK — later slices.

## Slice 3 — motorcycle + airplane, beat opponent Slices 2/5 (MUSE, 2026-10-21)

Reviewed opponent commits 0f1c7ec (rideable cow + bullock cart +
vehicle base + mobile UI) and 278fc0b (Slice 5 airplane) line by
line. Credit where due, by name:
- mount_controller: real rideable cow + bullock cart with Area3D
  proximity, saddle reparenting, and a player state machine
  (ON_FOOT / RIDING / DRIVING / FLYING) with interact priority.
- aircraft_controller: a real flight attempt — throttle, lift
  proportional to forward speed, pitch/roll/yaw, cockpit reparent,
  speed cap — and terrain grown 400 -> 1000, so the "1km airspace"
  claim has a real ground plane behind it.
- mobile_touch_ui: the right idea — wire joystick signals into
  player.touch_input_vector and add Interact/Jump/Sprint buttons.

Concrete defects found in 0f1c7ec / 278fc0b (file evidence):
- vehicle_controller.gd is dead code: no scene in either tree
  references it, and a VehicleBody3D with no VehicleWheel3D
  children cannot drive anyway. The opponent tree still has no
  drivable car and no motorcycle.
- mobile_touch_ui.gd is dead code: setup() is never called — no
  world or player scene contains a MobileTouchUI node — so its
  joystick wiring never runs in-game. The Slice-1 dead-joystick
  defect moved, it was not fixed.
- mount_controller.gd reads Input.is_action_pressed("sprint"),
  but project.godot at 278fc0b defines no "sprint" input action
  (only [input_devices] emulate_touch) — undefined action, so
  mount sprint never engages.
- aircraft_controller.gd: throttle auto-rises every frame
  (throttle = clamp(throttle + delta*0.4, 0, 1)) with no
  throttle-down input, so a pilot cannot slow down or land on
  purpose except by exiting mid-air; stall_speed is exported but
  never read (no stall behaviour); roll and yaw both use
  input_dir.x (double turn).
- project.godot still references res://icon.svg, which is still
  not in the repo (missing-file warning, carried from Slice 1).

Slice 3 (this commit) keeps everything from Slice 2 (car, cart,
wired joystick, sprint/jump, dark nights, Q/E orbit) and adds:
- MOTORCYCLE (motorcycle.gd, third vehicle): faster than the car,
  leans into turns, joystick steering/throttle works, Enter/Space
  enter/exit via the same player vehicle picker.
- AIRPLANE (airplane.gd): flyable with EXPLICIT throttle
  (Shift up / Ctrl down, clamped, never auto-rises), pitch
  (Up/Down arrows), roll (Left/Right arrows), yaw (Q/E), joystick
  pitch/roll, and stall that is actually applied (lift collapses
  below stall_speed). Enter/exit cockpit via Enter/Space; exiting
  mid-air drops the pilot — NO parachute yet, stated plainly.
- Muse's own code avoids the listed defects by design: no
  undefined input actions (physical keys used), no unconnected
  signals (joystick writes player.touch_vector directly),
  no missing icon reference in project.godot.

Honesty: Slice 3 code is statically reviewed, NOT run inside
Godot (no Godot binary on this VM yet) — same standard as before:
not a playable APK, not PUBG graphics. Still missing:
traditional-dress character models, Android APK export, the whole
country map, helicopters, parachute.

## Slice 4 — better pagoda, beat opponent d4a1984 (MUSE, 2026-10-21)

Reviewed opponent commits since 278fc0b. `9a1b20a` is a
message-only commit (COLLAB.md, 28 lines, no code) — its claims
are opponent words, not verified here and not adopted. The code
change is `d4a1984`: a golden pagoda scene placed in the world.
Credit: a real tiered landmark (plinth, terrace, bell, spire,
hti), gold metallic material, StaticBody collision, placed in
the world — a genuine Myanmar landmark, not a placeholder box.

Concrete defects in d4a1984 (file evidence):
- One material for everything: plinth, terraces, bell, spire and
  hti all use the same gold material, so the whole structure
  reads flat and monochrome.
- One big collision cylinder (radius 5, height 11) for the whole
  structure: the collision profile does not follow the tiers, and
  there is no platform or site context around it.
- Scenery only: no interaction, no viewpoint, no marker — fair
  for a landmark slice, but it adds no gameplay.
- Standing opponent defects NOT fixed by d4a1984/9a1b20a (neither
  touches those files): dead vehicle_controller, dead
  mobile_touch_ui (setup never called), mount sprint on an
  undefined "sprint" action, airplane throttle auto-rise +
  stall_speed never read + roll/yaw double-using input_dir.x,
  missing icon.svg.

Slice 4 beats the pagoda (main.tscn, Pagoda at -20, -25) while
keeping EVERYTHING from Slice 3 (walk, car, cart, motorcycle,
airplane, wired joystick, sprint/jump, dark nights, Q/E orbit):
- TWO materials: white stone for platform/plinth/terraces,
  gold for bell/spire/hti — the tiers read as stone below and
  gold above, like a real pagoda.
- STEPPED collision: two cylinders (base r6.5/h3.4, bell r3.0/
  h3.5) following the tiers instead of one big tube.
- A round platform (r9) under the pagoda, so it sits in a site,
  not floating alone on the plane.
- Honest limits, stated plainly: the pagoda is still scenery
  (no enter, no quest, no viewpoint marker yet); cow riding,
  helicopter, traditional-dress character models, Android APK,
  whole-country map and PUBG graphics are STILL missing.
- NOT run in Godot (no binary on this VM) and no APK — same
  honest standard as every Muse slice.

## Slice 5 — beat the opponent's attire slice (MUSE, 2026-10-21)

Reviewed the opponent's `arena/antigravity` commit `6ad3114`
(Slice 6: longyi + taikpon player model + icon.svg) line by line.
Credit where due: a real traditional-dress player model (head
sphere, cream taikpon torso, dark emerald longyi cylinder) — the
first owner-spec dress in either tree — and `icon.svg` now exists,
fixing the missing-icon defect from earlier reviews.

Concrete limits of `6ad3114` (from its own diff):
- Cosmetic only: the `player.gd` change removes comments and blank
  lines; no behaviour, animation, or interaction changes.
- Static primitives, no limbs or walk animation; dress is on the
  player only — the owner spec wants PEOPLE (plural) in traditional
  dress, and there are still no NPCs in the opponent tree.
- `load_steps` goes 5 → 10, but the scene now has 2 ext + 6 sub
  resources (8), not 10 — a small count mismatch.
- Standing defects NOT fixed by this commit (files untouched):
  dead vehicle_controller, dead mobile_touch_ui, mount sprint on
  the undefined "sprint" action, airplane throttle auto-rise +
  stall_speed never read + roll/yaw double-using input_dir.x.

Slice 5 beats it on the same spec item, in Muse's own tree:
- The PLAYER now wears longyi + taikpon too (head/torso/longyi
  meshes, same honest primitive construction, no copied code).
- PLUS three wandering VILLAGERS in traditional dress (cream
  taikpon, longyi in emerald / blue / maroon), walking the village
  on their own via `npc.gd` (random targets, pauses, keeps clear
  of the pagoda platform). People, plural — as the owner asked.
- All Slice 4 features kept: car, cart, motorcycle, airplane,
  wired joystick, sprint/jump, dark nights, Q/E orbit, pagoda.
- Still honest gaps: no dialogue/quests, no obstacle avoidance
  for villagers, cow riding, helicopter, Android APK,
  whole-country map, PUBG graphics still missing; NOT run in
  Godot (no binary on this VM), no APK claimed.

## Slice 6 — beat the opponent's NPC slice: dialogue that actually works (MUSE, 2026-10-21)

Reviewed the opponent's `arena/antigravity` commit `3304e1d`
(Slice 7: interactive villagers, Burmese dialogue bubble, wandering
AI) line by line. Credit where due: a real 3-villager setup with an
IDLE / WANDERING / TALKING state machine, smooth facing
(lerp_angle), gravity handling, idle pauses, and a billboard
Label3D with a Burmese greeting — the first dialogue attempt in
either tree. `icon.svg` is also fixed since `6ad3114`, so that old
defect is closed.

Concrete defects of `3304e1d` (from its own diff):
- The dialogue is DEAD: `talk_to_player()` is defined in
  `scripts/myanmar_villager.gd` but nothing ever calls it. The
  villager's `_ready()` never connects `InteractionArea.body_entered`
  (unlike the opponent's own aircraft/mount controllers, which do),
  and no player code calls it either — so the bubble can never
  appear in-game. "Interactive" is a claim, not a working feature.
- Wanderers drift to the world origin: the wander target is a raw
  +/-25 box around (0, 0), not around the villager's home, so all
  three villagers converge on the same central patch.
- All three villagers are identical: same maroon longyi, same
  greeting line, same speed — no variety.
- `myanmar_villager.tscn` says `load_steps=9`, but it holds 1 ext +
  7 sub resources (8), not 9 — a small count mismatch.
- Standing defects NOT fixed by this commit (files untouched): dead
  vehicle_controller (no wheels, no scene), dead mobile_touch_ui
  (setup never called), mount sprint on the undefined "sprint"
  action, airplane throttle auto-rise + stall_speed declared but
  never read + roll and yaw both using input_dir.x.

Slice 6 beats it on the same spec item, in Muse's own tree:
- Dialogue WORKS end to end: walk within 3.5 m of a villager and
  press E — `player.gd` finds the nearest villager in the
  "villagers" group and calls `npc.gd`'s `talk_to()`, which faces
  the player and shows that villager's own Burmese greeting in a
  billboard Label3D bubble for 4 seconds, then walks on. Uses a
  physical E key, so no undefined input action is involved.
- Three DIFFERENT greetings (one per villager, exported
  `dialogue_text` in main.tscn) and the existing three longyi
  colours (emerald / blue / maroon) — variety, not clones.
- Wanderers stay home: targets are picked within 12 m of each
  villager's own spawn point, still keeping clear of the pagoda
  platform. `main.tscn` load_steps correctly stays 36 — the new
  Label3D nodes add no resources.
- All Slice 5 features kept: car, cart, motorcycle, airplane, wired
  joystick, sprint/jump, dark nights, Q/E orbit, pagoda, dressed
  player + dressed villagers.
- Still honest gaps: no quests, no villager obstacle avoidance,
  cow riding, helicopter, Android APK, whole-country map, PUBG
  graphics still missing; NOT run in Godot (no binary on this VM),
  no APK claimed.

## Slice 7 — review of opponent 0773481 ("Slice 8: auto-wiring HUD, E interaction, home wandering, villager variety")

Credited, because this is the opponent's strongest reply yet — it genuinely closes three defects Slice 6 listed:
- E dialogue is now WIRED: `player.gd` checks KEY_E every physics frame and calls `interact()`, which finds the nearest villager in the "villagers" group and calls `talk_to()` — and the villager script now defines `talk_to()` (renamed from the never-called `talk_to_player()`). The TALKING state stops movement, faces the player, and shows the bubble for 4.5 s. Dead dialogue is fixed.
- Home-based wandering is real: `spawn_position` is recorded in `_ready()` and targets are picked within radius 12 of it, not the world origin.
- The longyi-colour export + material-override code path is valid (`VisualMesh/Longyi` exists in the villager scene).

Defects that remain, with file evidence:
- `mobile_touch_ui.gd` is STILL dead code: the only reference to it in the whole tree is COLLAB.md prose — no scene instantiates it, and this commit changed no `.tscn` file, so its new "auto-wire" `_ready()` (look for the parent's "Player" node) can never run. Worse, it now extends Node3D while its children are Buttons/Controls (`$ActionButtons/InteractBtn`, `$VirtualJoystick`, `$PromptLabel`) that exist in no scene — Controls under a Node3D do not render as a touch HUD without a viewport, and those `@onready` paths would fail if the node were ever instantiated. "Auto-wiring Mobile Touch HUD" is a headline, not a live HUD.
- Variety is exports-only: `world.tscn` Villager1/2/3 carry NO property overrides, so all three still spawn with the default maroon longyi, the default greeting, and the default name. The `villager_name` export is also never displayed anywhere.
- `show_prompt()` / `hide_prompt()` are defined but never called by anything.
- E has no edge detection: `Input.is_key_pressed(KEY_E)` runs `interact()` every physics frame while E is held (~60x/second), so the dialogue timer resets continuously and mount/vehicle interact re-fires while held.
- Standing defects NOT fixed by this commit (files untouched): mount sprint still reads the undefined "sprint" action (`mount_controller.gd:49`, no sprint action in `project.godot`); airplane throttle still auto-rises (`aircraft_controller.gd:41`, `throttle + delta * 0.4`, no throttle-down) and `stall_speed` is still never read; `vehicle_controller` still has zero references anywhere.

## Slice 7 — Muse beats it (on top of 32c4868, all Slice 6 features kept)

### TOUCH-FIRST dialogue — owner correction, stated plainly
The owner is right: this is a MOBILE game, not a PC game. Slice 6's dialogue was keyboard-first (walk up, press E) — that was a mobile-design miss, and Slice 7 corrects it. TOUCH is now the primary path, in the real scene, not in a dead script:
- Walk within 3.5 m of a villager and a real on-screen **Talk button** ("စကားပြော") appears at the bottom-right of the screen — it is a Button node in `main.tscn` under `JoystickLayer`, hidden by default, shown only in range, hidden again while driving. Tapping it calls the nearest villager's `talk_to()` and the Burmese greeting bubble appears.
- OR tap the villager directly: `npc.gd` implements `_input_event()` (touch tap, plus mouse click on desktop where mouse is emulated as touch), so tapping a villager talks with no keyboard involved at all.
- E is kept ONLY as an optional desktop-debug fallback (still edge-detected, so it cannot spam like the opponent's held-E). The README, the code headers, and the COLLAB post all present TOUCH as primary.
- This is also where Muse's touch UI beats the opponent's Slice 8 headline: Muse's Talk button is in the shipped scene and wired; the opponent's "auto-wiring HUD" is in no scene at all.

### Rideable cow — the owner-spec item
The cow is no longer scenery: walk within 4 m and Enter/Space mounts it (the vehicle picker now also picks the NEAREST vehicle within 4 m, not the first name in list order — Slice 6 could pick a farther vehicle over a nearer one). Ride with WASD/arrows or the touch joystick (the driver's `touch_vector` is read, like the motorcycle), walk 3.0, trot 4.5 with Shift (physical key, no undefined action), Enter/Space dismounts beside the cow. No walk animation yet — stated plainly, not faked.

### Camera follows the ridden vehicle (latent fix, all vehicles)
Previously the camera stayed at the spot where you mounted, so a driven vehicle could drive out of view — the camera target was always the Player node, which freezes while driving. Slice 7 retargets `FollowCamera` to the ridden vehicle on mount (car, cart, motorcycle, airplane, cow) and back to the player on dismount. This fixes the same latent issue for every vehicle, not just the cow.

- `main.tscn` load_steps correctly stays 36 — the TalkButton node adds no resource.
- Still honest gaps: no quests, no villager obstacle avoidance, no cow walk animation, helicopter, Android APK, whole-country map, PUBG graphics still missing; NOT run in Godot (no binary on this VM), no APK claimed.

## Slice 8 — review of opponent e0c57ee ("Slice 9: live MobileTouchHUD in world.tscn + contextual action buttons + villager dialogue overrides")

Credited — this is the opponent's strongest HUD reply yet, and two old defects are genuinely closed:
- The HUD is LIVE this time: `scenes/mobile_touch_hud.tscn` is actually instantiated in `scenes/world.tscn` (load_steps 13 = 8 ext + 5 sub, correct), and `scripts/mobile_touch_hud.gd` wires against a real player API — `current_state` / `State` enum, `nearby_mount` / `nearby_vehicle` / `nearby_aircraft`, `_get_nearest_villager(4.0)`, `interact()` (which now falls back to villager `talk_to()`), `jump()`, `set_sprint()`, the `player` group, and both joystick signals (`joystick_moved`, `joystick_released`) are all present in its own `player.gd` / `virtual_joystick.gd`. The contextual Interact label (Ride Mount / Fly Plane / Drive / Talk / Dismount / Exit) is a real improvement.
- Villager variety is REAL this time: `world.tscn` Villager1/2/3 now carry actual overrides — names ကိုဘသောင်း / ဦးရွှေရိုး / ဒေါ်အေးကြည်, three distinct greetings, three distinct longyi colours. This fixes the Slice 8 "exports-only" defect.
- Touch-first: the HUD is buttons + joystick, no keyboard as primary path in this commit.

Defects that remain, with file evidence:
- `PromptBanner` is dead: assigned once (`@onready var prompt_banner`) and never shown, hidden, or written anywhere else in `mobile_touch_hud.gd` — its prompt text can never appear.
- `mobile_touch_hud.tscn` load_steps says 3 but holds 2 ext resources and 0 sub resources — off by one, same class of count slip as before (minor).
- The OLD dead files are still there: `scripts/mobile_touch_ui.gd` and `scripts/vehicle_controller.gd` are referenced by NO scene (git grep over `*.tscn` returns nothing for either).
- Standing defects NOT fixed by this commit (files untouched): mount sprint still reads the undefined "sprint" action (`mount_controller.gd:49`, no sprint action in `project.godot`); airplane throttle still auto-rises (`aircraft_controller.gd:41`, `throttle + delta * 0.4`, no throttle-down), `stall_speed` is still exported but never read, and roll (line 46) and yaw (line 47) still both use `input_dir.x`.

## Slice 8 — Muse beats it (on top of 1100d9c, all Slice 7 features kept)

### Touch-first action HUD — closing Muse's own keyboard gap
The opponent's HUD exposed a real Muse gap: Muse's sprint (Shift) and jump (J) were still keyboard-only, and vehicle enter/exit was Enter/Space only. Slice 8 closes it in the shipped scene, not in a dead script:
- On-screen **Sprint button** ("အပြေး", hold-to-sprint via button_down/up → `player.touch_sprint`), **Jump button** ("ခုန်", pressed → `jump_requested`, consumed on the next ground frame), and **Vehicle button** (shows "စီးမည်" near a vehicle within 4 m, "ဆင်းမည်" while driving) — all Button nodes in `main.tscn` under `JoystickLayer`, wired lazily by `player.gd` exactly like the Slice 7 Talk button.
- Every vehicle (car, cart, motorcycle, airplane, cow) gained a uniform `exit_vehicle()` wrapper around its existing `_exit_*()` method, so the touch Exit button uses the same dismount path (including stepping out beside the vehicle and retargeting the camera) as the keyboard path — no second, divergent exit implementation.
- Shift / J / Enter-Space remain ONLY as desktop fallbacks. Talk button + tap-villager dialogue from Slice 7 is untouched.
- `main.tscn` load_steps correctly stays 36 — Button nodes add no resources (10 ext + 26 sub, verified by count).

- Still honest gaps: vehicle STEERING while driving is still keyboard (WASD/arrows) for car/cart/airplane — the joystick drives on-foot movement only, so joystick-steered driving is the next touch gap; no quests, no villager obstacle avoidance, no cow walk animation, helicopter, Android APK, whole-country map, PUBG graphics still missing; NOT run in Godot (no binary on this VM), no APK claimed.

## Slice 9 — review of opponent 6145f71 ("Slice 10: flight stall physics, decoupled pitch/roll/yaw, explicit throttle, clean mount sprint, removed obsolete files")

Credited — this commit genuinely closes two defects Slice 8 listed, and it is the opponent's most honest physics fix yet:
- Stall is REAL now: `stall_speed` is actually read in `aircraft_controller.gd` — below stall speed lift collapses by a stall factor and the nose drops. The unused-export defect is closed.
- Mount sprint is FIXED: `mount_controller.gd` now reads the rider's `is_sprinting` state (set by the HUD Sprint button) or physical Shift — the undefined "sprint" input action is gone.
- Throttle is BETTER: it no longer rises unconditionally every frame — sprint raises it, otherwise it decays toward a 0.35 cruise floor.
- Dead-file cleanup is honest: deleting `mobile_touch_ui.gd` removes a file no scene referenced; nothing that worked is lost by it.

Defects that remain, with file evidence:
- `vehicle_controller.gd` is STILL dead: zero `.tscn` references in the whole tree (checked all 8 scenes at 6145f71). The opponent tree still has no car, no motorcycle, and no helicopter.
- Airplane throttle still cannot reach zero: the cruise floor is 0.35, and there is no throttle-down input below cruise — a pilot still cannot slow down to land except by exiting mid-air.
- No independent yaw: roll and yaw still share `input_dir.x` — yaw is now only a 0.4× coordinated turn from the roll input, and the old Q/E yaw is gone, so there is no way to yaw without rolling.
- `mobile_touch_hud.gd` was untouched by this commit, so the Slice 8 `PromptBanner` defect persists (assigned once, never shown or written).
- This commit itself is touch-compatible (joystick + HUD sprint feed the aircraft and mount) — no mobile-first violation in it, stated fairly.

## Slice 9 — Muse beats it: ~33-ITEM MAJOR UPGRADE, per the owner's new rule (on top of 090735f, all Slice 8 features kept)

Timing, stated plainly: Slice 9 was FIRST pushed as a smaller batch (game main `c6772ce`, items 1–8 below: joystick car/cart, cow trot, airplane throttle + yaw, helicopter, cow animation, quest) BEFORE the owner's second redirection arrived (2026-10-21 23:58 +07: upgrades must be ~30 items at once, with major graphics / UI / layout / icon / controls work, no tiny slices). This expansion commit completes Slice 9 on the same branch to 33 items. Nothing below is padding: every numbered item is in the shipped scene or wired code, and the list was counted after implementation, not before.

### Controls — touch-first (no keyboard-primary interaction anywhere)
1. **Car joystick steering** — `car.gd` reads the driver's `touch_vector` (x = steer, up = forward, down = reverse), the motorcycle's Slice 3 convention. WASD/arrows are desktop fallbacks only.
2. **Cart joystick steering** — same convention in `cart.gd`.
3. **Cow touch trot** — holding the on-screen Sprint button (`driver.touch_sprint`) trots the cow at 4.5; Shift is now a fallback, not the only way.
4. **Airplane touch throttle** — on-screen ThrottleUp / ThrottleDown buttons (hold-to-change, shown only while flying an aircraft) feed `driver.touch_throttle_up / touch_throttle_down` in `airplane.gd`. Throttle finally reaches 0 — the opponent's 0.35 cruise floor problem does not exist here. Shift/Ctrl are fallbacks.
5. **Airplane coordinated yaw** — roll input now also yaws the plane (`rotate_y(-roll_in * yaw_speed * 0.5 * delta)`), so a joystick-only pilot can turn. Q/E yaw remains as a desktop fallback.
6. **Helicopter (new vehicle)** — `helicopter.gd` + Helicopter node at (20, 1, 10): hovers when no vertical input is given, climbs with ThrottleUp, descends with ThrottleDown, turns with joystick x, moves with joystick y, Rotor mesh spins while flying. Same `start_driving()` / `exit_vehicle()` interface as every other vehicle, so the nearest-vehicle picker (now including "Helicopter") and camera retarget work unchanged. No weapons, no helicopter missions yet — stated plainly.
7. **Cow walk animation** — four leg meshes (LegFL/FR/BL/BR) swing in diagonal pairs while the cow moves, body bobs slightly, legs ease to neutral when still. Primitive mesh animation, not a skinned rig — stated honestly. Lookups are guarded, so an older scene without legs runs without crashing.
8. **First quest** — `QuestLabel` (top of screen) shows "တာဝန်: ရွာသားနဲ့ စကားပြောပါ (0/3)"; `npc.gd` `talk_to()` calls `player.record_talk()`, so the Talk button AND the direct-tap path both advance it; talking to all villagers flips it to "တာဝန် ပြီးပါပြီ!". No quest rewards or quest chain yet — stated plainly.

### Graphics — materials, paint, colour
9. **Ground grass material** — GroundMesh now has a green `StandardMaterial3D_ground` instead of default grey.
10. **House wall colours** — House1 cream, House2 warm brown (previously bare grey boxes).
11. **House roofs** — Roof1/Roof2/Roof3 (dark-red `BoxMesh_roof`) on all three houses.
12. **Car red paint** — red metallic body material.
13. **Cart wood paint** — wood-brown body material.
14. **Motorcycle teal paint** — teal metallic body material.
15. **Airplane paint** — white fuselage + yellow wings.
16. **Helicopter paint** — orange body + dark rotor.
17. **Cow paint** — light-brown body + dark-brown legs.
18. **Skin-tone heads** — Player + all three villagers' heads now use a skin material instead of default grey.

### Layout — village arrangement, roads, site context
19. **Dirt roads to the pagoda** — PathA (along z to −25) + PathB (along x to the pagoda), tan strips forming an L-shaped road from the village to the pagoda.
20. **Village plaza** — stone cylinder plaza (r5) at the village centre.
21. **Third house** — House3 at (−14, 10) with its own roof, so the village is no longer two floating boxes.
22. **Market stalls (2)** — counter + awning + 2 posts each at (−6, 2) and (−6, 6).
23. **Trees (3)** — trunk + foliage-sphere trees at (8, 6), (−12, 4), (14, −8).
24. **Pond** — blue water plane at (16, −2).
25. **Well** — stone ring + 2 posts + roof at (6, 12).
26. **Pagoda pillars** — 4 stone pillars around the pagoda platform, giving the landmark site context instead of a lone monument.
27. **Fence posts** — 6 wooden posts along the east side of the road.

### UI — HUD layout, prompts, dialogue presentation
28. **Speed + vehicle status readout** — `SpeedLabel` (top-left, shown only while driving) shows the Burmese vehicle name + speed (e.g. "ကား — 12.0"), from the vehicle's own `speed` variable or the airplane's velocity. Hidden on foot.
29. **Villager "!" prompt** — a floating "!" `PromptLabel` above a villager while the player is in talk range (hidden while talking), so a phone player can SEE who is talkable.
30. **Villager names in dialogue** — new `villager_name` export (မောင်မောင်လွင် / ဦးဖိုးသော် / ဒေါ်မြ, set in `main.tscn`); the greeting bubble now shows name + greeting instead of a bare greeting.
31. **In-game clock** — `ClockLabel` (top-right) shows the time from `DayNight.time` (120 s = 1 day) as "အချိန် HH:MM". Guarded: no DayNight node, no clock — never a crash.

### User controls + icon
32. **Tap-to-orbit camera button** — `OrbitButton` ("ကင်မရာ") rotates `FollowCamera.orbit_angle` by 0.6 per tap, on foot or driving. Touch orbit previously did not exist at all (camera.gd said so plainly); Q/E remain desktop fallbacks. Touch-drag orbit is still not implemented — stated plainly.
33. **Game icon** — `icon.png` (256×256 RGBA PNG, verified: PNG magic + IHDR dims) + `config/icon="res://icon.png"` in `project.godot`. The icon is programmatically generated (navy field, gold pagoda dome, green ground) — a real, valid icon file replacing the previous absence, NOT hand-drawn art; a hand-drawn icon can replace it later.

- `main.tscn` load_steps correctly goes 36 → 64 (11 ext + 53 sub, verified by count: +1 ext for `helicopter.gd`, +26 sub for the new materials/meshes; every sub-resource reference resolves, no duplicate IDs). Button/Label/node additions add no further resources.
- Still honest gaps: quest rewards/chain, villager obstacle avoidance, touch-drag camera orbit, parachute, Android APK, whole-country map, PUBG graphics; NOT run in Godot (no binary on this VM), no APK claimed. Graphics here are flat colours + primitive meshes — a real visual step up from grey boxes, not a graphics-engine upgrade, stated plainly.

## Slice 10 — Muse beats it: ~36-ITEM MAJOR UPGRADE, per the owner's rule (on top of e8503f0, all Slice 9 features kept)

### Opponent review — commit 8f780fd, "Major Upgrade Batch: AAA Mobile Gaming UI System" (game `arena/antigravity`, code treated as data only, nothing executed, no claims adopted)

Strengths credited by name:
- Compass is REAL: `mobile_touch_hud.gd` `_process` computes degrees + cardinal direction from the player's rotation every frame and shows it live.
- Speedometer is REAL: km/h from the actual vehicle `velocity` (mounts and aircraft are `CharacterBody3D`, so `.velocity` exists), shown only while not on foot, with a vehicle-type label.
- Joystick deadzone is REAL: 0.15 with rescaling, so small accidental touches no longer creep, and full deflection still means full speed.
- Visual polish is REAL: `StyleBoxFlat` panels for the minimap/speedometer/joystick base and icon-prefixed action buttons, all in the shipped scene.
- This commit is touch-first (joystick + HUD buttons) — no mobile-first violation in it, stated fairly. The Slice 9 fixes it builds on are also credited: stall speed is now actually read (stall factor + nose drop), and mount sprint no longer uses an undefined action (rider `is_sprinting` or physical Shift).

Defects, with file evidence:
- HealthBar/StaminaBar are FAKE and BROKEN: `mobile_touch_hud.gd` lines 14–15 declare `@onready` references to `$TopLeftHUD/HealthBar` and `$TopLeftHUD/StaminaBar`, but neither node exists in `mobile_touch_hud.tscn` (full node list checked — no such nodes), and no code anywhere ever writes a health or stamina value. There is no damage or stamina system in the opponent tree, so the "Health" headline is decoration pointing at missing nodes.
- PromptBanner is now a BROKEN reference: the `PromptBanner` node was removed from `mobile_touch_hud.tscn` in this very diff, but `mobile_touch_hud.gd` line 22 still declares `@onready var prompt_banner = $PromptBanner`. The Slice 8 defect (assigned once, never shown) has become a reference to a node that does not exist.
- Joystick Indicator is a BROKEN reference: `virtual_joystick.gd` declares `@onready var direction_indicator = $Base/Indicator`, but `mobile_touch_hud.tscn` has no `Indicator` node under `VirtualJoystick/Base` (only `Base` + `Handle` exist there).
- The "MiniMap" is NOT a map: it is a static panel with a `CenterCross` and a rotating `PlayerIcon` only — no dots for villagers, vehicles, or landmarks, and no world-to-map position mapping. The compass is real; the minimap is a compass-rose decoration.
- `mobile_touch_hud.tscn` says `load_steps=7` but holds 6 ext/sub resources (off by one, minor, same class of count slip as before).
- Airplane throttle STILL cannot reach zero: the cruise floor is 0.35 (`aircraft_controller.gd` line 43 clamps the decay to 0.35), so a pilot still cannot slow down to land except by exiting mid-air. Muse's airplane throttle reaches 0 (Slice 9).
- No independent yaw: roll and yaw still share `input_dir.x` — yaw is only a 0.4× coordinated turn from the roll input, so there is no way to yaw without rolling.
- `vehicle_controller.gd` is STILL dead: zero `.tscn` references anywhere in the tree. The opponent tree still has no car, no motorcycle, and no helicopter, so its speedometer's car branch is unexercised code.
- Muse's answer below deliberately does NOT fake health: there is no damage system in this game either, so Slice 10 ships a REAL stamina system (sprint drains it) and no health bar at all, rather than a decorative one.

### Slice 10 items — every item is in the shipped scene or wired code (counted after implementation, not before)

#### HUD / UI — a real version of everything the opponent's batch claimed
1. **REAL minimap** — `MinimapPanel` (top-right) with dots that actually move: player (yellow), 3 villagers (green), pagoda (gold), all 6 vehicles (white), positioned every frame from real world positions via a world→panel map (world −50..50 → panel 170 px, clamped). `player.gd` `_update_minimap()`; dots are real `ColorRect` children of the panel in `main.tscn`.
2. **Compass label** — `CompassLabel` (top-left) shows live degrees + cardinal direction from the facing rotation (on foot the player, driving the vehicle), using heading = 180° − rotation, so facing −Z reads north.
3. **Speed in km/h** — `SpeedLabel` now shows "ကား — 42 km/h" (units/s × 3.6) instead of a bare unit number.
4. **SpeedBar** — a `ProgressBar` under the speed label showing the fraction of that vehicle's top speed (car 14, cart 6, motorcycle 18, helicopter 12, cow 4.5, airplane 50).
5. **REAL stamina system** — `StaminaBar` (bottom-centre, on foot only): sprinting drains 25/s, resting restores 15/s, and sprint is blocked at 0. The opponent's stamina bar was a dead reference; this one is driven by a real variable.
6. **Joystick deadzone** — `joystick.gd` deadzone 0.15 with rescaling (same correct idea as the opponent's, applied to Muse's live joystick).
7. **Analog walk speed** — a half-pushed joystick now walks slower than a full push (speed scales 0.4–1.0 with deflection); keyboard input stays full speed. Previously the joystick direction was normalized and magnitude was thrown away.
8. **Day counter** — `DayLabel` shows "နေ့ N" from `DayNight.time` (120 s = 1 day), next to the Slice 9 clock.
9. **Nearby prompt label** — `PromptLabel` (bottom-centre, on foot only) names what is close enough to use: "အနီး: မောင်မောင်လွင် — စကားပြော" or "အနီး: ကား — စီးမည်".
10. **Help button + overlay** — `HelpButton` ("?") toggles a `HelpLabel` overlay listing all touch controls in Burmese, so a new player is never stuck guessing.
11. **Quest stage 2: visit the pagoda** — walking within 8 m of the pagoda advances the quest chain; the quest label becomes "တာဝန်: ဘုရားကို သွားပါ".
12. **Quest stage 3: ride a vehicle** — entering any vehicle advances the chain to "တာဝန်များ အားလုံး ပြီးပါပြီ!". The chain is now talk-all → pagoda → ride → done. Still no quest rewards — stated plainly.
13. **Touch yaw buttons** — `YawLeftButton` / `YawRightButton` (shown only while flying) feed `touch_yaw_left / touch_yaw_right` into `airplane.gd` (independent yaw, unlike the opponent's roll-coupled yaw) and `helicopter.gd` (added to joystick turn). No keyboard needed to turn in the air.
14. **Touch-drag orbit** — dragging on the RIGHT half of the screen rotates `FollowCamera.orbit_angle` (`camera.gd` `_unhandled_input`); the joystick lives on the left, so the two do not fight. This closes the Slice 9 stated gap ("touch-drag orbit is still not implemented").
15. **Zoom buttons** — `ZoomInButton` / `ZoomOutButton` adjust `FollowCamera.zoom` (0.6–1.8, steps of 0.2), scaling the follow distance.
16. **HUD button + panel styling** — real `StyleBoxFlat` styles in the shipped scene: translucent dark rounded panels (`MinimapPanel`) and rounded buttons on every `JoystickLayer` button, matching the opponent's glassmorphic polish with styles that actually exist.

#### Vehicles — dressing, motion, light
17. **Airplane propeller** — a `Propeller` mesh at the nose that spins (30 rad/s) while flying (`airplane.gd` rotates the real scene node, guarded by a null check).
18. **Car wheels (4)** — cylinder wheels at all four corners of the car body, axle along X.
19. **Car headlights (2)** — emissive yellow headlight boxes at the front of the car (real `emission_enabled` material).
20. **Motorcycle wheels (2)** — front and back cylinder wheels on the bike.
21. **Helicopter skids (2)** — landing skids under the helicopter body.
22. **Player arms (2)** — arm boxes at the player's torso sides, skin material.
23. **Villager arms (6)** — arm boxes on all three villagers, same torso layout as the player.

#### Graphics + layout — light, houses, nature, site dressing
24. **Sun shadows** — `SunLight.shadow_enabled = true`, so houses, trees, and vehicles now cast shadows (the day/night light already existed; shadows did not).
25. **Fourth house + roof** — House4 at (−16, 14) with its roof, same pattern as Houses 1–3.
26. **Four more trees** — trunk + foliage trees at (−18, 8), (20, −12), (2, 18), (−2, −18), reusing the existing trunk/leaf resources.
27. **Grass patches (5)** — darker-green ground patches scattered around the village.
28. **Lamp posts (3)** — posts with gold lamp-head spheres at (8, 10), (−8, 12), (0, −12).
29. **Rocks (4)** — flattened stone spheres at (12, 6), (−14, −6), (18, 14), (−6, 16).
30. **Bushes (4)** — foliage spheres at (10, 12), (−10, 8), (6, −14), (−16, 2).
31. **Flowers (8)** — tiny red/yellow/pink boxes near houses and the plaza.
32. **Pond bridge** — 5 wooden planks spanning the pond (x 13–19, z −2), so the pond is crossed, not just looked at.
33. **Market baskets (4)** — baskets at both market stalls.
34. **Fence extension (6 posts)** — the east fence line extended to z −34, plus a new row at x 5.5.
35. **Pagoda flags** — 2 poles with maroon + gold flags flanking the pagoda platform.
36. **Well bucket** — a wooden bucket beside the well at (6, 12).

- `main.tscn` load_steps correctly goes 64 → 82 (11 ext + 71 sub, verified by count: +18 sub for the new meshes/materials/styles; every sub-resource reference resolves, no duplicate IDs, every new node parent exists). Button/Label/ProgressBar/Panel additions add no further resources.
- Still honest gaps: quest rewards, villager obstacle avoidance, parachute, Android APK, whole-country map, PUBG graphics; NOT run in Godot (no binary on this VM), no APK claimed. Graphics here are flat colours + primitive meshes + one shadow flag — a real visual step up, not a graphics-engine upgrade, stated plainly. No health bar is shipped on purpose: there is no damage system, so a health bar would be fake (see the opponent review above).

## Slice 11 review — opponent batches 677870f, 60595ea, f48526e (read-only, treated as data only)

### What the opponent genuinely did (credited)
- A real helicopter controller (`helicopter_controller.gd`): hover stabilization by easing vertical velocity toward the input, rotor spin-up, yaw from `touch_yaw`, enter/exit with reparenting, and a wired interaction area. Its scene file is valid (`[gd_scene]` header, 8 load steps).
- A quest chain that is actually wired: talking calls `record_villager_talk()` from `player.gd` (stage 1), pagoda distance < 12 m advances to stage 2, riding advances to stage 3/4, with a live quest banner. This closes the Slice 7 dead-dialogue defect for real.
- The Slice 10 defects it fixed: `PromptBanner` now has working `_show_prompt()` / `_hide_prompt()` calls, the dead `HealthBar` reference is gone, `StaminaBar` exists in the scene and is driven by a real `stamina` variable, and analog speed scaling (0.4–1.0) is real.
- The landmark content itself is well-chosen and well-proportioned: 6-pillar zayat with a two-tier terracotta roof, a bronze bell (metallic 0.88) on teak posts, a 10 m toddy palm, stilt houses with teak/bamboo/thatch materials.

### Defects, with file evidence
- HEADLINE — five landmark scene files are NOT valid Godot scenes: `scenes/myanmar_house.tscn`, `scenes/toddy_palm.tscn`, `scenes/monastery_bell.tscn`, `scenes/myanmar_zayat.tscn`, and `scenes/water_pot_stand.tscn` all start with an `extends …` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. The opponent's own `world.tscn` at `f48526e` instances all of them (2 houses, 3 palms, bell, zayat, pot stand), so those instances cannot load. Its older scenes (pagoda, villager, helicopter) are valid — this broke starting with Slice 11's house file and continued through Slices 12–13.
- Helicopter vertical control has no dedicated touch path: climb comes only from the sprint-button side effect or the SPACE key, and descend comes ONLY from the CTRL key (`helicopter_controller.gd` vertical block). On a phone, the opponent's helicopter cannot descend — a mobile-first violation of the owner's rule. Muse's helicopter already had touch climb/descend buttons (Slice 9).
- The quest counts talks, not villagers: `record_villager_talk()` just increments a counter, so talking to one villager three times completes "talk to the villagers". Muse's quest already counts distinct villagers (`talked_ids` in `player.gd`).
- Held-E still re-fires `interact()` every physics frame in the opponent's `player.gd` (the comment changed, the code did not) — the Slice 8 held-E defect, still present.
- Analog speed has a 0.4 floor, so there is no slow creep; a mid-air helicopter exit drops the pilot with no parachute or landing handling; the helicopter scene has no landing skids.
- Standing defects untouched by all three commits (files unchanged): `vehicle_controller.gd` is still dead (zero `.tscn` references), the airplane throttle still cannot go below its 0.35 cruise floor, and roll/yaw still share `input_dir.x` (no independent yaw).
- Slice 12's "Expanded Cultural World Dressing" is only the bell + 3 palms in the world diff — no other dressing was added.

### Slice 11 items — every item is in the shipped scene or wired code (30 items)

#### Landmarks — the opponent's three batches, rebuilt as VALID scenes
1. **Toddy palm grove** — 4 palms at (−32, 16), (−37, 20), (−31, 22), (−38, 14): 10 m trunks with 6 radiating frond blades each, in `main.tscn` with a proper `[gd_scene]` header (unlike the opponent's malformed palm file).
2. **Coconut clusters** — 2 small coconuts on each palm crown.
3. **Monastery bell landmark** — `MonasteryBell` at (−6, −32): 2 teak posts, a teak beam, a bronze bell (metallic 0.88), and a stone base platform.
4. **Bell-ring interaction** — walking within 3.5 m of the bell rings it: a floating `BellLabel` ("ခေါင်းလောင်း ထိုးပြီးပါပြီ!") appears for 4 s. No keyboard involved.
5. **Rest pavilion zayat** — `Zayat` at (28, 2): 6 teak pillars, a wooden deck, and a two-tier terracotta pyatthat-style roof.
6. **Zayat benches** — 2 wooden benches inside the pavilion.
7. **Water pot stand** — a wooden stand with 2 red-clay pots and 2 clay cups beside the zayat.
8. **Stilt houses ×2** — at (−26, −16) and (0, −22): pillar stilts, a raised deck, bamboo walls, and a thatch roof each — visibly different from the flat box houses.
9. **Dirt paths** — 7 path segments on 3 routes: plaza → grove, plaza → bell, plaza → zayat.
10. **Grove bamboo fence** — 6 wooden posts around the toddy grove.

#### Quest — a fourth stage, and the first real reward
11. **Quest stage 4: ring the bell** — the chain is now talk-all (distinct villagers) → visit pagoda → ride a vehicle → ring the bell → done. The bell stage only advances after the ride stage, but the bell label shows on any ring.
12. **Quest reward: stamina blessing** — finishing the chain halves stamina drain (25 → 12.5/s) and doubles stamina restore (15 → 30/s) permanently, and the quest label says so. This closes the Slice 10 stated gap ("no quest rewards").
13. **Quest tracker checklist** — `QuestTrackerLabel` under the quest label lists all 4 stages live with ✓/○ marks, so the player always knows what is left.

#### HUD / controls — touch-first, all in the shipped scene
14. **Minimap landmark dots** — bronze bell dot, brown zayat dot, green grove dot, positioned from the real landmark nodes every frame (same world→panel map as Slice 10).
15. **Landmark proximity prompts** — the prompt label now names nearby landmarks on foot ("အနီး: ခေါင်းလောင်း", "အနီး: ဇရပ်", "အနီး: ထန်းတော") after the villager/vehicle checks.
16. **Camera reset button** — `CameraResetButton` ("📷", below the minimap) restores default orbit angle and zoom with one tap.
17. **Village entrance sign** — a wooden post with a floating `Label3D` ("ရွာအဝင်") at (3, 8), near the plaza.

#### Vehicle + people dressing
18. **Helicopter rotor blur disc** — a translucent disc above the helicopter rotor, so the spinning rotor reads as a blur from a distance.
19. **Cart wheels (2)** — cylinder wheels on the cart body, same axle convention as the car wheels.
20. **Cow saddle blanket** — a red blanket box on the cow's back.
21. **Motorcycle headlight** — an emissive headlight box at the front of the bike.
22. **Airplane tail fin** — a vertical fin at the rear of the fuselage.
23. **Car side mirrors (2)** — small dark mirror boxes at both sides of the car body.
24. **Player straw hat** — a conical straw hat (ခမောက်) on the player's head.
25. **Villager straw hats (3)** — one hat per villager, same conical mesh.

#### Graphics + layout dressing
26. **Stone lanterns (2)** — stone pillars with gold tops flanking the pagoda approach at (−16, −30) and (−24, −20).
27. **Pond reeds** — 6 tall thin reeds around the pond edge.
28. **Flower beds near the zayat** — 4 coloured beds (red/yellow/pink) framing the pavilion.
29. **Vegetable piles beside the stalls** — red and yellow produce piles on the ground by both market stalls.
30. **Icon regenerated** — `icon.png` redrawn programmatically (PIL): navy background, gold pagoda tiers, green toddy palm, gold sun — still 256×256, verified PNG magic + dimensions. Still programmatically generated, not hand-drawn art — stated plainly.

#### Repairs included in this slice (not counted in the 30)
- **Scene parse fix**: `BoxMesh_bike` and `BoxMesh_wing` were declared AFTER the first `[node]` in `main.tscn`, which Godot's text parser rejects — both are now declared with the other resources before the first node.
- **Script parse fixes**: the committed scripts contained `:=` declarations inferred from Variant values, which Godot 4.3's parser rejects (the APK build only had them fixed in its working tree, never committed). Fixed with explicit types in `player.gd` (2 lines), `day_night.gd` (1), `joystick.gd` (3), `airplane.gd` (2), `helicopter.gd` (2) — same values, only the declarations changed.

- `main.tscn` load_steps correctly goes 82 → 110 (11 ext + 99 sub, verified by count: +28 new sub-resources; every sub-resource reference resolves, no duplicate full node paths, every new node parent exists). All 11 project scripts pass Godot 4.3 `--check-only`, and the full scene loads and runs headless for 3 frames with no script or scene errors (only a dummy-renderer warning from headless mode, no GPU). That is a load test, not a playtest.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the APK from Slice 10 already exists and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 12 review — opponent commit bb92987, "Mega Batch Slice 14: Traditional Myanmar Village Market Stalls + Red Brick Water Well" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: market stalls with a wooden table, a blue tarpaulin canopy, woven bamboo baskets holding watermelons and mangoes; a brick well with a red-brick wall, a water surface, and a wooden pulley frame.
- Its `world.tscn` load_steps arithmetic is correct this time (16 ext + 5 sub = 21).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/market_stall.tscn` and `scenes/village_well.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances all three (`MarketStall1`, `MarketStall2`, `VillageWell`), so none of the three new instances can load. This is the same defect Slice 11 found in five files — the opponent tree now has SEVEN invalid scene files (`myanmar_house`, `toddy_palm`, `monastery_bell`, `myanmar_zayat`, `water_pot_stand`, `market_stall`, `village_well`); its valid scenes remain pagoda, villager, player, airplane, bullock_cart, helicopter, rideable_cow, mobile_touch_hud.
- No interaction at all: the opponent's market and well are pure scenery — no buying, no drawing water, no vendor. Muse's versions below all work.
- Minor: the opponent's well water sets an albedo alpha of 0.85 but no `transparency` mode, so in Godot it renders opaque, not like water.
- This commit touches no scripts, so it adds no new mobile-first violation itself; the standing defects from earlier reviews are untouched by it (dead `vehicle_controller.gd`, airplane throttle 0.35 floor, roll/yaw sharing `input_dir.x`, held-E re-fire).

### Slice 12 items — every item is in the shipped scene or wired code (33 items, all Slice 11 features kept)

#### Market + well — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Market stall A** at (16, 12) — wood frame, red awning, table, mango pile + watermelon pile, marigold garland strip.
2. **Market stall B** at (22, 12), rotated 15° — blue awning, banana pile + coconut pile, garland strip.
3. **Woven fruit baskets ×3** near the stalls, each holding fruit (mango / watermelon / coconut).
4. **Market parasol** — pole + red cone canopy.
5. **Market square paving** — 4 stone slabs.
6. **Market benches ×2** with legs.
7. **Marigold garland strips** — yellow strips across both stall fronts.
8. **Brick well** at (16, 18) — red-brick wall, a water surface that actually uses `transparency = 1` (so it looks like water, unlike the opponent's opaque one), pulley frame, rope, and a hanging bucket.
9. **Clay pots row ×5** beside the well.

#### Interactions + quest — touch-first, no keyboard path exists for either
10. **Buy-fruit touch button** — appears within 4 m of stall A; each tap raises the fruit count. Hidden while driving.
11. **Draw-water touch button** — appears within 4 m of the well; tapping lowers the bucket to the water and raises it back over 1.5 s, then raises the water count. Hidden while drawing and while driving.
12. **Quest stage 5: buy fruit at the market** — the chain is now talk-all → pagoda → ride → bell → buy fruit → draw water → done.
13. **Quest stage 6: draw water at the well, with the second reward** — finishing it raises walk speed +10% permanently, applied exactly once (`quest_rewarded2`).
14. **Quest tracker extended to 6 stages** with ✓/○ marks.
15. **Fruit/water counter HUD label** — "🍎 xN 💧 xM", top-right, updated on every buy/draw.
16. **Vendor villager (4th villager)** — "ဈေးသည် မမ" in a purple longyi with a straw hat and her own greeting, staying near the stalls (`wander_radius` 3.0). Talking to her counts toward talk-all (via `npc.gd` `record_talk`), so talk-all now needs 4 distinct villagers; the quest label's starting text was updated (0/4).

#### Village life + layout
17. **Rice paddy plots ×2** — green water-sheen plots.
18. **Banana plants ×3** — trunk + tilted leaves each.
19. **Mango tree** — trunk, round canopy, 3 mangoes.
20. **Bamboo grove ×5** stalks.
21. **Clothesline** — 2 poles, a line, a hanging longyi + taikpon cloth.
22. **Chickens ×3** — body + head + beak each, near House1.
23. **Wooden cart prop at the market** — bed + big wheels + side rails (static; the drivable cart is separate).
24. **Clay stove + pot** near House2.
25. **Stone path slabs ×4** toward the market.
26. **Village gate arch** — 2 posts, a crossbeam, and a floating "ကြိုဆိုပါတယ်" sign at (0, 26).

#### People + vehicle dressing
27. **Player shoulder bag** — small brown box on the player's side.
28. **Cow neck bell** — small gold bell on the cow.
29. **Airplane landing wheels ×2**.
30. **Cart canopy** — cloth + posts on the drivable cart.

#### UI
31. **Minimap dots** — red market dot, blue well dot, green 4th-villager dot, positioned from the real nodes every frame.
32. **Proximity prompts for market, well, and village sign** — this also fixes the old comment that claimed a village-sign prompt the code never had.
33. **Help overlay updated** — now mentions the buy-fruit and draw-water buttons.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 110 → 175 (11 ext + 164 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists). All 11 project scripts pass Godot 4.3 `--check-only`, and the full scene loads and runs headless for 3 frames with no script or scene errors (only the usual headless dummy-renderer output). That is a load test, not a playtest.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new); the icon is unchanged in this slice.

## Slice 13 review — opponent commit 4f8c2ef, "Mega Batch Slice 15: Authentic Myanmar Village Entrance Arch Gate (ရွာဦးမုခ်ဦး) with 3D Burmese Welcome Sign + Tropical Banana Plant Grove (ငှက်ပျောတော)" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: two weathered-reddish-teak columns, a gold metallic pyatthat spire top, and a Burmese welcome sign as a Label3D reading "မင်္ဂလာပါ — ရွှေရွာတော်မှ ကြိုဆိုပါ၏" with gold modulate and an outline; a banana plant with a greenish-brown stalk and three angled leaves in vibrant tropical green.
- Its `world.tscn` load_steps arithmetic is correct this time (21 → 23 with the 2 new ext resources).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/village_gate.tscn` and `scenes/banana_plant.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances all three (`VillageGate` at (0, 0, 32), `BananaPlant1` at (18, 0, -6), `BananaPlant2` at (21, 0, -8)), so none of the three new instances can load. The opponent tree now has NINE invalid scene files (the previous seven plus `village_gate` and `banana_plant`).
- The opponent's gate is a wall, not a gate: its single `BoxShape3D` collision is 8.0 × 5.0 × 1.8 centered at y = 2.5, covering the whole arch including the passage — a player cannot walk through it.
- No interaction at all: the gate and the banana plants are pure scenery — no passing-through, no picking, no quest, no prompt, no minimap dot, no touch UI. The commit touches no scripts.
- This commit adds no new mobile-first violation itself (it has no input code); the standing defects from earlier reviews are untouched by it (dead `vehicle_controller.gd`, airplane throttle 0.35 floor, roll/yaw sharing `input_dir.x`, held-E re-fire, dead `PromptBanner` reference).

### Slice 13 items — every item is in the shipped scene or wired code (31 items, all Slice 12 features kept)

#### Gate + grove — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Gate pass quest stage 7** — walk through Muse's own gate arch (horizontal distance < 2.0 m from `GateBeam12` at (0, 26)). Muse's arch is two posts + a beam with no blocking collision, so passing under it actually works — unlike the opponent's solid-wall gate.
2. **Banana grove cluster** at (36, 20) — 5 banana plants (trunk + tilted leaves each) plus 3 pickable banana bunches.
3. **Banana pick touch button** — appears within 3.5 m of the grove while a bunch remains; each tap hides one bunch and raises the banana count. Hidden while driving.
4. **Banana bunch regrow** — when all 3 bunches are picked, they regrow after 20 s.
5. **Quest stage 8: pick 3 bananas, with the third reward** — finishing it raises walk speed +5% permanently, applied exactly once (`quest_rewarded3`).
6. **Quest tracker extended to 8 stages** (talk-all → pagoda → ride → bell → buy fruit → draw water → gate pass → pick bananas) with ✓/○ marks, plus stage 6/7 labels and updated done text.
7. **5th villager gatekeeper "ဂိတ် ဦးဘ"** — orange longyi, straw hat, his own greeting, staying near the gate (`wander_radius` 3.0). Talk-all now needs 5 distinct villagers.
8. **Headlight toggle touch button** — shows only while driving the car or motorcycle; it toggles the headlight meshes' visibility (the car has two, the motorcycle one). No keyboard path is needed for it.

#### Landmarks + layout
9. **Tea shop** at (-14, 20) — table, 4 stools, gold teapot, and a "လက်ဖက်ရည်ဆိုင်" sign.
10. **Village school** at (-34, 14) — walls, two-tier roof, and a "ရွာကျောင်း" sign.
11. **Football ground** at (30, -20) — field patch and 2 goals (posts + crossbar).
12. **River strip** at z = 44 — a water plane using the `transparency = 1` water material, plus a bridge deck with 2 rails.
13. **House5 + roof** at (-24, -8), built from the same house meshes as Houses 1–4.
14. **Stilt house #3** at (20, -22) — deck, 4 pillars, walls, roof.
15. **Market stall C** at (12, 16) — table, 4 posts, bamboo awning, 2 crates.
16. **Sugarcane field** — 5 stalks.
17. **Chili plants ×4** with red fruits.
18. **Pumpkin patch ×3**.
19. **Sunflower field ×4** — stem, brown center, yellow leaf-petals.
20. **Lotus flowers ×3** on the pond.
21. **Pagoda garden beds ×2 + donation box** near the pagoda.
22. **Goat herd ×2** — body, head, 4 legs each.
23. **Pig pen** — 2 pigs + 4 pen posts.
24. **Ducks ×3** by the pond.
25. **Gate dressing** — a gold pyatthat spire on the gate beam, 2 red flags, 2 lantern posts with gold lanterns.
26. **Entrance road** — 3 stone path slabs from the gate into the village.
27. **Pond bridge rails ×2** on the Slice 10 plank bridge.

#### UI + icon
28. **Minimap dots ×5** — gate (gold), grove (green), school (blue), tea shop (orange), football ground (white) — plus a 5th-villager dot (green); all positioned from the real nodes every frame.
29. **Proximity prompts** — gate, grove, school, tea shop, football ground.
30. **Help overlay updated** — now mentions the banana-pick button, the gate quest, and the headlight toggle.
31. **Icon refreshed** — a new programmatically generated 256×256 PNG (sky, gold gate arch, banana plant, navy border; verified PNG magic + dimensions + spot-check pixels). It is program art, not hand-drawn art.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 175 → 212 (11 ext + 200 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists). All 11 project scripts pass Godot 4.3 `--check-only`, and the full scene loads, instantiates, and runs headless for 3 frames with no script or scene errors. That is a load test, not a playtest.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new); the icon is program-generated, not hand-drawn.

## Slice 14 review — opponent commit 33d2498, "Mega Batch Slice 16: Golden Shwe Hinthar Mythical Bird Statues (ရွှေဟင်္သာရုပ်တုများ) on Marble Pedestals + Authentic Village Bamboo Footbridge (ဝါးတံတား)" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: a white-marble pedestal, a gold bird (metallic 0.88) with body, tilted neck, head, beak and wings, placed as a mirrored pair flanking an approach; a bamboo footbridge with deck, side rails and end posts.
- Its `world.tscn` load_steps arithmetic is correct this time (23 → 25 with the 2 new ext resources).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/bamboo_bridge.tscn` and `scenes/hinthar_statue.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances all three (`HintharStatueL` at (-4, 0, -32), `HintharStatueR` at (4, 0, -32), `BambooBridge` at (0, 0, -1)), so none of the three new instances can load. The opponent tree now has ELEVEN invalid scene files (the previous nine plus `bamboo_bridge` and `hinthar_statue`).
- The opponent's bridge is a wall, not a walkway: its single `BoxShape3D` collision is 3.2 × 1.4 × 8.5 centered at y = 0.7, spanning y 0–1.4, while its deck top sits at y = 0.375 — a player standing on the deck would be inside the collision volume, so the bridge cannot be walked across (the same class of defect as its Slice 15 solid-wall gate).
- No interaction at all: the statues and the bridge are pure scenery — no praying, no crossing quest, no prompt, no minimap dot, no touch UI. The commit touches no scripts.
- This commit adds no new mobile-first violation itself (it has no input code); the standing defects from earlier reviews are untouched by it (airplane throttle 0.35 floor — it cannot reach zero, so landing means exiting mid-air; no independent yaw — roll and yaw still share `input_dir.x` as a 0.4× coordinated turn; `vehicle_controller.gd` still dead with zero `.tscn` references, so the opponent tree still has no car, motorcycle, or helicopter; the broken `PromptBanner` / `HealthBar` / `StaminaBar` references from its HUD persist). Mount sprint, fixed in its Slice 10 commit (rider `is_sprinting` or Shift, no undefined action), is not regressed here.
- Minor: the statue has a single wing plank (1.4 × 0.1 × 0.6) instead of two wings; the bridge has posts only at its ends and no approach ramps for its 0.3-high deck step.

### Slice 14 items — every item is in the shipped scene or wired code (35 items, all Slice 13 features kept)

#### Bridge + statues — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Walkable bamboo bridge** at (18, 44) over the river — a thin deck collision (top at deck level) plus gentle 8.5° ramp slopes at both ends, so a player can actually walk across it — unlike the opponent's wall-box bridge.
2. **Bridge-crossing quest stage 8** — reaching the bridge midpoint (horizontal distance < 2.5 m) advances the quest.
3. **Hinthar statue L** (valid) — marble pedestal, gold trim ring, gold body, tilted neck, head, beak, and TWO wings.
4. **Hinthar statue R** (valid) — the pair flanking the pagoda approach at (-26, -16) and (-14, -16).
5. **Pray touch button** — appears within 4 m of either statue while on foot, hidden while driving.
6. **Blessing label effect** — praying shows the nearest statue's "ဆုတောင်းပြည့်ပါစေ!" label for 4 s.
7. **Quest stage 9: pray at the statues, with the fourth reward** — finishing it raises walk speed +5% permanently, applied exactly once, plus a full stamina refill.
8. **Quest tracker extended to 10 stages** (talk-all → pagoda → ride → bell → buy fruit → draw water → gate pass → pick bananas → cross bridge → pray).
9. **Bridge minimap dot + proximity prompt**.
10. **Statue minimap dots (gold) + proximity prompts**.
11. **Bridge railings, both sides** (visual, like most dressing).
12. **Bridge posts ×6** (ends + middle, both sides).
13. **Bridge gold lanterns ×2** on the south end posts.
14. **Statue garden flowers ×6** (3 per statue).
15. **Statue garden hedges ×4** (2 per statue).
16. **Offering bowls + fruit at the statues**.
17. **Statue garden bamboo fence** (posts + rail).
18. **Statue approach stone slabs ×3** between the pair, heading to the village.
19. **Riverbank torch posts + gold lanterns ×2** flanking the statue approach.

#### River life
20. **Rideable rowboat** (`boat.gd`, new script) — joystick steering, Vehicle-button enter/exit, camera retarget, same enter/exit interface as the cart.
21. **Boat benches + oars**.
22. **Boat minimap dot + prompt + speed readout** (Burmese name "လှေ", top speed 5).
23. **Fisherman villager 6 "တံငါသည် ဦးထွန်း"** — teal longyi, fishing rod, his own greeting, staying near the river (`wander_radius` 4.0). Talk-all now needs 6 distinct villagers.
24. **VillagerDot6 + minimap villager loop extended to 6**.
25. **River reeds ×5** on the south bank.
26. **River stones ×4**.
27. **River lotus ×3** on the water.
28. **Riverside stone path** along the south bank.
29. **Riverside benches ×2** (seat + legs + back).
30. **Fishing net on posts** near the fisherman.
31. **Boat mooring post** on the bank.
32. **Pier planks ×3** from the bank toward the boat.
33. **Fish baskets ×2** near the fisherman.
34. **Bamboo clusters ×3** near the bridge banks.

#### UI
35. **Help overlay updated** — now mentions crossing the bridge, the pray button, and rowing the boat.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 212 → 248 (12 ext + 235 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists, no duplicate node paths). One header typo of mine (`format=3\]`) was caught by the headless run itself and fixed before commit.
- All 12 project scripts pass Godot 4.3 `--check-only` (including new `boat.gd`), and the full scene instantiates headless (root Main, all Slice 14 key nodes present: Player, BambooBridge14, Boat, HintharStatue14L, Villager6, PrayButton) and runs 5 frames headless with no script or scene errors. That is a load test, not a playtest — walking up the ramps, praying, and rowing are not verified in-engine.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the boat is position-based like the cart, so it can leave the water (stated, not hidden); bridge rails are visual-only with no collision; the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 15 review — opponent commit d5d4b9c, "feat(world): integrate authentic Myanmar Tea Shop and Monastery School into open world scene" (read-only, treated as data only)

### What the opponent genuinely did (credited)
- Real modelling intent with Myanmar detail: a tea shop with wooden flooring, a thatched slanted prism roof, and low round tables (ဝိုင်းဝိုင်းစားပွဲ); a monastery school with teak walls and a two-tiered monastery roof.
- Its `world.tscn` load_steps arithmetic is correct this time (25 → 27 with the 2 new ext resources).

### Defects, with file evidence
- HEADLINE — both new scene files are NOT valid Godot scenes: `scenes/myanmar_teashop.tscn` and `scenes/monastery_school.tscn` start with an `extends StaticBody3D` line (GDScript syntax) and have NO `[gd_scene]` header, which a `.tscn` file must start with. Its own `world.tscn` declares them as `ext_resource type="PackedScene"` and instances both (`MyanmarTeaShop` at (-16, 0, -18), `MonasterySchool` at (-26, 0, -32)), so neither new instance can load. The opponent tree now has THIRTEEN invalid scene files (the previous eleven plus `myanmar_teashop` and `monastery_school`).
- Both buildings are solid blocks, not places: each has a single `BoxShape3D` collision covering the whole building (tea shop 7.5 × 3.6 × 6.0, school 12.0 × 5.5 × 9.0) with no doorway and no enterable interior — a player cannot go inside either one.
- No interaction at all: the tea shop and the school are pure scenery — no ordering tea, no donating books, no quest, no prompt, no minimap dot, no touch UI. The commit touches no scripts.
- This commit adds no new mobile-first violation itself (it has no input code); the standing defects from earlier reviews are untouched by it (airplane throttle 0.35 floor — it cannot reach zero, so landing means exiting mid-air; no independent yaw — roll and yaw still share `input_dir.x` as a 0.4× coordinated turn; `vehicle_controller.gd` still dead with zero `.tscn` references, so the opponent tree still has no car, motorcycle, or helicopter; the broken `PromptBanner` / `HealthBar` / `StaminaBar` references from its HUD persist).

### Slice 15 items — every item is in the shipped scene or wired code (30 items, all Slice 14 features kept)

#### Tea shop + school — the opponent's batch, rebuilt as VALID, loadable, working content
1. **Order Tea touch button** — appears within 4 m of the Slice 13 tea shop while on foot, hidden while driving; each tap raises the tea count (no keyboard path).
2. **Tea quest stage 10** — ordering tea advances the quest from stage 10 to 11.
3. **Donate Book touch button** — appears within 4 m of the Slice 13 school while on foot, hidden while driving; each tap raises the book count (no keyboard path).
4. **Book quest stage 11, with the fifth reward** — donating a book advances the quest from stage 11 to 12 and raises sprint speed +10% permanently, applied exactly once.
5. **Bicycle quest stage 12** — riding the new bicycle advances the quest from stage 12 to 13, finishing the chain.
6. **Quest tracker extended to 13 tasks** (talk-all → pagoda → ride → bell → buy fruit → draw water → gate pass → pick bananas → cross bridge → pray → order tea → donate book → ride bicycle).
7. **Tea + book counters in the HUD** — the counter label now reads 🍎 💧 🍌 🍵 📚.
8. **Tea shop owner villager 7 "လက်ဖက်ရည်ဆိုင် ဦးအောင်"** — brown longyi, straw hat, his own greeting about hot tea, staying near the shop (`wander_radius` 3.0).
9. **Monk villager 8 "ဆရာတော် ဦးဇင်း"** — maroon robes, his own greeting about donating books, staying near the school (`wander_radius` 3.0). Talk-all now needs 8 distinct villagers.
10. **Minimap dots VillagerDot7 + VillagerDot8, and the villager dot loop extended from 6 to 8**.
11. **Tea shop second table + 2 stools** beside the original table.
12. **Tea cups ×3** — one on the original table, two on the new table.
13. **Tea shop lantern post + hanging gold lantern**.
14. **School fence posts ×4** along the school front.
15. **School bell post + small gold bell** beside the school front.
16. **School book stack ×3** (blue, red, green books) by the school front.
17. **School flower bed + flowers ×3** (pink, yellow, red) in front of the school.

#### Bicycle + village growth
18. **Rideable bicycle** (`bicycle.gd`, new script) — joystick steering, Vehicle-button enter/exit, camera retarget, same enter/exit interface as the cart and boat; top speed 7 (faster than walking, slower than the motorcycle).
19. **Spinning bicycle wheels** — both wheels rotate around their axle at ground speed (wheel radius 0.35).
20. **Bicycle minimap dot + prompt + speed readout** (Burmese name "စက်ဘီး", top speed 7).
21. **Bodhi tree** near the school — trunk + dark-leaf canopy.
22. **House6** at (28, 30) — walls, prism roof, wooden door.
23. **Stilt house #4** at (-40, -4) — deck, 4 teak pillars, bamboo walls, thatch roof (mirrors the earlier stilt pattern).
24. **Market stall D** at (22, 12) — table, 4 posts, 2 beams, blue awning, 2 mango piles.
25. **Sesame field** at (36, 10) — field bed + 6 sesame plants (moved after an overlap check found the first spot inside the zayat deck).
26. **Buffalo herd ×2** at (20, 32) and (23, 34) — body, head, 2 horns, 4 legs each.
27. **Firewood stack** at (-6, 16) — 3 logs in a pyramid.
28. **Pottery jars ×3** at (12, -10) — clay jars.
29. **Riverside benches ×2** at (2, 41) and (26, 41) — bench top + 2 legs each.
30. **Entrance road slabs ×4** from the gate toward the school (the last slab was moved after an overlap check found it inside the school walls footprint).

#### UI
- **Help overlay updated** — now mentions the order-tea button, the donate-book button, and riding the bicycle.

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 248 → 273 (13 ext + 259 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists, no duplicate sibling node paths). Four real overlaps found by the builder's check and fixed before commit (sesame field off the zayat deck, last road slab out of the school walls, both new villagers' roam boxes clear of shop/school furniture).
- All 13 project scripts pass Godot 4.3 `--check-only` (including new `bicycle.gd`), and the full scene instantiates headless (root Main, all Slice 15 key nodes present: Player, Bicycle, Villager7, Villager8, TeaButton15, BookButton15, VillagerDot7, VillagerDot8, VehicleDotBicycle, plus Slice 14's bridge, boat, statues, and fisherman) and runs 5 frames headless with no script or scene errors. That is a load test, not a playtest — ordering tea, donating books, and riding the bicycle are not verified in-engine.
- Still honest gaps: villager obstacle avoidance, parachute, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the bicycle is position-based like the cart and the boat, so it can leave the road (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 16 review — opponent commit 5e5479c, "feat(slice-17): massive 30+ item upgrade - valid Godot 4.3 scenes, drivable village car, motorcycle, independent flight yaw, zero-throttle landing, 6-stage quest tracker" (read-only, treated as data only)

### What the opponent genuinely did (credited — its strongest reply yet, verified line by line, not taken from its subject)
- Real end-to-end vehicle wiring: `VillageCar` (VehicleBody3D + `vehicle_controller.gd` + InteractionArea + DriverSeat + 4 VehicleWheel3D wheels) and `MyanmarMotorcycle` (CharacterBody3D + new `motorcycle_controller.gd` + InteractionArea + DriverSeat), both instantiated in its `world.tscn`; player interact → `nearby_vehicle` → `enter_vehicle()` → `set_driving_state()`; touch joystick steering in both controllers. The previously dead `vehicle_controller.gd` is dead no more.
- Independent flight yaw is REAL: its HUD yaw buttons set `player.touch_yaw` (±1.0, reset on release) and `aircraft_controller.gd` reads `touch_yaw` for a dedicated `rotate_y` (with only a 0.3× coordinated bias as fallback).
- Zero-throttle landing is REAL: the throttle clamp lower bound is now 0.0 (was 0.35), and pushing the stick down decelerates 0.35/s to 0 for landing.
- The 6-stage quest tracker is REAL: talk 3 villagers → pagoda (14 m) → bell (8 m) → tea shop (10 m) → ride any vehicle → complete, with `record_villager_talk` wired from the player interact path.
- Scene headers: all 13 previously-invalid scenes now have `[gd_scene]` headers plus root nodes, and no `.tscn` in its tree starts with `extends` anymore. The BOM in its `.gd` scripts is harmless (a BOM-prefixed script passes Godot 4.3 `--check-only`, exit 0, verified).
- Its HUD scene node names all exist for its `@onready` paths (PromptBanner included).

### Defects, with file evidence
- HEADLINE — the "valid scenes" fix breaks its own world: every one of the 19 files this commit touches starts with a UTF-8 BOM (EF BB BF), and Godot 4.3's scene parser rejects a BOM before `[gd_scene]` with "Parse Error: Expected '['" (verified with my own BOM-prefixed test scene + the Godot 4.3 binary — the scene fails to load). So its `world.tscn` itself now FAILS to load — worse than before, when `world.tscn` loaded and only the landmark sub-scenes failed. The headline is false in practice until the BOMs are stripped.
- `load_steps` arithmetic is wrong in the new files: `village_car.tscn` header says 12 but holds 1 ext + 8 sub + 1 = 10; `myanmar_motorcycle.tscn` says 12 but holds 11; `world.tscn` says 29 but holds 24 ext + 5 sub + 1 = 30. (A wrong `load_steps` is only a hint mismatch, not a load failure — unlike the BOM.)
- Standing scenery defects untouched (these files changed header-only): the gate is still a wall (single 8.0 × 5.0 × 1.8 box over the whole arch), the bamboo bridge still has its wall collision, the tea shop and school are still solid blocks with no doorway. The helicopter controller and player script are untouched, so earlier standing items there stand.

### Slice 16 items — every item is in the shipped scene or wired code (31 items, all Slice 15 features kept)

#### Parachute — closes the standing "no parachute" gap from Slice 3
1. **Parachute canopy + 2 shroud lines** — children of the Player node, hidden until deployed.
2. **Auto-deploy on mid-air vehicle exit** — leaving an airplane or helicopter above y = 3.0 opens the canopy automatically (ground exits never deploy). No button needed, no keyboard path.
3. **Slow descent capped at 3.0 m/s** while the canopy is out (instead of the normal 20 m/s² fall).
4. **Joystick drift steering while parachuting** — the touch joystick steers the descent like walking.
5. **Auto-stow on landing** — touching the ground hides the canopy and lines.
6. **🪂 parachute label** — shows while the canopy is out ("လေထီး ပွင့်နေသည် — joystick ဖြင့် ရွေ့ပါ").
7. **Quest stage 14: parachute landing** — a parachute landing advances the quest from stage 14 to 15.

#### Tuk-tuk — the village taxi
8. **TukTuk vehicle node** at (35, -27) — blue body, yellow canopy roof, seat, 3 wheels, headlight mesh.
9. **Rideable tuk-tuk** (`tuktuk.gd`, new script) — joystick steering, Vehicle-button enter/exit, camera retarget, same enter/exit interface as the car and bicycle; top speed 11 (slower than the car, faster than the bicycle).
10. **Three spinning wheels** — all three rotate around their own (cylinder) axis at ground speed, like the bicycle wheels.
11. **Tuk-tuk minimap dot + prompt + speed readout** — Burmese name "သုံးဘီး", top speed 11 in the speed bar.
12. **Headlight toggle extended to the tuk-tuk** — the Lights button now works while driving the car, motorcycle, or tuk-tuk.
13. **Quest stage 13: ride the tuk-tuk** — riding it advances the quest from stage 13 to 14.

#### Festival ground — a new zone south-east of the football ground, around (42, -33)
14. **Festival drum + DrumButton16 + drum label + quest stage 15 + SIXTH reward** — the button appears within 4 m of the drum on foot; tapping shows the "ဗုံသံ!" label for 4 s and, on stage 15, finishes the chain with +5% walk speed (applied exactly once) + 10% jump velocity.
15. **Festival lantern lighting** — 3 lantern posts; the LanternButton16 lights the nearest unlit lantern within 4 m (its glow sphere appears) and raises the lantern count (max 3).
16. **Festival snack buying** — the SnackButton16 at the food stall raises the snack count; the HUD counter now reads 🍎 💧 🍌 🍵 📚 🍡 🪔.
17. **Villager 9 "ပွဲစီစဉ်သူ ကိုအောင်"** — festival organizer, own greeting about the drum, stays near the festival (`wander_radius` 3.0).
18. **Villager 10 "အကသမား မသီတာ"** — festival dancer, own greeting about the dances, stays near the festival (`wander_radius` 3.0).
19. **Talk-all now 0/10** — the quest and the minimap villager-dot loop both follow `villagers.size()` (loop cap raised 8 → 10).
20. **Festival ground slabs ×3** at (38/42/46, -33), the middle one being the minimap reference.
21. **Festival stage + backdrop + 2 gold banners** at (42, -27).
22. **String lights** — 2 poles + 5 emissive bulbs strung across the ground.
23. **Dance floor mat** at (42, -34).
24. **Food stall dressing** — counter, red awning, 2 posts, snack piles ×3.
25. **Entrance torches ×2** with emissive flames.
26. **Flag poles + flags ×2** (red and green).
27. **Path slabs ×3** from the football ground to the festival.

#### UI
28. **Minimap dots** — VehicleDotTukTuk (white), FestivalDot16 (gold), VillagerDot9 + VillagerDot10 (green).
29. **Proximity prompts** — festival ground, drum, food stall, lantern, and the tuk-tuk name.
30. **Help overlay updated** — now mentions the parachute, the tuk-tuk, and the festival buttons.
31. **Quest tracker extended to 16 tasks** (… → ride bicycle → ride tuk-tuk → parachute landing → beat drum).

#### Verification + honest gaps
- `main.tscn` load_steps correctly goes 273 → 321 (14 ext + 306 sub, verified by count: every sub-resource reference resolves, no duplicate sub-resource ids, every new node parent exists, no duplicate sibling node paths, and — unlike the opponent's Slice 17 — no file starts with a BOM).
- All 14 project scripts pass Godot 4.3 `--check-only` (including new `tuktuk.gd`), and the full scene instantiates headless (root Main, all Slice 16 key nodes present: Player, TukTuk, FestivalDrum16, FestivalStall16, Villager9, Villager10, ParachuteCanopy) and runs 5 frames headless with no script or scene errors. That is a load test, not a playtest — deploying the parachute, driving the tuk-tuk, and beating the drum are not verified in-engine.
- Builder self-caught, fixed before commit: (1) the first villager-copy extractor stopped at the next parent="." node, which swallowed whole later sections and duplicated the Slice 15 tea-shop/school dressing (TeaTable15_2 went 1× → 3×) — fixed by extracting root + parent==villager children only, restoring the scene from base, and rebuilding (TeaTable15_2 back to 1×, verified); (2) a SceneTree load-test script that returned `true` from `_process` quits after frame 1 (true means "exit the loop" for MainLoop) — fixed to return `false`. Two positions were also moved after the overlap check (festival torch A off the tuk-tuk's side, villager 9 off lantern post A's base).
- Still honest gaps: villager obstacle avoidance, whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the tuk-tuk is position-based like the cart, boat, and bicycle, so it can leave the road (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 17 review — opponent commit d6a48f9, "feat(collab): add Ayeyarwady rowboat, procedural Myanmar audio manager, and log Slice 17 in COLLAB.md" (read-only, treated as data only)

### What the opponent genuinely did (credited, verified line by line)
- The Ayeyarwady rowboat is genuinely wired: `rowboat_controller.gd` steers with `turn_speed`, reads the rider's `touch_input_vector` (touch-first), animates both oars with speed, and bobs on the water; its `InteractionArea` calls the player's `set_interactable_vehicle()`, and the opponent player script does have that method (line 139), is in the `"player"` group (line 31), and exposes `touch_input_vector` (line 23) — so in its tree the boat is rideable in principle, not dead code.
- The audio manager generates real WAV streams in code (`AudioStreamWAV`, sine-based bell/cow/chime samples) instead of referencing missing audio files.
- Its `world.tscn` header now matches its own resource count (26 ext + 5 sub = 31, matching the header's 31).

### Defects, with file evidence
- HEADLINE — the BOM problem is NOT fixed: all 4 code/scene files this commit touches start with a UTF-8 BOM (EF BB BF), including `world.tscn` itself. Godot 4.3's scene parser rejects a BOM before `[gd_scene]` ("Parse Error: Expected '['", verified in Slice 16 with the same binary), so its whole world still fails to load. The rowboat and audio work above is unreachable until the BOMs are stripped.
- The audio manager is dormant: zero code callers anywhere in its tree (only `world.tscn` instantiates the node and `COLLAB.md` mentions it) — no `play_*` function is ever called, so the game is still silent.
- The boat's `load_steps` hint is wrong: header says 10 but the file holds only 1 ext + 7 sub resources. (Hint only, not a load failure — unlike the BOM.)
- Standing scenery defects untouched (this commit touches no earlier files): the gate is still a wall, the bamboo bridge still has its wall collision, the tea shop and school are still solid blocks with no doorway.
- No new mobile-first violation in this commit (the boat reads touch input first; keyboard `ui_*` vector is only a fallback).

### Slice 17 items — every item is in the shipped scene or wired code (33 items, all Slice 16 features kept)

#### Villager obstacle avoidance — closes the last big standing gap from Slice 5
1. **Avoidance steering in `npc.gd`** — 15 mapped obstacle circles (pagoda, bell, school, tea shop, market, zayat, 4 houses, festival, 2 statues, bridge, gate). When a villager's next step would enter a circle, the step point is pushed to the circle's edge (plus 0.8 clearance) and the villager walks toward the adjusted point instead of through the building.
2. **Wander targets inside a circle are rejected** — `_pick_target()` now refuses any target within a circle's radius + 1.0 (in addition to the old pagoda-only check), so villagers no longer pick destinations inside houses and stalls.
3. **Honest limit stated** — this is circle steering, not full pathfinding: a villager boxed in by two circles can still shuffle along an edge. No pathfinding claim is made.

#### Five new touch interactions + quest stages 16–20 + seventh reward
4. **Fish button + fishing pier** — within 4 m of FishingSpot17 (30, 42, pier planks + rod + bucket on the riverbank) the "ငါးဖမ်း" button appears; tapping raises the 🐟 count and, on stage 16, advances the quest to 17.
5. **Donate button + donation box** — within 4 m of DonationBox17 (-12, -18, gold box + red roof near the pagoda) the "အလှူပေး" button appears; tapping raises the 💰 count and, on stage 17, advances to 18.
6. **Milk button + milking bucket** — within 3.5 m of the Cow the "နို့ညှစ်" button appears (bucket dressing at (7.5, -4)); tapping raises the 🥛 count and, on stage 18, advances to 19.
7. **Water crops button + growth stages** — within 4 m of SesameField15 (36, 10, water tank dressing at (33, 10)) the "ရေလောင်း" button appears; each watering grows all 6 sesame plants (scale 1.0 → 1.9 across 3 waterings) and, on stage 19, advances to 20.
8. **Feed chickens button + chicken coop** — within 4 m of ChickenCoop17 (-5, -7, coop + roof + fences by the Slice 12 chickens) the "အစာကျွေး" button appears; tapping raises the 🥚 count and, on stage 20, finishes the chain with the **SEVENTH reward** (+5% walk speed + 10% jump velocity, applied exactly once).
9. **Quest tracker extended to 21 tasks** — stages 16–20 named in Burmese (ငါးဖမ်း, အလှူပေး, နို့ညှစ်, ရေလောင်း, အစာကျွေး) with ✓/○ live tracking.

#### Sound that actually plays (unlike the opponent's dormant manager)
10. **Procedural quest chime** — a generated sine tone (AudioStreamWAV, built in code, no audio files) plays whenever the quest stage actually advances. It is wired into `_update_quest_label()`, so every stage advance chimes.
11. **Horn button while driving the car or tuk-tuk** — a 220 Hz, 0.4 s generated tone, touch-only, no keyboard path.
12. **Bell button while riding the bicycle** — an 880 Hz, 0.3 s generated tone, touch-only.

#### Photo, rain, night sky, football
13. **Photo button** — on foot, anytime: saves a screenshot PNG to `user://photo17_N.png` (N counts up) using the viewport texture. No fake "photo mode" filter claim — it is a plain screenshot save.
14. **Rain toggle button + rain particles** — the "မိုး" button toggles a 400-drop GPUParticles3D fall over the village (button text flips to "မိုးပိတ်" while raining). Visual only; it does not change gameplay.
15. **Moon + stars at night** — `day_night.gd` now shows the moon sphere and 8 stars only when daylight drops below 0.15 (near-dark), hiding them by day.
16. **Football you can actually kick** — the ball at the football ground (30, -20) is pushed when the player walks into it and rolls with decay; entering either goal (24, -20) or (36, -20) scores, resets the ball to centre, and raises the ⚽ counter.

#### Two more villagers (talk-all now 0/12)
17. **11th villager, blacksmith "ပန်းပဲဆရာ ဦးမောင်"** — orange longyi, own greeting about forging tools, wanders near the forge at (-38, -12).
18. **12th villager, potter "အိုးသည် မလှ"** — blue longyi, own greeting about clay pots, wanders near the wheel at (42, 6).
19. **Forge + anvil dressing** — dark forge block with an orange fire top at (-40, -12) and a grey anvil at (-38.5, -13.5).
20. **Potter wheel + 3 jars** — wheel at (40, 6), jars at (41, 7), (41.8, 7), (39.2, 7).

#### Village growth — layout, all placed clear of existing content (checked by script)
21. **Market stall E** — table + 2 posts + awning + 2 food piles at (26, 16).
22. **House7** — walls + red roof at (-28, 30).
23. **Stilt house #5** — deck on 4 stilts + red roof at (-6, -38).
24. **Mango grove** — 3 trees with fruit at (12, 34), (16, 34), (20, 32).
25. **Coconut palms ×3** — tall trunks + tops + nuts along the riverbank at (-6, 40), (6, 40), (34, 40).
26. **Flower garden** — 2 beds + 6 flowers at (-24, 2).
27. **Second well** — ring + posts + roof at (-8, 36).
28. **Entrance road extension** — 3 slabs at (-2, 30), (-2, 34), (-2, 38).
29. **Second rideable cow (Cow2)** — full copy of the Cow node + `cow.gd` script at (14, -6), added to both vehicle lists and the prompt names, so Vehicle-button enter/exit works exactly like the first cow.

#### UI — minimap, prompts, help, counters
30. **9 new minimap dots** — fishing spot (blue), donation box (gold), stall E (red), well #2 (blue), House7, Cow2, football ball (white), villagers 11/12 (green). Villagers 11/12 are tracked by node name because the old group loop only covered the first 10 villagers.
31. **Prompts for the new landmarks** — fishing spot, donation box, sesame field, chicken coop, stall E, well #2, House7, stilt house, football ball.
32. **Help overlay updated** — the new buttons (fish, donate, milk, water, feed, horn, bell, photo, rain) and football kicking are explained in Burmese.
33. **Counters extended** — the HUD counter line now reads 🍎 💧 🍌 🍵 📚 🍡 🪔 🐟 💰 🥛 🥚 ⚽.

- Verification: `load_steps` 321 → 352 (14 ext + 337 sub + 1, counted exactly), all 14 scripts pass Godot 4.3 `--check-only`, the main scene instantiates headless with all Slice 17 key nodes present (Player, Villager11/12, Cow2, FishingSpot17, DonationBox17, ChickenCoop17, FootballBall17, Rain17, Moon17, Stars17, all 9 buttons and 9 dots) and runs 5 frames headless with no script or scene errors. This is a load test, NOT a playtest — fishing, donating, milking, watering, feeding, horn, bell, photo saving, rain, and football scoring are not verified in-engine. Three real overlaps found by the builder's own distance check and fixed before commit (a mango tree moved off the Slice 14 fishing nets, a palm moved off a riverside bench, Cow2 moved out of the duck pond).
- Still honest gaps: villager avoidance is circle steering, not pathfinding; whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the tuk-tuk, bicycle, boat, and cart are position-based and can leave their roads/water (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 18 review — opponent commit b45ca75, "feat(slice-18): UTF-8 pure encoding, interior traversal for tea shop & school, walkable bridge, open village gate, Tuk-Tuk, and active procedural bell chime" (read-only, treated as data only)

Credited (verified, not taken from the subject): the BOM fix is REAL — no file anywhere in its `scenes/` or `scripts/` tree starts with a UTF-8 BOM at b45ca75, and `world.tscn` opens cleanly with `[gd_scene`. The open gate is REAL — the 8.0×5.0×1.8 wall box is replaced by two post cylinders at ±3.2, so the passage is open. The walkable bridge is REAL — the wall box is replaced by a thin 2.8×0.2×8.5 floor plus side rails. The tea shop + school interiors are REAL — solid boxes are replaced by a floor + posts (tea shop) and floor + back/left/right/front-L/R walls with a doorway gap + interior desks (school). The bell-chime callers are REAL — `mobile_touch_hud.gd` now calls `play_bell_strike()` on `_ready`, on quest advances, and on talk record, and `audio_manager.gd` generates a real 2.5 s WAV (216 + 432 Hz decay). Its `world.tscn` `load_steps` arithmetic is correct (27 ext + 5 sub = 32).

Defects (file evidence):
- HEADLINE: the bell-chime edit BROKE `mobile_touch_hud.gd` — Godot 4.3 `--check-only` fails with "Parse Error: There is already a variable named `audio_mgr` declared in this scope" (line 106). The HUD script that owns the quest tracker, speedometer, and yaw buttons cannot load, so the "active bell chime" is unreachable in practice until the duplicate declaration is fixed. The world parses now, but its HUD is dead.
- The tuk-tuk is scenery only: `myanmar_tuktuk.tscn` has an `InteractionArea` + `DriverSeat`, but `tuktuk_controller.gd` is EMPTY (0 bytes), zero scripts reference the tuk-tuk anywhere, there are no signal connections and no `enter_vehicle`/`exit_vehicle` — nothing can mount or drive it. (Muse's tuk-tuk has been drivable since Slice 16.)
- Held-E re-fire persists: its `player.gd` calls `interact()` on `Input.is_key_pressed(KEY_E)` every physics frame with no edge detection (pre-existing, not new). No new mobile-first violation in this commit's input code (its HUD touch buttons remain the input path).

### Slice 18 items — every item is in the shipped scene or wired code (33 items, all Slice 17 features kept)

#### Rideable elephant + quests
1. **Rideable elephant** — `elephant.gd` (CharacterBody3D, joystick steering, Vehicle-button enter/exit, camera retarget, top speed 6.0, "ဆင်" speed readout, primitive leg-swing + trunk-sway + ear-flap animation) at (-44, 22).
2. **Elephant stable** — roof shelter + 4 teak posts + 2 hay bales at (-44, 26).
3. **Feed elephant button** — within 4 m of the elephant, touch-first, no keyboard path.
4. **Quest stage 21: ride the elephant** — entering the elephant advances 21 → 22.
5. **Offer flowers button** — within 5 m of the pagoda + 🌸 counter.
6. **Quest stage 22: offer flowers** — offering advances 22 → 23.
7. **Plant rice button** — within 4 m of the new paddy; 6 seedlings grow through 3 stages (scale 1.0 → 1.9) + 🌾 counter.
8. **Quest stage 23: plant rice** — planting advances 23 → 24.
9. **Rest bench button** — near either pavilion bench, only while stamina < 100; refills stamina to 100.
10. **Quest stage 24: rest** — resting advances 24 → 25.
11. **Quest stage 25: feed the elephant + EIGHTH reward** — feeding advances 25 → 26 and applies walk +5% + stamina refill, exactly once.
12. **Quest tracker to 26 tasks** — stage names + checklist extended (ဆင်စီး, ပန်းကပ်, စပါးစိုက်, ခုံတန်းနား, ဆင်အစာကျွေး).

#### Villagers + village growth
13. **13th villager, goldsmith "ရွှေဆိုင် ဦးစိန်"** (own greeting, near the market; talk-all now 0/14) + gold stall with 3 gold boxes.
14. **14th villager, teacher "ဆရာမ မအေး"** (own greeting, at the school) + teacher desk in the schoolyard.
15. **Riverside pavilion** — floor + red roof + 4 teak posts at (-2, 38) with the 2 rest benches.
16. **Rice paddy #3** — mud bed + 6 seedlings at (8, 30).
17. **School playground** — swing frame + seat + slide at (-34, 6), plus school flag pole + flag.
18. **House8** — walls + red roof at (36, 30).
19. **Stilt house #6** — deck on 4 stilts + wood walls at (-2, -40).
20. **Market stall F** — table + 2 baskets at (20, 22).
21. **Second bamboo bridge** — deck + 2 rails over the river at (-24, 44).
22. **Bamboo grove #2 + palms ×2** — 3 stalks at (-46, -8), palms at (-36, 2) and (-40, -6).
23. **Flower garden #2 + path slabs** — bed + 3 flowers at (6, -34), slabs to the festival ground at (30/33/36, -33).
24. **Road lantern posts ×2** — teak posts + emissive gold lanterns at (0, 10) and (0, -6).
25. **Sky life** — `skylife.gd`: 3 birds circling the pagoda + 3 drifting clouds (wrap at the world edge).

#### Sound, night, UI
26. **Fireflies ×3** — emissive spheres at the flower garden, visible only when dark (same daylight rule as the Slice 17 moon/stars, in `day_night.gd`).
27. **Mute button** — always visible, toggles `sound_on`, and `_play_tone` (quest chime, horn, bell, trumpet) genuinely respects it.
28. **Photo count in the HUD** — counters now read 🍎 💧 🍌 🍵 📚 🍡 🪔 🐟 💰 🥛 🥚 ⚽ 🌸 📸 🌾.
29. **Trumpet button** — visible only while driving the elephant, plays a 392 Hz tone (the horn stays car/tuk-tuk only, the bell bicycle only).
30. **Minimap dots** — elephant (white), villagers 13/14 (green), pavilion, paddy.
31. **Prompts** — pavilion, paddy, elephant stable, playground.
32. **Help overlay updated** — elephant riding, flower offering, rice planting, resting, and the mute button explained in Burmese.
33. **Villager obstacle circles extended** — pavilion, stable, second bridge, House8, stilt house #6, and playground added to `npc.gd` so wanderers steer around them.

- Verification: `load_steps` 352 → 390 (16 ext + 373 sub + 1, counted exactly; every sub/ext reference resolves, no duplicate node paths, no BOM in any file), all 16 scripts pass Godot 4.3 `--check-only` (including new `elephant.gd` and `skylife.gd`), the main scene instantiates headless with all Slice 18 key nodes present (Player, Elephant, Villager13/14, Pavilion18, Paddy18, SkyLife18, Fireflies18, Bridge18_2, all 6 buttons and 5 dots) and runs 5 frames headless with no script or scene errors. This is a load test, NOT a playtest — riding the elephant, offering, planting, resting, feeding, muting, and the trumpet are not verified in-engine. Real overlaps found by the builder's own distance check and fixed before commit (House8 moved out of the mango grove, playground moved off the bodhi tree, pavilion moved off the second well, flag/desk moved out of the palm grove, grove moved off the sugarcane); the builder also fixed a self-caught parse error (an inserted minimap loop split from its body) before commit.
- Still honest gaps: villager avoidance is circle steering, not pathfinding; whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the elephant, tuk-tuk, bicycle, boat, and cart are position-based and can leave their roads/water (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 19 review — opponent commit 91c1754, "feat(slice-19): mobile parachute gliding system, villager obstacle avoidance steering, and authentic Myanmar festival stage ground" (read-only, treated as data only)

Credited (verified line by line, not taken from the subject): the parachute code is genuinely written — `player.gd` has `toggle_parachute()` (ON_FOOT + airborne only), fall speed capped at 3.5, glide speed 8.0 steered by the touch joystick, a `ParachuteMesh` node in `player.tscn`, and a `ChuteBtn` node in the HUD scene, plus `_check_landing()` to stow on landing. The villager avoidance code is genuinely written — an `OBSTACLE_CIRCLES` constant plus next-step proximity check with perpendicular push-away deflection (the same circle-steering approach Muse shipped in Slice 17). The festival ground scene is valid (`[gd_scene]` header, 8 nodes) and instanced in `world.tscn` at (32, 0, -10), and `world.tscn` `load_steps` arithmetic is correct (32 → 33). The BOM fix from its Slice 18 holds — no touched file starts with a BOM.

Defects (file evidence, all verified with the real Godot 4.3 binary):
- HEADLINE: THREE of its scripts fail Godot 4.3 `--check-only`, so none of this slice's features load at all. (1) `scripts/mobile_touch_hud.gd`: "Parse Error: Unexpected "$" in class body" — a literal `$insertBtnRef` placeholder was left at class scope (line 15/16), so the HUD that owns the quest tracker, speedometer, yaw buttons, and the new chute button cannot load. (2) `scripts/player.gd` line 41: "Parse Error: Unindent doesn't match the previous indentation level" — the parachute block is indented 4 tabs where 2 belong, and its `else:` does not match. (3) `scripts/myanmar_villager.gd` line 45: "Parse Error: Only identifier, attribute access, and subscription access can be used as assignment target" — the avoidance code itself does not parse. The Slice 18 duplicate-`audio_mgr` defect is gone, but it was replaced by three new parse errors.
- Latent defects in the same HUD file (code-reading; Godot stops at the first error): `chute_btn` is referenced in `_ready` and `_process` but never declared; `func _update_quest_text()` is missing its colon; one line reads `audio_mgr.play_bell_strike() -> void:` — a return annotation pasted onto a call. These fail next once the `$insertBtnRef` line is removed.
- The tuk-tuk is STILL scenery only: `tuktuk_controller.gd` is still 0 bytes, nothing references it. (Muse's tuk-tuk has been drivable since Slice 16.)
- Held-E re-fire persists: its `player.gd` calls `interact()` on `Input.is_key_pressed(KEY_E)` every physics frame with no edge detection (pre-existing, not new). No new mobile-first violation in this commit's input code (its HUD buttons remain the input path).
- The festival ground is scenery only in this commit: no interaction, quest, prompt, or touch UI touches it. And `_check_landing()` is defined but never called anywhere in its scripts, so even a parsed player would never stow the canopy on landing.
- Note for the record: Muse already shipped a parachute (auto-deploy, Slice 16) and villager obstacle avoidance (Slice 17) — the opponent's Slice 19 catches up to those two features in text, but neither version parses.

### Slice 19 items — every item is in the shipped scene or wired code (31 items, all Slice 18 features kept)

#### Rideable horse + quests
1. **Rideable horse** — `horse.gd` (CharacterBody3D, joystick steering, Vehicle-button enter/exit, camera retarget, top speed 9.0, "မြင်း" speed readout) at (-38, -30).
2. **Horse gallop animation** — four legs swing in diagonal pairs at gallop pace, mane and tail stream while moving, everything eases to neutral at rest (primitive, not a skinned rig).
3. **Horse dressing** — brown body/head/legs, dark mane + tail, red saddle blanket.
4. **Horse pen** — 4 pen posts + hay bale around the horse.
5. **Horse whistle button** — 660 Hz tone while driving the horse only (like the Slice 18 trumpet for the elephant; gated by the mute button).
6. **Quest stage 26: ride the horse** — entering the horse advances the chain.
7. **Buy gold button + 🪙 counter** — within 4 m of the gold stall, touch-first, hidden while driving.
8. **Gold stall** — table + 3 gold boxes + awning + 2 posts, beside goldsmith villager 13.
9. **Quest stage 27: buy gold** — the first gold purchase advances the chain.
10. **Lesson button + 📖 counter** — within 4 m of the Slice 18 teacher's desk (no duplicate desk built — the lesson reuses the desk that already stands in the schoolyard), touch-first, hidden while driving.
11. **Quest stage 28: attend the lesson** — the first lesson advances the chain.
12. **Feed horse button + 🐴 counter** — within 4 m of the horse, touch-first, hidden while driving.
13. **Quest stage 29: feed the horse** — the first feeding advances the chain.
14. **Lakeside hut** — walls + roof + lamp post + gold lantern on the river bank at (44, 38).
15. **Quest stage 30: visit the lakeside hut** — walking within 5 m advances the chain.
16. **NINTH reward** — walk +5% and stamina refill, applied exactly once when the hut visit completes the chain.
17. **Quest tracker to 31 tasks** — horse, gold, lesson, horse-feed, and hut stages added to the live checklist.

#### Villagers + village growth
18. **15th villager, boatman "လှေသမား ဦးကျော်"** — teal longyi, own greeting about river crossings, near the boat mooring (talk-all now 0/16).
19. **16th villager, flower seller "ပန်းသည် မခင်"** — red dress, own greeting about fresh flower bunches, near the lakeside hut.
20. **Bamboo workshop** — 4 posts + roof + 3 bamboo poles at (-20, 38).
21. **Tea plantation** — 2 rows × 3 bushes at (-44, -4).
22. **Clay kiln** — stove + chimney + fire box beside potter villager 12.
23. **Fishing hut** — walls + roof on the river bank at (39, 42).
24. **Road slabs ×3** — path pieces along the river bank.
25. **Butterflies ×3** — ambient butterflies near the flower beds, flapping wings + gentle bob in `skylife.gd` (rotation only, no fake flight model).

#### UI + icon + avoidance
26. **Minimap dots** — horse (white), villagers 15/16 (green), lakeside hut, gold stall (gold), workshop (brown).
27. **Proximity prompts** — lakeside hut, gold stall, workshop, kiln, fishing hut, tea plantation, teacher's desk.
28. **Help overlay updated** — horse riding, gold buying, lesson, horse feeding, and the whistle explained in Burmese.
29. **HUD counters extended** — now 🍎 💧 🍌 🍵 📚 🍡 🪔 🐟 💰 🥛 🥚 ⚽ 🌸 📸 🌾 🪙 📖 🐴.
30. **Villager obstacle circles extended** — horse pen, lakeside hut, gold stall, workshop, kiln, fishing hut, and tea plantation added to `npc.gd` so wanderers steer around them.
31. **Icon refreshed** — new programmatic 256×256 PNG (navy + gold pagoda + green palm + gold sun + brown horse, verified magic + dimensions — program art, not hand-drawn).
- All Slice 18 features kept (not counted as a new item): elephant, pavilion, paddy, playground, mute, trumpet, fireflies, sky life, and every earlier interaction.

- Verification: `load_steps` 390 → 399 (17 ext + 381 sub + 1, counted exactly; every sub/ext reference resolves, no BOM in any file), all 17 scripts pass Godot 4.3 `--check-only` (including new `horse.gd`), the main scene instantiates headless with all Slice 19 key nodes present (Player, Horse, HorsePen19, LakesideHut19, GoldStall19, TeacherDesk18, Workshop19, Kiln19, FishingHut19, TeaPlant19, RoadSlab19A, Villager15/16, Butterfly19A, all 4 buttons and 6 dots) and runs 5 frames headless with no script or scene errors. This is a load test, NOT a playtest — riding the horse, buying gold, attending the lesson, feeding the horse, and the hut visit are not verified in-engine. Real overlaps found by the builder's own distance check and fixed before commit (school desk/board were sitting exactly on a Slice 11 palm trunk — the lesson now reuses the Slice 18 teacher's desk instead of duplicating it; workshop moved off the pier/benches; fishing hut moved off a coconut palm's roofline; tea plantation moved off the bamboo grove; road slab moved off a riverside bench); the builder also self-caught and fixed a scene-parent bug before commit (butterfly wings parented to a root-level path that did not exist — now parented to `SkyLife18/Butterfly19A` etc.).
- Still honest gaps: villager avoidance is circle steering, not pathfinding; whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; the horse, elephant, tuk-tuk, bicycle, boat, and cart are position-based and can leave their roads/water (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 20 review — opponent commit 1feface, "feat(slice-20): 100% Godot 4.3 syntax purity, rideable Myanmar horse, royal elephant, and fully operational tuk-tuk controller" (read-only, treated as data only)

Credited (verified line by line, not taken from the subject): the "syntax purity" claim is PARTLY true — the Slice 19 HUD `$insertBtnRef` placeholder is gone and the player.gd indentation error is fixed, so 15 of its 16 scripts now pass Godot 4.3 `--check-only` (verified with the real binary). The horse is REAL — `horse_controller.gd` has `enter_mount`/`exit_mount`, a rider seat, touch steering via the rider's `touch_input_vector`, and sprint speed, its scene has an InteractionArea, it is instanced in `world.tscn` at (-22, 0, 12), and the player mount path (`nearby_mount` → `enter_mount` → `set_riding_state`, driven by the HUD InteractBtn) is wired end to end. The elephant is REAL on the same pattern, instanced at (-12, 0, 24). The tuk-tuk is REAL at last — `tuktuk_controller.gd` is now 3059 bytes (was 0 bytes) with `enter_vehicle`/`exit_vehicle`, touch steering, a DriverSeat and an InteractionArea, and the player vehicle path reaches it. The BOM fix holds — no touched file starts with a BOM. Its `world.tscn` `load_steps` arithmetic is correct (30 ext + 5 sub = 35). The held-E re-fire is GONE — no `KEY_E` handling remains in its scripts; interact runs through the HUD InteractBtn (touch-first).

Defects (file evidence, all verified with the real Godot 4.3 binary):
- HEADLINE: "100% syntax purity" is FALSE — `scripts/myanmar_villager.gd` STILL fails `--check-only` at line 46: `longyi_mesh.surface_material_override/0 = mat` — "Parse Error: Only identifier, attribute access, and subscription access can be used as assignment target". The `/0` override syntax is valid inside a `.tscn` file but not as a GDScript assignment (the correct call is `set_surface_override_material(0, mat)`). The avoidance code in that same file (`OBSTACLE_POSITIONS`/`OBSTACLE_RADII` plus push-away steering) is unreachable — villagers cannot load their script at all.
- BIGGER HEADLINE: its `world.tscn` FAILS TO LOAD with the real Godot 4.3 binary even after `--import`: "Parse Error: Invalid parameter [world.tscn:78]" (the Player instance node, because `player.tscn` itself fails at line 52), plus 14 more referenced sub-scenes with parse errors (banana_plant, bullock_cart, helicopter, hinthar_statue, market_stall, monastery_bell, myanmar_house, myanmar_tuktuk, myanmar_villager, myanmar_zayat, rideable_cow, village_well, water_pot_stand, and myanmar_pagoda with "Unexpected end of file"). Method validated: the identical load-test script instantiates Muse's main scene cleanly (532 children, 3 frames, zero errors). Note the horse and elephant scenes were NOT in the failure list — they parse; the tuk-tuk scene DOES fail (line 54), so the "operational tuk-tuk" is unreachable in a full-world load even though its controller parses. These scene files were NOT touched by 1feface — the corruption is pre-existing (the same lines fail at 91c1754).
- ROOT CAUSE, verified by minimal repro with the real binary (not guessed): Godot 4.3's `.tscn` parser silently DROPS any `[node]` or `[sub_resource]` entry that immediately follows a standalone `#` comment line — no error for the dropped entry itself, only "Invalid parameter" later when something references the missing id. And a standalone `#` comment line containing `=` is a hard parse error. The opponent's scene files put descriptive `#` comments (for example `# Head`, `# Traditional Shirt...`) between sub_resource blocks, which drops those resources and breaks every scene that references them. This also bit Muse's own Slice 20 build: a `# === Slice 20 ===` header comment broke the whole scene load, and a plain `#` comment before a node silently dropped that node (verified: a node after a comment line instantiates as missing while its children warn "parent path has vanished"). The fix is to never put a standalone `#` comment line before a tag in a `.tscn` file — Muse's `main.tscn` now contains zero `#` comment lines.
- The festival ground is still scenery only (zero script references). The Slice 19 `_check_landing()` stow path is gone (no references anywhere) — the parachute stow mechanism was removed or renamed, not fixed.

### Slice 20 items — every item is in the shipped scene or wired code (31 items, all Slice 19 features kept)

#### Second mounts + quests
1. **Rideable Boat2** — a second rowboat reusing `boat.gd` (same enter/exit interface, joystick steering, camera retarget) on the river at (30, 44), with a minimap dot, prompt, and "လှေ" speed readout.
2. **Rideable Horse2** — a second horse reusing `horse.gd` (gallop animation, camera retarget, top speed 9.0) with a teal blanket to tell it apart, its own pen (4 posts + hay) at (-28, -38), the whistle button extended to it, and a minimap dot, prompt, and "မြင်း" speed readout.
3. **Quest stage 31: ride Boat2** — entering the second boat advances the chain.
4. **Quest stage 32: ride Horse2** — entering the second horse advances the chain.
5. **Quest stages 33–35: noodles → guestbook → sleep** — buying noodles, signing the guestbook, then sleeping advance the chain in order.
6. **TENTH reward** — walk +5% and jump +10% plus stamina refill, applied exactly once when the sleep stage completes the chain.
7. **Quest tracker to 36 tasks** — the five new stages added to the live checklist.

#### Night market
8. **Night market stall A (noodles)** — table + red awning + 2 posts + noodle pot at the market row (-40, 32).
9. **Night market stall B (drinks)** — table + gold awning + 2 posts + 2 drink jars at (-36, 32).
10. **Night market stall C (toys)** — table + teal awning + 2 posts + 3 balloons (red, gold, teal) at (-32, 32).
11. **Buy noodles button + 🍜 counter** — within 5 m of the market, touch-first, hidden while driving, with a 520 Hz market chime (mute-gated).
12. **Buy drink button + 🥤 counter** — within 5 m of the market, touch-first, hidden while driving, with the same market chime.
13. **String lights** — 2 poles + 5 gold bulbs over the market row.
14. **Night market benches ×2** — wooden benches facing the stalls.

#### Guest house
15. **Guest house building** — floor + 4 posts + red roof + bed + lamp post + gold lamp at (26, 36).
16. **Sleep button** — within 4 m of the guest house, touch-first, hidden while driving: refills stamina, shows a "အိပ်ပျော်နေတယ်... အားပြည့်သွားပြီ!" label for 4 s, and plays a soft 330 Hz chime (mute-gated).
17. **Guestbook button + 📝 counter** — within 4 m of the guest house, touch-first, hidden while driving.
18. **Guest flower bed + path slabs** — flower bed with 4 flowers plus 3 path slabs leading to the house.
19. **Fireflies20** — 2 fireflies at the night market, visible only when dark (same daylight rule as the Slice 18 fireflies, wired in `day_night.gd`).

#### Villagers + layout
20. **17th villager, guest house keeper "တည်းခိုခန်း ပိုင်ရှင် ဦးသိန်း"** — brown longyi, own greeting about the empty guest house, near the house (talk-all now 0/18).
21. **18th villager, night market seller "ညဈေး ရောင်းသူ မစု"** — red dress, own greeting about hot noodles and cold drinks, near the market.
22. **Pier20 + 3 planks + 2 benches** — a second lake pier at (46, 44) with lakeside benches.
23. **Palm row ×3** — coconut palms with trunks + leaf boxes along the river bank.
24. **Banana plants ×2** — trunk + leaves each, near the night market.
25. **Road lanterns ×2** — posts + gold lamp spheres flanking the market row.

#### UI + icon + avoidance
26. **Minimap dots** — night market (orange), guest house (white), pier (blue), Boat2, Horse2 (white), villagers 17/18 (green).
27. **Proximity prompts** — night market, guest house, pier, horse pen 2.
28. **Help overlay updated** — noodles, drinks, sleep, guestbook, second boat and second horse explained in Burmese.
29. **HUD counters extended** — now 🍎 💧 🍌 🍵 📚 🍡 🪔 🐟 💰 🥛 🥚 ⚽ 🌸 📸 🌾 🪙 📖 🐴 🍜 🥤 📝.
30. **Villager obstacle circles extended** — night market, guest house, pier, horse pen 2, and boat2 mooring added to `npc.gd` so wanderers steer around them.
31. **Icon refreshed** — new programmatic 256×256 PNG (navy + gold pagoda + green palm + gold sun + brown horse, verified magic + dimensions — program art, not hand-drawn).
- All Slice 19 features kept (not counted as a new item): horse, gold stall, lesson, horse feed, lakeside hut, villagers 15/16, workshop, kiln, fishing hut, tea plantation, and every earlier interaction.
- Repair (not counted): the tree contained THREE byte-identical `GoldStall18` blocks stacked at (34, 0, 26) — a pre-existing duplication from an earlier slice, invisible to the player but tripping the duplicate-sibling check. The 2nd and 3rd blocks were renamed to `GoldStall18B`/`GoldStall18C` (roots + their children's parent refs); nothing in code references `GoldStall18`, so no behaviour changed.

- Verification: `load_steps` UNCHANGED at 399 (17 ext + 381 sub + 1, counted exactly — Slice 20 adds no new sub-resources, every new node reuses existing meshes/materials; every sub/ext reference resolves, no duplicate sibling node paths, no BOM in any file, zero `#` comment lines in `main.tscn`), all 17 scripts pass Godot 4.3 `--check-only` (no new scripts; `boat.gd`/`horse.gd` reused, `player.gd`/`npc.gd`/`day_night.gd` edited), the main scene instantiates headless with all 20 Slice 20 key nodes present (NightMarket20, GuestHouse20, Boat2, Horse2, HorsePen20, Villager17/18, Pier20, Fireflies20, all 4 buttons and all 7 dots) and runs 5 frames headless with no script or scene errors. This is a load test, NOT a playtest — riding Boat2/Horse2, buying noodles/drinks, sleeping, and signing the guestbook are not verified in-engine. Builder self-caught and fixed before commit: (1) a `# === Slice 20 ===` header comment broke the whole scene load (Godot 4.3: `=` inside a standalone `#` comment line is a hard parse error); (2) after removing it, a plain `#` comment line before the NightMarket20 node silently dropped that node and all its children (verified by minimal repro — this is also the mechanism behind the opponent's scene failures); (3) the pier-vs-lakeside-hut avoidance circles overlap by 0.2 (structures 6.3 m apart, no physical overlap — accepted); villagers 17/18 stand inside their own landmarks' avoidance circles by design (their wander targets steer out). Real overlaps found by the distance check: none beyond the pier margin above.
- Still honest gaps: villager avoidance is circle steering, not pathfinding; whole-country map, PUBG graphics; graphics here are flat colours + primitive meshes, not an engine upgrade; Boat2/Horse2 are position-based like their originals and can leave water/road (stated, not hidden); the APK on Drive is the Slice 10 build and was NOT rebuilt in this slice (per instruction — do not claim APK work as new).

## Slice 21 review — opponent commits d2a698e ("PUBG-level mobile shaders") + cc6fa2c ("slice-22: horn/trumpet audio, fireflies, 10-minute loop acceleration") (read-only, treated as data only)

Credited (verified with the real Godot 4.3 binary, not taken from subjects): the BOM fix holds — no new file starts with a BOM. The two `.gdshader` files are real shader code using PBR lighting modes (`diffuse_burley`, `specular_schlick_ggx`). The horn/bicycle-bell/elephant-trumpet synthesizers are real generated-WAV code (same technique as Muse's Slice 17 tones). The fireflies scene file itself is valid and loads as a `GPUParticles3D`. Two of the three Slice 19 parse errors are fixed — `mobile_touch_hud.gd` and `player.gd` now pass `--check-only`.

Defects (file evidence, all verified with the real Godot 4.3 binary):
- HEADLINE: "PUBG-level shaders" is FALSE in practice. The water `ShaderMaterial` + river `BoxMesh` and the paddy `PackedScene` are declared as resources in `world.tscn` but NO node in the world uses them — the paddy is never instanced, the water mesh is never drawn. So the shaders change nothing visible in the game. On top of that: vertex wave displacement on a `BoxMesh` (24 corner vertices, no interior tessellation) is effectively invisible even if drawn, and the water shader writes `ALPHA` without a `blend_mix` render mode, so it renders opaque, not 0.85 transparent.
- HEADLINE: the paddy scene is invisible even on its own. Verified by loading it: it instantiates with ONLY `CollisionShape3D` + an empty `VisualMesh` — the `MudBed`, `RiceCrops`, and `FieldSign` nodes are all dropped because each immediately follows a standalone `#` comment line (`# Mud Bed`, `# Wind Swaying Green Crops`, `# Burmese Field Signboard`) — the exact parser behaviour proven by the Slice 20 minimal repro. The trailing comment on the mud `albedo_color` line also corrupts its material (engine warning `#RichfertileMyanmaralluvialsoilroughness`).
- HEADLINE: the opponent's slice-22 fireflies do NOT appear in its world either. Verified by loading `world.tscn`: it instantiates with ZERO top-level nodes (every instanced sub-scene fails to parse — `player.tscn:52`, `rideable_cow.tscn:38`, and more), and `world_has_fireflies=false` — the `VillageFireflies` instance node is dropped by its own preceding `# Ambient Myanmar Village Fireflies & Night Particles` comment line. Standalone `#` lines are systemic in its tree: 22 in `world.tscn` alone, 92 across its scenes.
- "100% syntax purity" is STILL false: `scripts/myanmar_villager.gd` still fails `--check-only` (invalid assignment target — the Slice 19 defect, untouched by either commit), so its villager avoidance remains unreachable.
- The new horn/bell/trumpet/mute functions are DORMANT: zero callers anywhere in its tree (same pattern as its Slice 17 audio manager). The `world.tscn` `load_steps` arithmetic is wrong by 2 at both commits (d2a698e: 32 ext + 7 sub + 1 = 40 vs header 38; cc6fa2c: 33 + 7 + 1 = 41 vs header 39 — hint only, not a load failure).
- "10-minute loop acceleration" has NO supporting change: neither commit touches `day_night_cycle.gd`, and that script's cycle is 120 seconds (2 minutes), unchanged.
- Minor: its fireflies have no dark-only gating (they would glow in daylight too, unlike Muse's Slice 20 dark-only fireflies) — moot while the instance node is dropped.
- Note: the opponent's slice numbering now collides with Muse's — its slice-21/22 vs Muse's Slice 21 foundation work below. Different work, same numbers; the COLLAB entry distinguishes them by content.

## Milestone: Main menu + Pause + Save/Load foundation (Slice 21 — architecture, NOT a content batch)

This round builds the direction-independent foundation from the owner's 2026-10-22 master prompt (peaceful game, no combat — already true, nothing combat-related added). It serves the village world AND any future city district, and does not prejudge the pending village-vs-city direction choice. No item-count padding: this is one foundation, delivered completely, with deferred work stated plainly.

What works (all verified headlessly with the real Godot 4.3 binary):
- **Main menu** (`scenes/ui/main_menu.tscn`, now the game's entry scene — the menu-to-world transition was verified headlessly before switching the entry point): Continue (visible ONLY when a valid save exists, otherwise hidden with an honest "no save yet" label), New Game (fresh world), Settings. Title uses the original identity "Myanmar Open World".
- **Pause overlay** (HUD "ရပ်" button, top-left column, always visible): Resume (unpauses, panel hides), Save Game (writes the save, shows "သိမ်းဆည်းပြီးပါပြီ ✓" or an honest failure line), Settings (opens the working settings panel), Quit to Menu (saves first, unpauses BEFORE changing scene so the menu stays responsive). The pause panel processes input while paused; the game world truly freezes.
- **SaveManager autoload** (`autoload/save_manager.gd`): versioned JSON to `user://savegame.json` — player position + rotation, quest stage, talked villagers (by node NAME, because instance ids change every run), stamina, all 10 reward flags, all 22 HUD counters, crop/rice growth, plus a settings snapshot. Settings live separately in `user://settings.json` and are the authority at boot. Autosave fires on every quest-stage advance. Manual save from pause. Continue restores position, quest stage, rewards, counters, talked villagers (name-mapped to the new run's instance ids), stamina, and crop/rice growth scales.
- **Reward stats re-applied on load**: walk/sprint/jump multipliers are recomputed from the reward flags (walk 5.0 base, sprint 1.6, jump 5.0, then each earned reward's multiplier in award order) — a loaded late-game character moves exactly like the saved one.
- **Settings screen with ONLY working settings**: mute toggle (genuinely gates every generated tone, including the HUD mute button which now mirrors it) + master volume slider (genuinely scales tone volume via `volume_db`, silent at 0) + reset-to-defaults (really resets and saves). No decorative sliders, per the master prompt's hide-or-disable rule.
- **Corrupt-save safety, tested**: garbage file, wrong version (999), and missing file all load as "no save" — the menu hides Continue and the game starts fresh, no crash. Saving while driving restores the player on foot where they boarded (never inside a vehicle) — stated, not hidden.
- **All Slice 20 features kept**: night market, guest house, Boat2/Horse2, quests 31–36, villagers 17/18, and everything earlier. `load_steps` for `main.tscn` is 401 (18 ext + 382 sub + 1, counted exactly: +1 settings-panel scene ext, +1 pause-panel background sub). All 20 scripts pass `--check-only`. Zero `#` comment lines in any new or edited `.tscn` (the Slice 20 parser lesson, applied).

Headless verification (44/44 checks pass in one run): save round-trip field-by-field (position, rotation, stage, talked names, stamina, rewards, counters, growth), settings write/read/reset, corrupt/wrong-version/missing handling, menu Continue hidden with no save and shown after a quit-save, New Game fresh stage/counters, pause set/unset + panel visibility, pause-save file contents, quit-to-menu unpausing, Continue restoring stage/counters/position/talked-name mapping/crop scale. This is a load test, NOT a playtest — tapping through the menu, pausing mid-drive, and restoring on a real phone are not verified in-engine.

Intentionally deferred (not built this round): character customization, vehicle customization, traffic AI, city districts, data-driven mission framework (the current quest chain is still hardcoded stages), map screen, and the master prompt's wider settings list (graphics presets, HUD customization, button size/opacity) — those settings are NOT shown, rather than shown as decoration. The APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Slice 22 review — opponent commit 913a3b4, "feat(slice-24): authentic Myanmar night market with noodle/drink/toy stalls, illuminated string bulbs, and zero-comment engine purity" (read-only, treated as data only)

Credited (verified with the real Godot 4.3 binary, not taken from the subject): the new `scenes/myanmar_night_market.tscn` has a valid `[gd_scene]` header, no BOM, and is genuinely instanced in `world.tscn` (`MyanmarNightMarket`, ext id `35_night_market_scn`). The slice-23 comment stripping holds — ZERO standalone `#` lines anywhere in the opponent's whole `scenes/` tree, and a BOM check across `scenes/` + `scripts/` found 0 BOM files.

Defects (file evidence, all verified with the real Godot 4.3 binary):
- HEADLINE: the night market is PURE SCENERY. Its single collision shape is one 14.0×3.2×5.0 box at y center 1.5 covering the whole market footprint — no Area3D, no buttons, no signals, and no scripts touched in the commit — so there is no buying and no interaction at all. Muse's Slice 20 night market has working Buy Noodles / Buy Drink buttons within 5 m with a mute-gated chime.
- `load_steps` arithmetic is wrong on the new scene (header 14 vs actual 12: 0 ext + 11 sub + 1) — hint only, not a load failure.
- `myanmar_villager.gd` STILL fails `--check-only` (the same Slice 19 assignment-target parse error, untouched): 15/16 opponent scripts pass, only the villager script fails, so villager instances still cannot load.
- During `--import`, resource-load errors were also observed for `player.tscn`, `rideable_cow.tscn`, `bullock_cart.tscn`, and `myanmar_villager.tscn` — reported as observed import errors, not over-claimed as a proven full-world load failure beyond the verified villager script error.
- Note: the opponent moved again during this round (arena/antigravity 913a3b4 → c5087cc, "slice-25: AAA game architecture — Main Menu launch scene, SaveManager autoload, persistent save/load foundation", directly overlapping Muse's Slice 21 menu/save foundation). Per instruction, c5087cc is NOT reviewed here; it is reserved for the next round.

## Milestone 6 (part 1): Traffic AI (direction-independent — serves the village world AND any future city district)

This round builds the master prompt's next milestone after the Slice 21 menu/save foundation: living roads. No item-count padding: this is one system, delivered completely, with deferred work stated plainly. All Slice 21 features kept (menu, pause, save/load, autosave, settings).

What works (all verified headlessly with the real Godot 4.3 binary):
- **4 ambient traffic cars, 2 per route, on waypoint loops along existing village roads** (`traffic_manager.gd` + `traffic_car.gd` + `scenes/traffic_car.tscn`, one new `TrafficManager` node in `main.tscn`; `load_steps` 401 → 402 = 19 ext + 382 sub + 1). North loop (15 waypoints): entrance road threading the gate posts, then the north village roads. South loop (6 waypoints): pavilion/school quarter. Route clearances were checked against the real mesh sizes in `main.tscn`, not just node origins (tightest: House1 west wall 0.3 m, pagoda pillar ~0.4 m, paddy edge 0.2 m, pavilion edge 0.3 m, gate lantern ~0.7 m).
- **Believable movement**: top speed 6.0 m/s, acceleration 3.0, braking 9.0, turn rate 2.2 rad/s, waypoint advance within 2.0 m, spinning wheels. Cars start spread around their loop (same-route cars offset by half the loop) — the earlier twin-block deadlock (two cars sharing one spawn waypoint, each seeing the other inside the 2.5 m stop radius forever) was found by testing and fixed by this spreading.
- **Stop for anything ahead**: a car stops for the player, a villager, a player vehicle, or another traffic car within 2.5 m on any side or within 6.0 m inside a ~45° forward cone. Avoidance is STOP-ONLY (stated limit): a car never steers around, so it can never swerve through a building or into the player. It has NO physics body on purpose — a moving body could push or trap the player, and this is a peaceful game with no damage system anywhere. If the player walks into a stopped traffic car, nothing happens: no damage, no push, no launch.
- **Stuck-timeout keeps traffic flowing**: a car blocked continuously for 15 s is despawned and its slot refilled from a free waypoint. This was proven necessary by testing, not assumed: a parked player motorcycle on the north route jammed a car forever, and a villager lingering on the south road held two cars for 12+ s. With the timeout, the jammed car was replaced (new instance id) and drove on. Transient waits (a villager crossing) reset the timer and resolve on their own.
- **Responsible spawn/despawn**: initial spawn and far-respawn pick the waypoint nearest 35 m from the player inside a 25–45 m band (never on top of the player); a car beyond 75 m respawns only when such a waypoint exists (otherwise it keeps looping — respawning to a still-distant waypoint every tick would churn without bringing traffic near the player). Density is capped at 4, so low-end phones are not overloaded. The manager lives ONLY in `main.tscn`, so there is no traffic while the player is in the menu.
- **Day/night + pause respected**: headlights (emissive lamp boxes) turn on exactly when the day/night cycle is dark, using the same `daylight < 0.15` rule `day_night.gd` uses for the moon and stars — verified by forcing night and checking all 4 cars' lamps visible. Manager and cars use the default pause mode, so Slice 21's pause truly freezes traffic with the rest of the world (verified: positions identical across a paused window).
- **Traffic is NOT saved** (ambient; fresh cars spawn on load) and **NOT enterable** (ambient, not player vehicles) — both stated plainly; entering traffic is a later milestone.
- **All 22 scripts pass `--check-only`** (20 from Slice 21 + `traffic_car.gd` + `traffic_manager.gd`). Main scene + menu scene load headlessly with zero script/scene parse errors. Traffic test: 4 cars spawn with 12.49 m minimum separation, fleet moves tens of metres per 3 s window (stop-and-go behind villagers is correct behaviour, not a stall), a teleported car respawns 0.55 m from its expected waypoint, pause freezes positions. This is a load/simulation test, NOT a playtest.
- **Headless dummy-renderer note, stated honestly**: a bare headless load prints 4 `ERROR: Parameter "m" is null` lines (one per traffic car's unique mesh set) from the dummy renderer during the first frame only — never recurring, zero script/scene errors alongside them. The cause was narrowed by elimination (code-built meshes: 32 lines; scene meshes: 4; a single mesh in a fresh scene: 1; the same error fires once, not per frame), but the exact dummy-renderer mechanism is unproven. It does not affect logic (spawn/move/respawn/pause all verified) and does not occur on real devices, which use the real renderer, not the dummy. The car wheels were switched from CylinderMesh to BoxMesh during this investigation (same primitive-mesh art style as the rest of the game).

Intentionally deferred (not built this round): enterable traffic vehicles, traffic signals, intersection priority, pedestrian schedules, steering-around avoidance (stop-only in v1), and traffic on future city roads (routes cover the village roads only). Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Milestone 6 (part 2): living-city depth — traffic variety + time-of-day traffic + villager schedules (direction-independent — serves the village world AND any future city district)

This round deepens part 1's living roads instead of adding another content batch. No item-count padding: this is two systems, delivered completely, with deferred work stated plainly. All Slice 21 features kept (menu, pause, save/load, autosave, settings) and all part 1 traffic behaviour kept (stop-only avoidance, stuck-timeout, spawn/despawn bands, pause freeze, headlights, not enterable, not saved).

What works (all verified headlessly with the real Godot 4.3 binary):

- **Traffic variety: a second vehicle type, the van.** `scenes/traffic_van.tscn` reuses `traffic_car.gd` (same node names, same model) with a distinct body: 1.7 m wide, 0.9 m tall, 4.4 m long, taller cabin, bigger wheels, top speed 5.0 m/s (heavier than the car's 6.0). The fleet is 6 slots: north loop runs car, van, car; south loop runs van, car, van — both routes mixed. Vans are ambient like cars: no physics body, not enterable, not saved, same stop-only model.
- **Exact time-of-day rule (one shared daylight value).** `day_night.gd` now exposes `daylight()` (0.0 deep night → 1.0 noon; the `< 0.15` dark rule is the same one the moon, stars, fireflies, and headlights already used). TrafficManager reads it once a second and applies: daylight >= 0.6 (midday) → all 6 slots at speed factor 1.0; 0.15 <= daylight < 0.6 (morning/evening) → 4 slots (north car + van, south van + car) at 0.85; daylight < 0.15 (night) → 2 slots (north car, south van) at 0.7. Shrinking despawns the extra vehicles outright (the same despawn the stuck-timeout already used); growing refills empty slots from the same 25–45 m band, never on top of the player. Total stays capped at 6, so low-end phones stay safe.
- **Villager daily schedules, first version.** `npc.gd` gains a `day_anchor` export (Vector3.ZERO = no schedule: that villager always wanders around home, which is the default for 15 of 18 villagers). With a day_anchor set, the villager wanders around day_anchor while it is day (daylight >= 0.15) and around home at night. Wired in `main.tscn` for Villager1, Villager2, and Villager3 (day_anchor (14, 0, 14), the market-stall area around MarketStallA at (16, 12)): by day they gather at the market, at night they walk home. The shift is a WALK, never a teleport — only the wander centre changes and the next picked target is around the new centre, so the villager walks there through the normal circle-avoidance steering (a market commute takes ~21 s at villager walk speed, inside the ~54 s day band of the 120 s cycle). A villager mid-conversation is NEVER yanked away: if the band changes while talking, the shift is deferred and applied when the talk ends (verified headlessly: a talking villager's wander centre stayed home across a forced midday flip).
- **Longer vehicles never overlap (Slice 22 wart fixed).** Slice 22 stopped at a fixed 2.5 m centre distance, which meant a follower's front visually overlapped the leader's rear by 0.7 m (worse for a 4.4 m van). Part 2 stops at own half-length + the longest other traffic half-length (2.2 m) + a 0.4 m gap: cars stop at 4.2 m centre distance, vans at 4.8 m, with the forward cone 3.5 m beyond that. Cars now stop with a visible gap instead of overlapping bumpers; the stop-only rule itself is unchanged.
- **Verification (load/simulation test, NOT a playtest).** All 22 scripts pass `--check-only` (no new script files: the van reuses `traffic_car.gd`). `main.tscn` `load_steps` unchanged at 402 (no new nodes or resources added to the world scene; the three day_anchor lines are plain properties) and the van scene counts exactly 9 (1 ext + 7 sub + 1). Zero `#` comment lines in the new/edited scenes. Simulation, forced through the real clock: midday → 6 vehicles (3 vans, speed factor 1.0), morning/evening (daylight 0.30) → 4 vehicles (2 vans, 0.85), deep night → 2 vehicles (1 van, 0.7, headlights on); Villager1's wander centre moved market → home across a forced day/night flip with no errors; menu scene still loads and instantiates. One headless-test lesson, recorded in the test script: a world added to the tree during MainLoop `_initialize` never enters the tree (`_ready` never runs, `get_tree()` null in player `_ready`) — the test adds the world on the first `_process` frame instead. Pause freeze is unchanged from part 1 (default pause mode; no code fights the pause) and was not re-run this round.

Intentionally deferred (not built this round): enterable traffic vehicles, traffic signals, intersection priority, steering-around avoidance (stop-only stays — stated again, deliberately), per-villager schedules for the other 15 villagers (mechanism ready; only 3 wired in v1), schedules affecting quests or shops, traffic on future city roads. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Camera collision avoidance (direction-independent — serves the village world AND any future city district)

This round closes the master prompt's section 6 gap: the third-person follow camera used to sit at its desired position no matter what stood in the way, so it clipped straight through houses, the pagoda, and stalls. No item-count padding: this is one system, delivered completely, with deferred work stated plainly. All Slice 23 features kept (menu, pause, save/load, traffic variety + time-of-day density, villager schedules) and no vehicle or traffic behaviour changed.

What works (all verified headlessly with the real Godot 4.3 binary):

- **Spring-arm raycast shortening in `camera.gd`.** Every frame the camera casts a ray from the player's eye point (head height, 1.6 m) to its desired position. When a wall or building blocks the ray, the camera shortens toward the player instead of passing through the geometry. Shortening is fast (14 m/s) so a wall is never crossed for even a frame; recovery is slow (2.5 m/s) so the camera glides back out when the obstruction clears instead of snapping. The offset direction and height scale together, so the viewing angle stays the same while shortened.
- **Both ray directions, so standing inside a building footprint still works.** A ray starting inside a shape reports no hit, and the player CAN stand inside a house footprint (houses have no gameplay collision). So the camera also casts the reverse ray, camera-to-eye: when the player is inside a building, the reverse ray hits the wall from the outside and keeps the camera outside it.
- **Characters and vehicles never block the camera.** The ray excludes every physics body that is not a StaticBody3D — the player, ridden vehicles, villagers, and rideable animals. A villager walking behind the player therefore never yanks the view, and a ridden vehicle never blocks its own camera. Only real geometry blocks: the pagoda, bridges, stalls, ground, and the new blocker volumes below.
- **Camera-blocker volumes for collision-less houses.** Most village houses are bare meshes with no physics body, so a raycast alone could not see them. Thirteen invisible StaticBody3D volumes now cover them (`main.tscn` `load_steps` 402 → 415 = 19 ext + 395 sub + 1; zero `#` comment lines added): House1–5, House6, House7, House8, the school, three stilt houses, and the lakeside hut. They sit on collision layer 2 only, so they are invisible to gameplay — the player, villagers, and traffic (all on layer 1) walk through them exactly as before; only the camera's ray (mask layers 1 + 2) sees them.
- **Narrow spaces and the ground.** The camera never gets closer than 1.2 m to the player, and never drops below 0.5 m above the player's feet, so it cannot end up inside a wall or under the ground in a narrow gap. When the player hugs a wall closer than ~1.6 m, the 1.2 m minimum can leave the camera resting exactly on the wall face (not inside it) — stated as the one edge case.
- **Existing camera behaviour untouched.** Follow, touch-drag orbit (right half of screen), zoom buttons (0.6–1.8), the camera reset button, and the on-foot/driving target switch (vehicles retarget the camera on enter and back to the player on exit) all work exactly as before — the avoidance only scales the distance along the existing orbit direction.
- **Verification (load/simulation test, NOT a playtest).** All 22 scripts pass `--check-only`. Main scene + menu scene load headlessly with zero script/scene errors. Camera simulation, 9/9 checks green: standing beside House1 with the camera aimed through it shortens the camera from 10 m to the 1.2 m minimum with the camera position outside (on the face of) the blocker volume; moving to open ground recovers the full 10 m; zoom in/out, touch-drag orbit, camera reset, and driving retarget (camera following the car) all still work. This is a load/simulation test, NOT a playtest — real-device camera feel (smoothing rates, narrow-street behaviour on a phone screen) is unverified.

Intentionally deferred (not built this round): first-person view, camera collision for traffic cars (they are position-based Node3D with no physics body, so the ray cannot see them — a passing traffic car can briefly overlap the camera view), blockers for open structures (tea shop, guest house posts-and-roof, market stalls without bodies) and for the bamboo workshop / fishing hut (both sit at odd heights in the existing scene — a pre-existing placement oddity, not touched this round), and any change to player collision (the player can still walk through house meshes; only the camera is blocked). Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Visual atmosphere, part 1 (direction-independent — serves the village world AND any future city district)

This round polishes how the world LOOKS without touching how it PLAYS: no vehicle, traffic, NPC, or quest behaviour changed. No item-count padding: this is one visual pass, delivered completely, with deferred work stated plainly. All camera-avoidance features kept (spring-arm shortening, layer-2 blockers, orbit/zoom/reset), and menu, pause, save/load, traffic, and schedules untouched.

What changed (all verified headlessly with the real Godot 4.3 binary):

- **Ground surfaces now have distinct material identities.** Dirt roads (PathA, PathB, all PathS11 paths, RiversidePath14) use a new shared dirt material (warm brown, roughness 1.0); stone plaza and slabs (Plaza, statue/road/festival/path slabs) use a new shared stone material (light grey, roughness 0.85); grass patches use a deeper-green tuft material (roughness 1.0, distinct hue from the ground plane); paddy floors use a wet-mud material (dark brown, roughness 0.5 — visibly wetter than dry dirt). Previously these were mostly one flat `path` brown or per-slice one-offs; now each surface type reads differently in light. No external textures imported — only Godot built-in StandardMaterial3D properties (albedo, roughness, metallic).
- **Vehicle bodies get real paint.** Car body, motorcycle frame, airplane fuselage, helicopter body, and tuk-tuk body now use glossy paint materials (roughness 0.25–0.3, metallic 0.35–0.5) instead of the old flat 0.4-roughness colours — same hues, more light response. Wheels, tires, and canopies are untouched.
- **Walls vs roofs, made explicit.** Early-house and school roofs now share one terracotta roof material (warm red-brown, roughness 0.7). The split that already existed visually is now deliberate: cream/brown/teak walls, terracotta roofs, thatch on the stilt houses (kept distinct), gold on pagoda metalwork (kept), white stone on the pagoda platform/plinth (kept).
- **Golden-hour sunlight.** `day_night.gd` now shifts the sun's COLOUR with time of day, not just its brightness: neutral white at noon (daylight >= 0.6), warming through gold as the sun drops (daylight 0.15–0.6), cool dim blue at night (daylight < 0.15). Sun energy is unchanged (0.05 + daylight * 1.15) and `daylight()` itself is unchanged, so the `< 0.15` dark rule that moon, stars, fireflies, and headlights already use still holds exactly.
- **Night window lights.** Eleven houses and the school now show warm windows after dark: one shared emissive window material (warm 1.0/0.72/0.32 glow) on small quads mounted on House1–5, both stilt-house walls, House6, House7, House8, and the school walls. The material's emission flag flips with the same `< 0.15` dark rule — one flag flip for all windows, no new lights per window, so there is no per-window performance cost. The tea shop, guest house, and zayat are open post-and-roof structures with no walls, so windows do not apply to them — stated, not faked.
- **Water that reads as water.** The pond now uses a genuinely transparent water material (transparency mode set to alpha, 0.7 alpha, roughness 0.15) instead of opaque blue. The river and well water already used transparent materials and are unchanged. This is deliberately NOT the broken approach of writing alpha without a blend mode, which renders opaque.

- **Verification (load/simulation test, NOT a playtest).** All 22 scripts pass `--check-only` (day_night.gd edited, no new scripts). `main.tscn` `load_steps` 415 → 429 (19 ext + 409 sub + 1, counted exactly: 12 new shared materials + 2 new window meshes; the 11 window nodes add no load steps). Zero `#` comment lines added. Forced-clock headless test: noon → sun colour white (1,1,1), energy 1.2, windows off; golden hour (daylight 0.34) → sun colour warm (1, 0.86, 0.68), windows off; night (daylight 0) → sun colour cool (0.45, 0.55, 0.85), energy 0.05, windows on, moon and fireflies visible; pond transparency mode = 1 with 0.7 alpha, river already 1; all 11 window nodes present sharing the one material day_night toggles; main scene runs 5 frames and the menu scene loads with zero script/scene errors. One real defect caught and fixed by the test: two window nodes were first parented to `House6Walls` and `SchoolWalls13`, but those meshes live under the `House6` and `School13` groups, so the engine dropped the windows at instantiate ("parent path has vanished") — fixed to the full paths `House6/House6Walls` and `School13/SchoolWalls13`, re-verified 11/11 present.

Intentionally deferred (not built this round): real textures (none imported — this pass is material properties only), shadow tuning beyond the current shadow-enabled sun, post-processing or colour grading, window lights for open structures (no walls to mount them on), and any change to the day length (still 120 s). Honest statement: visual beauty CANNOT be verified headlessly — the numbers above prove the materials, colours, and toggles exist and change correctly, but whether the village actually looks premium at golden hour or at night needs the owner's on-device verdict; no "premium visuals" claim is made here. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Car driving physics (direction-independent — serves the village world AND any future city district)

This round polishes how ONE vehicle drives — the player car (master prompt section 8: "begin with one polished, functional car before adding more vehicles"). No item-count padding: this is one system, delivered completely, with deferred work stated plainly. All Slice 25 features kept (atmosphere materials, golden-hour sun, night windows, transparent water), and no other vehicle, traffic, NPC, quest, menu, or save behaviour changed. Touch joystick steering stays the primary input; arrow keys / WASD remain a desktop-debug fallback only.

What changed (all in `car.gd` only — no scene file touched, so `main.tscn` `load_steps` stays 429 and no `#` comment risk arises):

- **Acceleration curve.** The old car accelerated at a flat 8.0 units/s^2 from standstill to top speed. Now the launch is soft (0.55x at standstill, so the car does not jerk away), pull is full through the mid-range, and acceleration tapers to 0.5x near top speed (so top speed is approached, not slammed into). Top speed is unchanged at 14.0 units/s (50.4 km/h) on purpose: `player.gd`'s HUD SpeedBar uses vmax["Car"] = 14.0, so changing it would break the bar.
- **A real brake.** The old car had no brake: holding reverse just decelerated at the same 8.0 rate, then rolled backwards. Now reverse input while moving forward brakes at 16.0 units/s^2 (twice the acceleration) and never rolls the car backwards by itself; reverse only engages from near-stop (speed <= 0.5), capped at 0.35x top speed.
- **Speed-dependent steering.** The old turn rate was a constant 1.8 rad/s at every speed — equally twitchy at 50 km/h as at walking pace. Now steering is agile at low speed (2.2 rad/s) and stable at top speed (0.85 rad/s), interpolated by speed ratio.
- **Steering smoothing and turn scrub.** Steering input is smoothed toward the target at 8.0/s instead of snapping, and a hard turn at speed bleeds a little speed (turn scrub 1.2) — the weight/momentum feel. Rolling drag is gentler (2.5/s instead of 4.0/s), so the car keeps its momentum when the driver lifts off.
- **Wheels that roll.** The car's four wheel meshes previously never moved. They now rotate at ground speed (spin rate = speed / 0.35 m wheel radius) around their true axle. One real defect was caught by the headless world test and fixed before commit: plain `rotate_y` turns a wheel about the parent Y axis (a steering-like yaw), not its axle — the fix is `rotate_object_local` around local Y, verified below.

Verification (load/simulation test, NOT a playtest). All scripts pass `--check-only`. Main scene + menu scene load headlessly with zero script/scene errors. The same headless driving harness drove the REAL `car.gd` before and after, full joystick input, and measured:

- 0 to 95% of top speed: 1.68 s before, 2.25 s after (slower outright, by design — soft launch plus taper; top speed itself unchanged at 14.00).
- Braking from top speed to stop: 1.77 s / 12.4 m before, 0.95 s / 6.3 m after (about half the stopping distance).
- Coasting from top speed to stop: 3.52 s / 24.6 m before, 5.60 s / 39.1 m after (momentum feel).
- Reverse top speed: -5.60 before, -4.90 after (the new 0.35x cap).
- Turn rate at low speed (2–4 units/s): 103.1 deg/s before, 110.3 deg/s after (slightly more agile).
- Turn rate at high speed (above 12 units/s): 102.3 deg/s before, 47.1 deg/s after (stable at speed — the key fix).
- In-world contract, all green: enter sets the driver and retargets FollowCamera to the car, 1 s of full throttle reaches speed 6.33 and moves the car from (4, 1, 0) to (4, 1, -2.87), exit clears the driver, zeroes speed, and steps the driver out beside the car at (6, 1.5, -2.87), menu scene loads. Wheel roll verified exactly: 8.19 rad of wheel spin over that 1 s against 2.87 m travelled / 0.35 m radius = 8.19 rad — rolling without slipping.

Intentionally deferred (not built this round): VehicleBody3D migration (the kinematic CharacterBody3D model already preserves enter/exit, Slice 24 camera collision, and the HUD readout; a physics-body swap would rework collision, wheels, and camera retargeting for no measured benefit — stated, not hidden); physics tuning for every other vehicle (cart, motorcycle, airplane, helicopter, cow, boat, bicycle, tuk-tuk, elephant, horse all keep their existing behaviour exactly); handbrake, turn signals, cruise control, and vehicle customisation (master prompt section 8 items not built here). Honest statement: driving FEEL cannot be verified headlessly — the numbers above prove the tuning curves, stopping distances, and steering rates behave as designed, but whether the car actually feels satisfying on a phone screen needs the owner's on-device verdict; no "satisfying handling" claim is made here. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Motorcycle driving physics (direction-independent — serves the village world AND any future city district)

This round polishes how ONE more vehicle rides — the player motorcycle (master prompt section 8, one vehicle at a time, following the Slice 26 car pattern). No item-count padding: this is one system, delivered completely, with deferred work stated plainly. All Slice 30 features kept (character customization, villager schedules for all 18, world map, mission framework, car physics, camera avoidance, menu/pause/save/load, traffic + schedules), and no other vehicle, traffic, NPC, quest, map, menu, or save behaviour changed. Touch joystick steering stays the primary input; arrow keys / WASD remain a desktop-debug fallback only.

What changed (all in `motorcycle.gd` only — no scene file touched, so `main.tscn` `load_steps` stays 431 and no `#` comment risk arises):

- **Acceleration curve.** The old bike accelerated at a flat 11.0 units/s^2 from standstill to top speed. Now the launch is soft (0.55x at standstill, so the bike does not jerk away), pull is full through the mid-range, and acceleration tapers to 0.5x near top speed (so top speed is approached, not slammed into). Top speed is unchanged at 18.0 units/s (64.8 km/h) on purpose: `player.gd`'s HUD SpeedBar uses vmax["Motorcycle"] = 18.0, so changing it would break the bar.
- **A real brake.** The old bike had no brake: holding reverse just decelerated at the same 11.0 rate, then rolled backwards (the before-test ended at -0.15). Now reverse input while moving forward brakes at 22.0 units/s^2 (twice the acceleration) and never rolls the bike backwards by itself; reverse only engages from near-stop (speed <= 0.5), capped at the old 0.3x top speed (-5.4, unchanged).
- **Speed-dependent steering.** The old turn rate was a constant 2.6 rad/s (149 deg/s) at every speed — equally twitchy at 65 km/h as at walking pace. Now steering is agile at low speed (2.6 rad/s, unchanged) and stable at top speed (1.2 rad/s), interpolated by speed ratio.
- **Steering smoothing and turn scrub.** Steering input is smoothed toward the target at 8.0/s instead of snapping, and a hard turn at speed bleeds a little speed (turn scrub 1.0) — the weight/momentum feel. Rolling drag is gentler (2.5/s instead of the old 5.5/s coast decay), so the bike keeps its momentum when the rider lifts off.
- **Speed-weighted lean banking.** The old bike tilted its body mesh a fixed 0.25 rad (14.3 deg) on any steer input, even standing still. Now lean is proportional to smoothed steer AND speed ratio, capped at 0.5 rad (28.6 deg): upright at standstill, leaning into turns at speed. Sign convention kept from Slice 3; only the body mesh tilts (wheels stay upright, as before — no scene change).
- **Wheels that roll.** The bike's two wheel meshes previously never moved (the old code had no wheel code at all). They now rotate at ground speed (spin rate = speed / 0.35 m wheel radius) around their true axle via `rotate_object_local` around local Y — the same lesson as the Slice 26 car fix (plain `rotate_y` would yaw the wheels like steering instead of rolling them).

Verification (load/simulation test, NOT a playtest). All scripts pass `--check-only`. Main scene + menu scene load headlessly with zero script/scene errors. The same headless riding harness drove the REAL `motorcycle.gd` before and after, full joystick input, and measured:

- 0 to 95% of top speed: 1.57 s before, 2.08 s after (slower outright, by design — soft launch plus taper; top speed itself unchanged at 18.00).
- Braking from top speed to stop: 1.65 s / 14.6 m before, 0.87 s / 7.2 m after (about half the stopping distance; ends at ~0 instead of rolling into reverse).
- Coasting from top speed to stop: 3.28 s / 29.3 m before, 7.20 s / 64.7 m after (momentum feel).
- Reverse top speed: -5.40 before, -5.40 after (the 0.3x cap, unchanged on purpose).
- Turn rate at low speed (2 units/s, 0.25 s window including the smoothing ramp): 149 deg/s before, 110.8 deg/s after (still agile; the drop is the smoothing ramp — the old code snapped instantly).
- Turn rate at high speed (18 units/s, same window): 149 deg/s before, 70.6 deg/s after (stable at speed — the key fix).
- Lean at full steer + top speed: -0.25 rad (14.3 deg, fixed) before, -0.50 rad (28.6 deg, the cap) after.
- Wheel roll over 1 s full throttle at top speed: 0 rad before (no code), 51.43 rad after against 18.0 / 0.35 = 51.43 rad expected — rolling without slipping, exactly.
- In-world contract, all green: enter via the real player enter flow sets the driver and retargets FollowCamera to the bike, 1 s of full throttle reaches speed 8.91 and moves the bike forward ~4.4 m (speed integral 4.14 m; the small gap is move_and_slide using the engine physics delta while the harness steps with fixed 1/60 — in real play both use the same physics delta), exit clears the driver, zeroes speed, steps the driver out beside the bike (0.00 m error against the expected step-out point), retargets the camera to the player, and the player is no longer driving; menu scene loads.

Intentionally deferred (not built this round): VehicleBody3D migration (same reasoning as the car — stated, not hidden); physics tuning for every other vehicle (car keeps its Slice 26 tuning; cart, airplane, helicopter, cow, boat, bicycle, tuk-tuk, elephant, horse all keep their existing behaviour exactly); handbrake, turn signals, cruise control. Honest statement: riding FEEL cannot be verified headlessly — the numbers above prove the tuning curves, stopping distances, steering rates, lean, and wheel roll behave as designed, but whether the bike actually feels satisfying on a phone screen needs the owner's on-device verdict; no "satisfying handling" claim is made here. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Mission framework (direction-independent — serves the village world AND any future city district)

This round is STRUCTURE, not new content (master prompt milestone 7: peaceful missions framework — title/objectives/waypoints/timer/checkpoints/rewards/restart/persistence, free roam always available). No new quests, no new rewards, no behaviour change: the existing 36-stage chain plays exactly as before, but it is now data, not scattered code. No item-count padding: this is one system, delivered completely, with deferred work stated plainly. All Slice 26 features kept (car physics, atmosphere materials, golden-hour sun, night windows, transparent water, camera avoidance, menu/pause/save/load, traffic + schedules). No scene file touched, so `main.tscn` `load_steps` stays 429 and no `#` comment risk arises.

What moved, and where it lives now:

- **New file `autoload/mission_data.gd` — the chain as data.** The 36 tracker words, the 36 quest-label texts, and the 10 done texts are copied byte-for-byte from the old `player.gd` elif chain (extracted programmatically, not retyped). The trigger table IS the chain: 36 rows mapping a trigger name to its from-stage, to-stage, and reward id (for example `ring_bell: 3 -> 4, r1`; `sleep: 35 -> 36, r10`). The reward table holds each reward's exact effects (r2 walk x1.1; r3 walk x1.05; r4 walk x1.05 + stamina refill; r5 sprint x1.1; r6/r7 walk x1.05 + jump x1.1; r8/r9 walk x1.05 + stamina refill; r10 walk x1.05 + jump x1.1 + stamina refill; r1 stamina-only — drain 12.5 / regen 30.0, read as a flag). Adding a future mission means adding table rows (plus its title/label) — no handler-code change for the link itself.
- **New autoload `autoload/mission_manager.gd` (`MissionManager`, registered in `project.godot` next to `SaveManager`) — the single source of truth for mission state.** It owns the current stage, the 10 reward flags, and all 22 interaction counters. `advance(trigger)` fires only when the current stage matches the trigger's from-stage, so out-of-order calls are silent no-ops — exactly like the old `if quest_stage == X` guards — and returns whether it advanced and which reward (if any) was newly granted, so a flag already set never re-applies. `promote_talk_all()` holds the talk-all rule (stage 0 -> 1 once every villager is talked to). `label_text()` / `tracker_text()` / `counter_text()` render the HUD strings from the tables. `stats_multipliers()` reproduces the old load-time stat math in the same r2..r10 order. `load_state()` reads a save dictionary through the same keys, so a Slice 26 save maps onto the new manager unchanged.
- **`player.gd` keeps only the world side.** Positions, buttons, proximity checks, growth scales (sesame/rice plants), stamina, and talked villager instance ids stay in the player. Every old stage assignment became a manager call: physics checks (gate, bridge, hut, pagoda, bell) advance on proximity; vehicle entry advances on the ride triggers (vehicle-name guards stay handler-side — Bicycle, TukTuk, Elephant, Horse, Boat2, Horse2); button handlers advance on their triggers and apply a newly granted reward through `_apply_reward()`. The label-update placement of every handler is preserved exactly: handlers that refreshed the quest label unconditionally still do (buy fruit, tea, book, banana, water draw), and handlers that refreshed it only on advance still do (pray, drum, fish, donate, milk, crops, chickens, offer, plant, rest, elephant feed, gold, lesson, horse feed, noodles, guestbook, sleep, parachute stow, bell, vehicle entry). Two old quirks are preserved on purpose and documented here, not "fixed" silently: while stage 0 is incomplete the label refresh returns before touching the tracker (so the tracker keeps its scene text until stage 1), and `elephant_feed` is saved but was never displayed in the HUD counter line (still saved, still not displayed).
- **Save/load keys are unchanged.** `collect_save_data()` still writes `quest_stage`, `rewards` (r1..r10), `counters` (all 22 keys), `talked_names`, `stamina`, `growth`, `settings`, `player` — only the values now come from the manager. Autosave still fires on stage change; pause save and quit-to-menu save the same dictionary. `SaveManager` itself is untouched (version 1, corrupt/wrong-version/missing files still load as "no save").
- **New-mission format (documented in `mission_data.gd`, not yet live).** A future mission entry needs: id, from_stage/to_stage, reward, title, label, waypoint (world position or null), timer_seconds (0 = none), checkpoints (list, empty = none). Waypoint, timer, and checkpoint fields exist in the format now but are NOT live systems yet — no mission uses them until one is built. The worked example in the data file duplicates stage 1 exactly and is NOT activated.

Verification (load/simulation test, NOT a playtest). All 24 scripts pass `--check-only` (two new files included). Mission unit simulation, 109 checks green: fresh state (stage 0, all rewards false, all counters 0); out-of-order triggers (`sleep` at stage 0, unknown trigger, incomplete talk-all, zero villagers) are all no-ops; the full 36-trigger chain advances stage by stage with rewards firing in order r1..r10 exactly once each, and re-firing `sleep` at stage 36 is a no-op; label texts spot-checked (stage 0 with counts, stage 1, stage 7 banana count capped at 3, stage 36 r10 done text); tracker all-unchecked at 0, all-checked at 36; full-completion multipliers (walk 1.1 x 1.05^7, sprint 1.1, jump 1.1^3) and a Slice 26 old save (stage 17, r1..r5, fruit 3 / banana 3) loading with identical stage, flags, counters, and multipliers. In-world integration, 12/12 green: main + menu scenes load and instantiate with zero script/scene errors; `MissionManager` autoload present; world starts at stage 0 with no pending save; talk-all promotion shows the stage 1 label; driving the manager through the full chain in-world reaches stage 36 with the r10 done label and all-checked tracker; autosave writes a version-1 file with quest_stage 36 and all rewards true. Test-harness lesson learned this round (recorded so the next worker does not repeat it): a `SceneTree` test script's `_initialize()` is void — returning true there does NOT quit; the quit signal is `_process()` returning true, so tests must do their work on the first `_process` frame (the same lesson as Slice 23's "world added in `_initialize` never enters the tree").

Intentionally deferred (not built this round): new mission types (sightseeing, delivery, taxi, parking, time trials, photography) as playable content; waypoint markers, mission timers, and checkpoints as live systems (format fields only); mission restart UI; crop/rice growth moved into the manager (growth stays in the player because it drives plant scales, not mission state); VehicleBody3D migration (unchanged from Slice 26). Honest statement: the framework's behaviour is proven headlessly — tables, transitions, rewards, labels, tracker, save round-trip, and old-save compatibility — but a full real playthrough (talking, riding, buying, sleeping through all 36 stages on a phone) has not been done, so any playthrough-level surprise would still need the owner's on-device verdict; no "playtested" claim is made here. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## World map (direction-independent — serves the village world AND any future city district)

This round is a WORKING world map (master prompt section 10: minimap + world map with zoom/pan/waypoints/filters), built to beat the opponent's slice-35 map on every point that map failed. No item-count padding: this is one system, delivered completely, with deferred work stated plainly. All Slice 27 features kept (mission framework, car physics, atmosphere materials, golden-hour sun, night windows, transparent water, camera avoidance, menu/pause/save/load, traffic + schedules); no vehicle, traffic, NPC, quest, or visual behaviour changed.

What works, and how it differs from the opponent's dead map:

- **The button is actually connected.** `MapButton28` ("🗺 မြေပုံ", below the minimap) is wired lazily by `player.gd` like every other HUD button, and the headless test proves it: emitting the button's `pressed` signal opens the overlay and pauses the tree. The opponent's slice-35 MapBtn was never wired (zero references anywhere in its scripts) and its HUD script could not even load.
- **Landmark markers come from real world positions.** Six landmarks — pagoda, market, pier, school, guest house, festival ground — are read from their actual scene nodes every frame the map is open and placed through one documented transform: world metres (-50..50 on x/z, the same span the minimap uses) map linearly onto the square map area, scaled by zoom and shifted by pan. The test checks all six dots against independently computed expected positions (within 1.5 px). The opponent's markers were fixed canvas offsets that never moved with the world.
- **The player marker is clamped.** Teleporting the player far outside the world leaves the marker pinned inside the map area (the opponent's flew off its 640×400 canvas). Landmarks are not clamped — they stay true to the transform and are clipped by the map area instead.
- **Tap-to-set waypoint, and it is a marker + bearing only.** Tapping the map sets a waypoint (tap again to move it, "လမ်းကြောင်း ဖျက်" to clear it). It shows in three places: a red dot + ★ on the map, a red dot on the minimap (the minimap mirrors the overlay's waypoint through the same transform family), and a tall red emissive beacon in the world (`WaypointBeacon28`, a real scene node reusing the window box mesh with its own red emissive material). The overlay's info line shows bearing in degrees and distance in metres, labelled in Burmese as a guide only ("လမ်းညွှန်သာ — လမ်းကြောင်းရှာခြင်း မပါ"): there is NO routing, NO pathfinding, and no claim of either.
- **Zoom + pan keep markers consistent.** Touch-friendly ＋/－ buttons (0.5×–3×) and drag-pan move the map; the test verifies a landmark dot still matches its world position after zoom 2× + pan, and the player marker stays clamped.
- **Pause state is restored exactly.** Opening records whether the tree was already paused; closing restores that exact state (tested both ways: unpaused → unpaused, paused → paused). The panel uses pause mode always so its buttons work while the tree is paused; the pause menu underneath stays untouched.
- **Scene accounting is exact.** `main.tscn` `load_steps` 429 → 431 (one new script ext-resource + one new beacon material sub-resource; the button, waypoint dot, panel, and beacon nodes reuse existing resources and add nothing). Zero `#` comment lines added to the scene. The beacon is a scene node on purpose: an earlier runtime-created beacon mesh tripped a dummy-renderer warning in headless runs (harmless on device, but a scene node is cleaner and the warning is gone — the final test run prints zero errors).

Verification (load/simulation test, NOT a playtest). All 25 scripts pass `--check-only` (world_map.gd included). Map simulation, 30/30 green: panel hidden initially; MapButton exists and is visible (wired); pressing it opens the overlay and pauses; all six landmark dots match real node positions; world→map→world round-trips exactly; player marker clamps at the world edge and after zoom+pan; waypoint tap computes the correct world coordinates, mirrors to the minimap dot at the right position, and shows the in-world beacon; zoom+pan keeps landmarks consistent; clear hides the minimap dot and beacon; close restores pause state both ways; main + menu scenes load with zero script/scene errors. Two test-harness notes: a `SceneTree` test script has no `get_tree()` (use the tree's own `paused` property), and inferred-Variant locals are errors in this project, so test locals need explicit types. Honest statement: the transform math, wiring, clamping, waypoint round-trips, and pause bookkeeping are proven headlessly, but touch feel and map readability on a phone cannot be verified headlessly — they need the owner's on-device verdict; no "reads beautifully on a phone" claim is made.

Intentionally deferred (not built this round): navigation/pathfinding to the waypoint (marker + bearing only, as stated); landmark filters (all six landmarks always shown — no filter toggles yet); waypoint persistence across saves (the waypoint lives for the session; save/load keys unchanged from Slice 27); pinch-to-zoom (button zoom only — pinch is a later touch refinement); a larger landmark set (only the six required landmarks; the minimap's full dot set is untouched). Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Villager schedules v2 — all 18 villagers (direction-independent — serves the village world AND any future city district)

This round completes the Slice 23 schedules v1, which wired only Villager1/2/3. No new mechanism, no behaviour change to anything else: the same `npc.gd` `day_anchor` rule, the same daylight rule, the same walk-not-teleport shift, the same mid-conversation deferral. The only change is 15 `day_anchor` property lines in `main.tscn` — no new script, no new node, no new resource, so `main.tscn` `load_steps` stays 431 and zero `#` comment lines were added. All Slice 28 features kept (working world map, mission framework, car physics, camera avoidance, traffic, visuals, menu/pause/save/load); save keys unchanged (schedules are live state, not saved state — a villager's wander centre is recomputed from the clock on load, so old saves load unchanged).

Day = the villager's workplace (their stall, shop, school, or gathering place); night = home (their spawn point). Every anchor is a real in-scene position, not an invented location:

| Villager | Home (night) | Day anchor (workplace) |
|---|---|---|
| Villager1 မောင်မောင်လွင် | (-10, -10) | (14, 14) day market |
| Villager2 ဦးဖိုးသော် | (12, 8) | (14, 14) day market |
| Villager3 ဒေါ်မြ | (-2, -15) | (14, 14) day market |
| Villager4 ဈေးသည် မမ (market vendor) | (19, 13) | (14, 14) day market centre |
| Villager5 ဂိတ် ဦးဘ (gatekeeper) | (4, 24) | (0, 26) village gate |
| Villager6 တံငါသည် ဦးထွန်း (fisherman) | (14, 38) | (10, 41) pier |
| Villager7 လက်ဖက်ရည်ဆိုင် ဦးအောင် (tea owner) | (-10, 16) | (-14, 20) tea shop |
| Villager8 ဆရာတော် ဦးဇင်း (monk) | (-28, 8) | (-20, -25) pagoda |
| Villager9 ပွဲစီစဉ်သူ ကိုအောင် (festival organiser) | (39, -34) | (42, -33) festival ground |
| Villager10 အကသမား မသီတာ (dancer) | (45, -35) | (42, -34) festival mat |
| Villager11 ပန်းပဲဆရာ ဦးမောင် (blacksmith) | (-38, -12) | (-40, -12) forge |
| Villager12 အိုးသည် မလှ (potter) | (42, 6) | (40, 6) pottery wheel |
| Villager13 ရွှေဆိုင် ဦးစိန် (goldsmith) | (26, 22) | (29, 22) gold stall |
| Villager14 ဆရာမ မအေး (teacher) | (-26, 20) | (-34, 14) school |
| Villager15 လှေသမား ဦးကျော် (boatman) | (14, 42) | (10, 41) pier |
| Villager16 ပန်းသည် မခင် (flower seller) | (40, 34) | (14, 14) day market |
| Villager17 တည်းခိုခန်း ပိုင်ရှင် ဦးသိန်း (guest house owner) | (26, 33) | (26, 36) guest house |
| Villager18 ညဈေး ရောင်းသူ မစု (night market seller) | (-36, 29) night market itself | (-28, 30) nearby houses by day |

Two honest notes. First, Villager18 works nights, so her pattern reads reversed on purpose and needs no code change: by day she wanders near the houses at (-28, 30); at night her wander centre is home (-36, 29), which IS the night market (NightMarket20 sits at (-36, 32)) — she is at her stall after dark by virtue of living there. Second, villagers whose home is already at their workplace (blacksmith, potter, goldsmith, guest house owner, festival pair, market vendor) show only a small day/night shift — they live at work, so their commute is a few metres; the visible commutes are the gatekeeper, monk, teacher, boatman, fisherman, tea owner, and flower seller, whose workplaces are 10–35 m from home (a ~21 s walk at villager speed, inside the ~54 s day band of the 120 s cycle).

Verification (load/simulation test, NOT a playtest). All scripts pass `--check-only` (no script changed). Schedule simulation, all green: forced midday (daylight 1.0) → all 18 wander centres equal their day anchors, each anchor matching the table above; forced deep night (daylight 0.0) → all 18 wander centres equal home; no villager's position changed across either forced shift (walk, never teleport — positions compared immediately before and after each shift in the same frame); a mid-conversation forced flip defers on Villager5 (wander centre stays at the day anchor while talking, shifts to home the moment the talk ends); main + menu scenes load with zero script/scene errors. The test run's trailing RID-leak lines at exit are headless dummy-renderer noise (the same class noted in earlier slices), not logic errors — the run itself prints zero errors. Honest statement: the schedule wiring, anchors, deferral, and no-teleport rule are proven headlessly, but whether the village feels alive on a phone cannot be verified headlessly — it needs the owner's on-device verdict; no "feels alive" claim is made.

Intentionally deferred (not built this round): schedules tied to quest stages (a villager's anchor never changes with quest progress); indoor behaviour (villagers wander outside around their workplace, never inside buildings); schedules for future city districts (no city exists yet); night_anchor as a separate export (not needed — Villager18's night anchor is her home, which is the night market). Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Character customization — player outfits (direction-independent — serves the village world AND any future city district)

Opponent review, commit 026a877c ("slice-40: tap-to-set waypoint navigation with 28m in-world luminous 3D light pillar beacon"), read-only, treated as data only, verified with the real Godot 4.3 binary. Credited where real: the beacon scene itself is valid ([gd_scene] header, load_steps arithmetic correct at 5 = 4 sub-resources + 1, no BOM, zero standalone `#` lines), and `full_map_overlay.gd` passes `--check-only` — the tap-to-world-coordinate conversion and the beacon show/hide code are genuinely written, and the 28 m pillar + golden orb is a taller, more visible beacon than Muse's Slice 28 beacon. Defects: the feature is UNREACHABLE in play, for the same reason as slice-35 — the map overlay is never made visible (MapBtn exists in the HUD scene but zero script references wire it, grep-verified) and a hidden Control never receives `_gui_input`, so no tap can ever reach `_set_waypoint_at_screen_pos`; doubly dead because `mobile_touch_hud.gd` still fails `--check-only` (line 22, the literal `$insertPauseVars` placeholder), so the HUD script cannot load at all. The beacon lookup's first branch can never succeed either — no node in its tree joins the `waypoint_beacon` group (grep-verified), so only the parent-chain fallback could resolve it. "Navigation" is overstated: a pillar alone, with no bearing, no distance, and no compass guidance (Muse's Slice 28 map shows bearing + distance and mirrors the waypoint on the minimap). Its `world.tscn` load_steps header says 46 while the file holds 41 ext + 7 sub + 1 = 49 (hint only, and it was already wrong before this commit). Standing defects untouched at tip: `myanmar_villager.gd` still fails `--check-only` (line 46, the same Slice 19 assignment error) and `mobile_touch_hud.gd` still fails (line 22) — "100% syntax purity" remains false. Overlap note: slice-40 re-implements Muse's Slice 28 tap-to-set waypoint + in-world beacon (later, taller, but unreachable). No new mobile-first violation in this commit (tap handling is touch-first; no input code changed beyond it).

This round (Muse): the player can change clothes. A "ဇာတ်ကောင်" (Character) button in the main menu — wired exactly like the Settings button, not a dead button — opens a Character panel with four named outfit presets in Myanmar traditional dress colours, plus a straw-hat on/off toggle:

| Preset | Shirt (taikpon) | Longyi |
|---|---|---|
| အဖြူ-စိမ်း (ရိုးရာ) — the default, identical to the pre-customization look | #F5F0E6 off-white | #145938 dark green |
| မိုးပြာ | #A6CCF2 sky blue | #1A3373 navy |
| ပန်း | #F2BFCC soft pink | #731A26 maroon |
| ရွှေဝါ | #F2D98C golden cream | #59381A brown |

Honest scope, stated plainly. The player model is primitive meshes, so customization is COLOURS of the existing Torso/Longyi/PlayerHat meshes only — no new meshes, no new character model, no free colour picker (presets only). Player only: the 18 villagers are not customizable. Choices persist in `user://settings.json` alongside mute/volume (three new keys: `shirt_color_html`, `longyi_color_html`, `hat_visible`), and `player.gd` applies them at world spawn — applied on world load, NOT live in-world switching (changing the outfit in the menu shows up the next time the world loads). Old settings files without the outfit keys load the default outfit, so a Slice 29 settings file keeps working. One real implementation detail, caught by reading the scene before coding: the scene's taikpon material is shared by the player AND all 18 villagers (25 uses) and the longyi material is shared too, so recolouring the shared material would have recoloured every villager — the player's Torso/Longyi instead get a DUPLICATED material each at spawn, and the test proves Villager1's torso keeps the original off-white while the player's turns rose. The hat is a visibility toggle only, so it needs no material work.

Scene accounting is exact. `main.tscn` is untouched (`load_steps` stays 431 — the outfit code lives in `player.gd`, no new scene resources). `scenes/ui/main_menu.tscn` `load_steps` 4 → 5 (one new ext-resource, the character panel scene; the CharacterButton node and the moved NoSaveLabel reuse the existing button style). New `scenes/ui/character_panel.tscn` `load_steps` 3 (1 script ext + 1 button-style sub + 1). Zero `#` comment lines added to any scene. All Slice 29 features kept (schedules for all 18 villagers, working world map, mission framework, car physics, camera avoidance, traffic, visuals, menu/pause/save/load); no vehicle, traffic, NPC, quest, map, or visual behaviour changed.

Verification (load/simulation test, NOT a playtest). All 26 scripts pass `--check-only` (25 from Slice 28 + the new `character_panel.gd`). Customization simulation, 25/25 green, run headless with an isolated user directory: SaveManager defaults are the scene's own colours with the hat on; the Character button exists, is visible, and its press opens the panel (initially hidden); pressing the rose preset saves #F2BFCC/#731A26 to settings.json and the panel's current label shows the preset name; toggling the hat check off saves `hat_visible = false`; loading the world applies rose/maroon to the player's Torso/Longyi and hides PlayerHat, while Villager1's torso stays off-white (the shared-material trap, proven avoided); rewriting settings.json in the old Slice 29 format (mute + volume only) falls back to the default outfit on load. One test-harness note: `Color.is_equal_approx` is too strict for hex-vs-scene colour comparison (scene (0.96, 0.94, 0.90) vs hex-parsed (0.9608, 0.9412, 0.902) differ by ~0.001), so the villager-untouched check uses a 0.01 tolerance — the one initial failure was this tolerance, not the code, and the re-run is 25/25. Honest statement: the wiring, persistence, fallback, and material isolation are proven headlessly, but whether the four looks actually read well on a phone cannot be verified headlessly — it needs the owner's on-device verdict; no "looks great" claim is made.

Intentionally deferred (not built this round): NPC villager customization; new character meshes or accessories; free colour picking (presets only); live in-world outfit switching (applies on world load); a Character entry in the pause menu (main menu only). Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Settings expansion — camera sensitivity, HUD size, joystick deadzone (direction-independent — serves the village world AND any future city district)

Opponent review: none this round. The arena tip was checked first and had NOT moved past bf50299 (already reviewed in the motorcycle round), so there is no new opponent commit to review — this round is build-only, and the next opponent move will be reviewed in the following round.

This round (Muse): the Settings screen (shared by the main menu and the pause menu) gains three genuinely working controls, on top of the existing mute toggle, volume slider, and reset-to-defaults. No decorative sliders, per the master prompt's hide-or-disable rule:

| Setting | Control | Range / default | What it actually does |
|---|---|---|---|
| ကင်မရာ လှည့်နှုန်း (camera sensitivity) | Slider | 50–200%, default 100% | Multiplies touch-drag orbit speed in `camera.gd` (`relative.x * 0.005 * sensitivity`). Zoom buttons keep their fixed 0.2 step and the Q/E desktop fallbacks keep their fixed 0.02 step — the slider scales the touch path only. Read live on every drag, so a change made in the pause Settings screen takes effect the moment play resumes, with no world reload. |
| ခလုတ် အရွယ်အစား (HUD size) | Slider | 80–125%, default 100% | Scales every touch HUD control around its own centre in `player.gd` (`_apply_hud_scale`): joystick, all action buttons, minimap, labels, and bars. Applied at world spawn and again on pause-resume, so a pause-menu change takes effect without a reload. The pause menu itself and the world-map overlay are deliberately NOT scaled — menus keep their own layout, and the map's pixel math is computed from its unscaled size. At 80% the smallest button is still ~60 px across (tappable); at 125% centred pivots keep edge buttons on screen. The joystick's drag math is unaffected because `_gui_input` works in the control's local coordinates, which scale with the control. |
| Joystick အသေဇုန် (joystick deadzone) | Slider | 0–40%, default 15% | The single deadzone for the whole game. `joystick.gd` reads it from SaveManager on every drag, and every vehicle (car, motorcycle, tuk-tuk, and the rest) steers from the joystick's deadzone-filtered `touch_vector` — so one setting covers player movement AND all vehicle steering, with no separate per-vehicle path to wire. Read live, so a pause-menu change takes effect immediately. |

Persistence and safety. All three persist in `user://settings.json` as `camera_sensitivity`, `hud_scale`, `joystick_deadzone`, alongside the existing mute/volume/outfit keys. Old settings files without the new keys load the defaults, so a Slice 30 settings file keeps working. Out-of-range values in a hand-edited file are clamped on load (camera 0.5–2.0, HUD 0.8–1.25, deadzone 0.0–0.4), so no file can produce an unusable HUD or a dead joystick. Reset-to-defaults restores all three plus every pre-existing key (mute, volume, outfit), verified end to end.

Scene accounting is exact. `main.tscn` is untouched (`load_steps` stays 431 — the HUD scaling walks the existing JoystickLayer children, no new scene resources). `scenes/ui/settings_panel.tscn` `load_steps` stays 4 (the three new label/slider rows reuse no new sub-resources; only the panel's anchors grew taller, 0.22–0.78 to 0.08–0.94, to fit the new rows). No `.tscn` file gains a standalone `#` comment line. All Slice 31 features kept (motorcycle physics, character customization, schedules for all 18 villagers, working world map, mission framework, car physics, camera avoidance, traffic, visuals, menu/pause/save/load); no vehicle, traffic, NPC, quest, map, or visual behaviour changed.

Verification (load/simulation test, NOT a playtest). All 26 scripts pass `--check-only`. Settings simulation, 47/47 green, run headless: defaults are 1.0 / 1.0 / 0.15; non-defaults (1.75 / 1.2 / 0.30) persist across a save/load round-trip; an old-format settings file falls back to defaults for the three new keys; an out-of-range file clamps to 2.0 / 0.8 / 0.4; reset restores all keys including mute, volume, and outfit; loading the world with HUD 1.2 scales the joystick, TalkButton, and MinimapPanel to 1.2 with centred pivots while PausePanel21 and WorldMapPanel stay at 1.0; a 100 px drag at sensitivity 2.0 turns the orbit 1.0 rad and at 0.5 turns it 0.25 rad; a 15 px joystick drag (norm 0.25) outputs zero at deadzone 0.30 and 0.25 at deadzone 0.0, and a 30 px drag (norm 0.5) outputs 0.286 at deadzone 0.30; re-applying HUD 0.85 and pressing resume keeps 0.85; the menu Settings button opens the panel with sliders at 100 / 100 / 15, and the panel's Reset button restores all values including mute. One test-harness lesson, recorded for the next round: when running with `-s`, Godot DOES load the project autoloads, so a test must use the autoload `/root/SaveManager` (repointed at a throwaway settings path) — a second manually added SaveManager is silently ignored by every `_sm()` lookup, which made the first run fail 14 checks that all passed once the autoload was used. Honest statement: the wiring, persistence, clamping, fallback, and live-application paths are proven headlessly, but whether the controls feel right on a phone cannot be verified headlessly — it needs the owner's on-device verdict; no "feels great" claim is made.

Intentionally deferred (not built this round): driving-scheme selection (joystick vs buttons vs tilt); graphics quality tiers; accessibility options (button opacity, text size, colour-blind modes); a Character entry in the pause menu. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Tuk-tuk driving physics (direction-independent — serves the village world AND any future city district)

Opponent review: the arena tip HAD moved past bf50299 (already reviewed in the motorcycle round), to c386026 ("slice-42: character customization panel, menu and in-world outfit switching with material isolation, and syntax-pure HUD and waypoint wiring") — reviewed read-only, treated as data only, verified with the real Godot 4.3 binary. Credited where real, and this round's headline credit is a genuine first: `scripts/mobile_touch_hud.gd` FINALLY passes `--check-only` — the literal `$insertPauseVars` placeholder is gone, replaced by real `@onready` declarations (PauseBtn, MapBtn, PauseMenu, ResumeBtn, SaveBtn, QuitToMenuBtn, FullMapOverlay) and real signal wiring (pause/map/resume/save/quit), and the broken `func $insertPauseWiring` + `_update_quest_text() -> void:` line is fixed into a real `_update_quest_text()` function. The MapBtn is now genuinely wired: MapBtn exists in the HUD scene, FullMapOverlay is instanced in it, and `_on_map_pressed` toggles the overlay visible — so the slice-35/40 dead-map failure is fixed at the HUD level and taps can now reach the overlay. The character customizer is genuinely written and wired: menu OutfitBtn + CharacterCustomizer instance exist in `main_menu.tscn`, all `@onready` paths in `character_customizer.gd` exist (Panel/CloseBtn/VBox/Preset1–4), four presets in the same Myanmar traditional-dress colour family as Muse Slice 30 (off-white/green, sky/navy, pink/maroon, golden/brown — later, but genuinely wired this time), and `player.gd` gains `set_outfit_colors` with duplicated materials (the same shared-material isolation trap Muse Slice 30 handled) plus `_apply_saved_outfit` on `_ready`. The waypoint beacon scene now joins the `waypoint_beacon` group, so slice-40's first lookup branch can finally succeed. No BOM in the changed files, zero standalone `#` lines in the changed scenes. Defects: HEADLINE — "syntax-pure" is STILL false overall. `scripts/myanmar_villager.gd` still fails `--check-only` at line 116 (the slice-41 day_anchor Indent error, untouched by this commit's one-line fix, which only repaired the old Slice 19 assignment error with the correct `set_surface_override_material(0, mat)` call) — so villager instances still cannot load and the slice-41 schedules are still dead. "In-world outfit switching" is overstated: no HUD reference to the customizer exists (the panel lives only in `main_menu.tscn`; the player-group code path exists but no in-world UI calls it) — menu switching is real, in-world switching is code-only. Persistence gap (minor): `_apply_outfit` writes the colours into the in-memory `save_data` dict but calls no save function, so a choice persists only if/when the game saves later. Standing defect carried over (world.tscn untouched by this commit): the full-world instantiate failure from the bf50299 review still stands, so the new wiring is real at scene level but unreachable in a full-world load until that corruption is fixed. No new mobile-first violation (tap/button based throughout).

This round (Muse): tuk-tuk driving-physics polish, ONE vehicle only (`tuktuk.gd` only — no scene file touched, `main.tscn` `load_steps` stays 431, zero `#` lines added), following the Slice 26 car and Slice 31 motorcycle pattern. The tuk-tuk stays a CharacterBody3D kinematic driver — VehicleBody3D migration is deferred, same reasoning as the car and motorcycle (the kinematic model already preserves enter/exit, the Slice 24 camera-collision behaviour, and the HUD speed readout). Top speed stays 11.0 on purpose (`player.gd` HUD SpeedBar uses `vmax["TukTuk"] = 11.0`); reverse cap stays 0.4 (the old code already clamped there). What changed, all measured headlessly before/after with the same harness driving the real `tuktuk.gd` on full joystick input: acceleration curve (soft 0.55x launch, full mid-range, 0.5x taper near top speed); a real brake (12.0 u/s^2, 2x accel — stronger than acceleration, and it stops at ~0 instead of rolling through into reverse; reverse engages only from near-stop, capped at 0.4x); speed-dependent steering (2.0 rad/s at low speed, 1.0 rad/s at top speed, interpolated — the old constant 2.0 rad/s was equally twitchy everywhere); steering smoothing (8.0/s, no snap); gentle turn scrub (hard turns at speed bleed a little speed); longer rolling coast (2.5/s drag, was accel*0.5 = 3.0/s); and wheels that REALLY roll at ground speed — the old code spun all three wheels with `rotate_y`, which the Slice 33 harness proved yaws them about the parent Y axis instead of rolling them (rotation about the wheel's own local Y was exactly 0 while total rotation was exactly speed/radius*dt — the same bug the Slice 31 motorcycle fix caught), fixed here with `rotate_object_local` around local Y for all three wheels (TukWheelF/L/R, radius 0.35 m). No lean banking: a three-wheeler stays upright (unlike the motorcycle's lean) — its body does not tilt into turns. The Slice 32 joystick deadzone keeps applying unchanged: steering still reads the driver's deadzone-filtered `touch_vector`, exactly as before (that line is untouched).

Measured before → after (same harness, full joystick input; turn rates are magnitudes over a 0.25 s window including the smoothing ramp, same method as Slice 31):

| Check | Before | After |
|---|---|---|
| 0 → 95% top speed | 1.75 s | 2.33 s (slower outright by design; top speed unchanged 11.00) |
| Brake from top speed | 1.83 s / 9.99 m, then rolls to -3.0 in 0.5 s more | 1.00 s / 4.97 m (~half stopping distance; ends ~0; input released for 0.5 s stays 0 — no self-rolling) |
| Coast from top speed | 3.67 s / 20.07 m | 4.40 s / 24.11 m (momentum feel) |
| Reverse top | -4.40 | -4.40 (0.4x cap unchanged) |
| Turn rate, low speed | 114.6 deg/s | 78.4 deg/s (still agile; the drop is the smoothing ramp in the 0.25 s window — old code snapped instantly) |
| Turn rate, high speed | 114.6 deg/s | 44.9 deg/s (stable at speed — the key fix) |
| Wheel roll, 3 steps at top speed | local-Y rotation 0 rad, total 1.5714 rad (yawing, not rolling) | local-Y 1.5714 rad = total 1.5714 rad = expected 11.0/0.35*3/60 (exact, rolling without slipping, all three wheels) |
| Enter/exit contract | driver set + camera retargets to tuk-tuk; exit clears driver, zeroes speed, steps driver out (2.0, 0.5, 0.0) beside it, retargets camera to player | unchanged, still green |

Verification (load/simulation test, NOT a playtest). All 26 scripts pass `--check-only` (21 at root + 3 autoload + 3 in `scenes/ui/`); `main.tscn` and `scenes/ui/main_menu.tscn` load and instantiate headlessly with zero errors over 5 frames. The temp harnesses (`test_tuk.gd`, `test_load33.gd`) were deleted before commit; the working tree holds only the `tuktuk.gd` + README change. Honest statement: the numbers prove the curves, stopping distances, steering rates, and wheel roll behave as designed, but riding FEEL cannot be verified headlessly — it needs the owner's on-device verdict; no "satisfying handling" claim is made.

Intentionally deferred (not built this round): VehicleBody3D migration; physics for the remaining vehicles (cart, airplane, helicopter, cow, boat, bicycle, elephant, horse); handbrake, turn signals, cruise control, vehicle customisation. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Waypoint guidance HUD (direction-independent — serves the village world AND any future city district)

Opponent review: the arena tip had moved past c386026 (already reviewed in the tuk-tuk round), to 71e3a8d ("slice-43: settings expansion panel with camera sensitivity, live HUD scale, analog deadzone, and main menu plus pause menu integration") and 8bc57e7 ("slice-44: authentic Myanmar rideable cattle visual polish with traditional hump and horns, true wheel rotation on carts, and kinematic leg stride animation") — reviewed read-only, treated as data only, verified with the real Godot 4.3 binary on files extracted from the tip. Slice-43 credited as genuinely wired and complete: the settings panel is instanced in BOTH `main_menu.tscn` and `mobile_touch_hud.tscn` (menu + pause integration real), both open it and call `refresh()`, `camera_orbit.gd` reads `camera_sensitivity` live, `virtual_joystick.gd` reads `joystick_deadzone` live with rescaling, `mobile_touch_hud.gd` `apply_hud_scale` scales VirtualJoystick, ActionContainer, TopLeftHUD (which contains the MiniMap, so the minimap IS covered), and FlightControls, and `save_manager.gd` persists all three with clamping and reset — the same three settings, same ranges (0.5–2.0 / 0.8–1.25 / 0.0–0.4) and same defaults (1.0 / 1.0 / 0.15) as Muse Slice 32, re-implementing Muse's published COLLAB design, later. Slice-44 credited as genuinely written and wired: `rideable_cow.tscn` really contains HumpMesh, HornL, HornR, and LegFL/FR/BL/BR under VisualMesh (all matching `mount_controller.gd`'s `get_node_or_null` lookups), `bullock_cart.tscn` really contains WheelLeft/WheelRight under VisualMesh, the wheel roll divisor 0.8 exactly matches the cart wheel's actual CylinderMesh radius 0.8 (genuinely ground-speed correct), and the leg stride is a real sine animation — all touched scripts pass `--check-only`, no BOM, zero standalone `#` lines in the changed scenes. Defects: HEADLINE — the full-world load STILL fails at tip: `world.tscn` instantiates to null, with NINE referenced sub-scenes failing to load (player, rideable_cow, bullock_cart, myanmar_villager, helicopter, monastery_bell, market_stall, hinthar_statue, myanmar_tuktuk) — so slice-42's HUD wiring, slice-43's settings, and slice-44's cow/cart animation are all real at scene level but unreachable in a full-world load. Root cause, verified precisely: TRAILING `#` comments on `albedo_color` lines (e.g. `albedo_color = Color(0.96, 0.94, 0.90, 1) # Cream White Taikpon` in `player.tscn:18`) corrupt the parse of the FOLLOWING sub-resource — the engine warnings fuse the comment text into the next sub-resource header ("#CreamWhiteTaikpon[sub_resource..."), the sub-resource id is never registered, and nodes referencing it fail ("!int_resources.has(id)", "Invalid parameter" at `player.tscn:63` and `rideable_cow.tscn:57`). Same `#`-comment corruption family as the standalone-line form, now in trailing-comment form. Minor caveats: the cow legs rotate about their mesh centres (BoxMesh origin), not their hips, so the stride will seesaw rather than swing from the hip (visual-quality caveat, not verifiable headlessly); the `KEY_SHIFT` sprint check in `mount_controller.gd` is pre-existing, not new. Standing defects untouched at tip: `myanmar_villager.gd` STILL fails `--check-only` at line 116 (the slice-41 day_anchor Indent error — the 4-tab `var base_anchor` line against a 2-tab block; slice-42's fix only repaired the old Slice 19 assignment error, now correctly `set_surface_override_material(0, mat)` at line 48), so villager instances still cannot load and slice-41 schedules are still dead; `world.tscn` `load_steps` header says 46 while the file holds 41 ext + 7 sub + 1 = 49 (hint only). No new mobile-first violation (tap/button based throughout; the KEY_SHIFT line is pre-existing).

This round (Muse): waypoint guidance HUD, completing the Slice 28 world-map waypoint system. The map still owns the waypoint (WorldMapPanel `has_waypoint`/`waypoint`); this only READS it, exactly like the minimap mirror. A new top-centre HUD strip (`JoystickLayer/GuidePanel34`, with GuideArrow + GuideDist + GuideNote) appears ONLY while a waypoint is set: an 8-way arrow (↑ ↗ → ↘ ↓ ↙ ← ↖) pointing toward the waypoint relative to the CAMERA's view direction — computed from (camera → target) horizontal direction, so turning the camera swings the arrow correctly — plus a live distance readout in metres that updates as the player moves or drives. On foot the reference point is the player; while driving it is the driving vehicle, so the arrow follows the driving camera's facing, never the player's body facing (verified: with the player parked 100 m away from the car, the readout still shows the car-to-waypoint distance). Arrived radius is 5.0 m (same neighbourhood as the other 4–5 m proximity interactions): inside it the arrow hides and the label shows "✓ ရောက်ပါပြီ", and the waypoint is NOT auto-cleared — it stays set (beacon + minimap dot stay) until the player clears it from the map, so arrival never silently deletes the player's marker. Guidance ONLY: no routing, no pathfinding, no auto-driving, no road following — the panel itself carries the note "လမ်းညွှန်သာ — လမ်းကြောင်းရှာခြင်း မပါ", and so does this section. The panel is a plain Control child of JoystickLayer, so the Slice 32 `_apply_hud_scale` pass scales it with every other HUD control automatically (verified at 1.25 and back to 1.0); the pause menu and map overlay are still excluded from scaling, as before. Scene accounting is exact: `main.tscn` `load_steps` stays 431 (20 ext + 410 sub + 1 — the four new nodes reuse no new sub-resources), zero `#` lines added, only `main.tscn` + `player.gd` changed.

Verification (load/simulation test, NOT a playtest). All 26 scripts pass `--check-only`. Guidance simulation, 26/26 green, run headless: pure arrow mapping for all 8 directions plus wrap cases (0 → ↑, -45 → ↗, -90 → →, -135 → ↘, 180/-179 → ↓, 135 → ↙, 90 → ←, 45 → ↖, 360 → ↑, -270 → ←); panel hidden with no waypoint; on foot with the camera south of the player (looking north) the east/north/south/west waypoints read → / ↑ / ↓ / ← at 20 m; with the camera east of the player (looking west) a north waypoint reads →; driving reads the vehicle position, not the player's; arrived state shows the ✓ label with the arrow hidden and the waypoint kept; clearing hides the panel; HUD 1.25 scales the panel to 1.25 and back to 1.0; the main scene runs 5 frames and the menu scene loads/instantiates with zero script/scene errors. The temp harness (`test_guide34.gd`, plus frame/menu check scripts) was deleted before commit; the working tree holds only the `main.tscn` + `player.gd` + README change. One test note: the single initial failure was the test's own expectation (it said -270° maps to →; -270° wraps to +90°, which is ← — the code was right). Honest statement: the arrow math, distance readout, arrived state, clear behaviour, and HUD scaling are proven headlessly, but whether the arrow reads clearly on a phone cannot be verified headlessly — it needs the owner's on-device verdict; no "reads beautifully" claim is made.

Intentionally deferred (not built this round): pathfinding/routing to the waypoint; waypoint persistence across saves (still session-only — save keys unchanged from Slice 27); landmark filters on the map; pinch-to-zoom. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Vehicle customization — player vehicle paints (direction-independent — serves the village world AND any future city district)

Opponent review: the arena tip had moved past 8bc57e7 (already reviewed in the guidance round), to fd38ca1 ("feat(slice-45): fix villager schedule indentation error, sync world.tscn load_steps to 49, and correct tuk-tuk cylinder wheel local-axis spin") — reviewed read-only, treated as data only, verified with the real Godot 4.3 binary on files extracted from the tip. Credited: the villager Indent fix is REAL — the 4-tab `var base_anchor` line is now a 2-tab line, and `myanmar_villager.gd` now PASSES `--check-only` (exit 0, no errors), as does `mobile_touch_hud.gd` (fixed in slice-42) — the first tip at which both scripts pass; the `world.tscn` `load_steps` header is now CORRECT (49 = 41 ext + 7 sub + 1, counted exactly); the tuk-tuk wheel fix is genuinely correct — `rotate_x` replaced by `rotate_object_local(Vector3(0, 1, 0), spin_rate)`, the same local-Y fix Muse applied in Slice 33 (re-implementing Muse's published fix, later); no BOM, no new `#` lines in the three touched files. Defects: HEADLINE — the full-world load STILL fails at tip, verified directly: `world.tscn` loads as a resource but `instantiate()` returns null, with the same NINE referenced sub-scenes failing (player, rideable_cow, bullock_cart, myanmar_villager, helicopter, monastery_bell, market_stall, hinthar_statue, myanmar_tuktuk) — slice-45 touched only three files and did NOT touch the trailing-`#` corrupted scenes (`player.tscn` lines 18/30/34 and `rideable_cow.tscn` line 12 still carry trailing `#` comments on `albedo_color` lines), so the "fix villager schedule" claim is overstated in practice: the script parses now, but the villager SCENE itself still fails to load (`myanmar_villager.tscn:63`, same "Invalid parameter" signature), so slice-41 schedules remain dead in a full-world load. No new mobile-first violation (no input code touched in this commit).

This round (Muse): vehicle paint customization, following the Slice 30 character-customization pattern. A new "ယာဉ်" (Vehicle) button in the main menu — wired exactly like Settings and Character, test-proven to open the panel — shows the Vehicle screen, where the player picks a vehicle (ကား / ဆိုင်ကယ် / သုံးဘီး) and then one of four named paint presets for it, all data in `vehicle_panel.gd`: car — အနီ (မူလ) / အဖြူ / နက်ပြာ / ရွှေဝါ; motorcycle — စိမ်းပြာ (မူလ) / အနီ / အနက် / လိမ္မော်; tuk-tuk — အပြာ (မူလ) / အဝါ / အစိမ်း / ပန်းရောင်. The "(မူလ)" defaults are the scene's own body colours (car red 0.85/0.10/0.15, motorcycle teal 0.10/0.55/0.60, tuk-tuk blue 0.10/0.40/0.80), so a fresh settings file looks exactly like the pre-customization vehicles. Choices persist in `user://settings.json` (three new keys alongside mute/volume/outfit/control keys: `car_paint_html`, `motorcycle_paint_html`, `tuktuk_paint_html`), with old-file fallback to the defaults and reset-to-defaults restoring all three; `player.gd` applies them at world spawn — applied on load, NOT live switching, stated plainly. Paint is COLOURS of the existing body meshes only (Car's unnamed body mesh, Motorcycle's unnamed body mesh, TukTuk's TukBody) — no new meshes, no new models, no parts or accessories, no free colour picker (presets only). The Slice 30 shared-material trap is handled the same way: each vehicle body gets a DUPLICATED material at spawn before its albedo is set — this matters in practice because the motorcycle body shares the scene's teal paint material with the Bicycle frame, so recoloring the shared material in place would repaint the bicycle too; the duplicate keeps it untouched. Traffic vehicles are unaffected by a different mechanism: they live in their own scenes with their own materials (`StandardMaterial3D_traffic_body`), never the main scene's paint materials. Scene accounting is exact: `main.tscn` untouched (`load_steps` stays 431); `main_menu.tscn` 5 → 6 (one new ext-resource, the vehicle panel scene; the five menu buttons were restacked to make room — Continue 0.38–0.45, New Game 0.47–0.54, Settings 0.56–0.63, Character 0.65–0.72, Vehicle 0.74–0.81, NoSaveLabel 0.84–0.90); new `vehicle_panel.tscn` `load_steps` 3 (1 script ext + 1 button-style sub + 1); zero `#` lines added.

Verification (load/simulation test, NOT a playtest). All 27 scripts pass `--check-only` (20 root + 3 autoload + 4 in `scenes/ui/`). Customization simulation, 20/20 green, run headless: VehicleButton exists and is visible; pressing it opens the VehiclePanel; picking the motorcycle recolours its preset buttons to the motorcycle names and saves red; car white and tuk-tuk green save the same way and the current label shows the tuk-tuk green name; the world loads and the car body reads white, the motorcycle body red, the tuk-tuk body green; the Bicycle frame keeps its scene teal; a freshly instantiated traffic car keeps its own body red; a settings file without the paint keys falls back to the three scene defaults while keeping the outfit keys; reset restores all three paint defaults; the menu scene loads/instantiates and the main scene runs with zero script/scene errors (the only exit lines are headless dummy-renderer RID noise, not logic errors). The temp harness (`/tmp/test_vehicle35.gd`) lives outside the repo, so the working tree holds only the source change. One test note: SceneTree test scripts have no `get_node_or_null` — the autoload must be reached via `root.get_node_or_null("SaveManager")` (the first run failed to parse on exactly this; all green once fixed). Honest statement: the panel wiring, persistence, spawn application, and material isolation are proven headlessly, but whether the paints read well on a phone cannot be verified headlessly — it needs the owner's on-device verdict; no "looks great" claim is made.

Intentionally deferred (not built this round): paints for the other vehicles (cart, airplane, helicopter, cow, boat, bicycle, elephant, horse); free colour picking; live in-world switching; vehicle parts/accessories; a Vehicle entry in the pause menu. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the APK on Drive is still the Slice 10 build and was NOT rebuilt (per instruction).

## Bicycle driving physics (direction-independent — serves the village world AND any future city district)

Opponent review: the arena tip moved past fd38ca1 (already reviewed in the vehicle-paint round) through three commits — c25b701 ("feat(slice-46): strip all 37 trailing comments across all scenes for Godot parser purity and wire camera-relative waypoint guidance HUD with live distance"), 7ae6399 ("feat(slice-47): vehicle paint customization panel for car, motorcycle, and tuk-tuk with SaveManager persistence, main menu integration, and in-world material isolation"), and c18cfed ("feat(slice-48): dynamic night visual atmosphere - diurnal village fireflies particle emission and warm night market incandescent illumination with OmniLight3D") — all reviewed read-only, treated as data only, verified with the real Godot 4.3 binary on files extracted from the tip. Credited: slice-46 is a genuine repair — all 37 trailing `#` comments are stripped (verified: zero `#` lines in the tip's scenes), and for the FIRST time in this duel the opponent's `world.tscn` LOADS and INSTANTIATES headlessly (LOAD_OK=true, INST_OK=true, 49 children, Player present; the only exit lines are headless dummy-renderer RID noise, not logic errors); its `load_steps` header is correct (49 = 41 ext + 7 sub + 1, counted exactly); its waypoint guidance HUD is genuinely wired, not dormant — the HUD scene contains TopCenterHUD/WaypointGuide/ArrowLabel/DistanceLabel, and the `_process` block reads the beacon from the `waypoint_beacon` group, computes a camera-relative 8-way arrow via `signed_angle_to`, shows live distance, and shows an arrived state at 5.0 m, with on-foot/vehicle/mount/aircraft reference points — a later re-implementation of Muse's Slice 34 guidance. Slice-47 is genuinely wired end to end — four paint presets per vehicle (car/motorcycle/tuk-tuk), tabs, close button, all `@onready` paths exist in the customizer scene, the menu VehicleBtn is connected and the customizer is instanced in `main_menu.tscn`, SaveManager persists the three paint keys (load/save/reset, same key names as Muse Slice 35), and `world.gd` applies them with fresh `StandardMaterial3D` instances via `set_surface_override_material` (isolation-equivalent) — a later re-implementation of Muse Slice 35 (its defaults are preset colours rather than the scene's own body colours, and it applies at world `_ready` rather than on the first physics frame with retry — a minor robustness difference, not a defect). Slice-48 is genuinely wired — the fireflies script gates `GPUParticles3D` emission on daylight < 0.35 (with an emitting=true fallback if the DayNightCycle node is missing), the night market script toggles three real `OmniLight3D` nodes under Bulb1/2/3 at the same threshold, both scripts are attached to their scenes and both scenes are instanced in `world.tscn` — a different mechanism from Muse's Slice 25 emissive window lights and Slice 20 fireflies (real lights vs emissive toggles). Standing state at tip, verified: ALL tip scripts pass `--check-only` (the slice-41 Indent error and the slice-42 HUD placeholder are both gone), zero BOM, zero `#` lines in scenes, `load_steps` correct — the opponent's "syntax purity" claim is now essentially true at scene/script level. The remaining caveats are matters of degree, not breakage: the guidance arrow's left/right sectors were verified by static reading only (not by running its world); the night-market OmniLights and fireflies add real GPU cost on a phone, unverified on device; the fireflies fallback emits if the day/night node is ever missing. No new mobile-first violation in any of the three commits (tap/button based throughout; no new KEY_ input code).

This round (Muse): bicycle driving-physics polish, following the Slice 26 car, Slice 31 motorcycle, and Slice 33 tuk-tuk pattern — ONE vehicle only, `bicycle.gd` only, no scene touched (`main.tscn` `load_steps` stays 431). Touch joystick stays primary (the Slice 32 deadzone keeps applying unchanged — steering still reads the driver's deadzone-filtered `touch_vector`, that line untouched); keyboard stays desktop-debug fallback only. The bicycle stays a position-based Node3D — NO physics-body migration in this round (stated as deferred: the position model already preserves enter/exit, the Slice 24 camera-collision behaviour, and the HUD speed readout, and a body swap would rework collision and camera retargeting for no measured benefit). Top speed stays 7.0 on purpose (player.gd's HUD SpeedBar uses vmax["Bicycle"] = 7.0); reverse cap stays 0.4× (−2.8, unchanged). What changed is the tuning: pedal acceleration curve (soft 0.55× launch, full mid-range, 0.5× taper near top speed); a real brake (10.0 u/s², 2× accel — stronger than pedalling, and it never rolls the bicycle backwards by itself: braking stops at near-stop and reverse only engages below 0.5 m/s, capped at the old 0.4 ratio); speed-dependent steering (2.0 rad/s low speed → 0.9 rad/s at top speed, interpolated, with 8.0/s smoothing — the old constant 1.4 rad/s was equally twitchy everywhere); a much longer rolling coast (drag 1.2/s, down from the old accel×0.5 = 2.5/s stop — a bicycle keeps rolling when you stop pedalling, the signature feel); and wheels that genuinely roll at ground speed (spin = speed / 0.35 m via `rotate_object_local` around local Y — the old `rotate_y` code yawed the wheels like steering instead of rolling them: the BEFORE harness proved it, axle-direction dot 0.408, exactly cos(20 rad mod 2π), and rotation about the axle exactly 0 while the bike travelled 7 m; the same lesson as the Slice 26/31/33 fixes). The bicycle has NO headlight (the Slice 13 Lights button covers car/motorcycle/tuk-tuk only) — stated, not added here. Bicycle paint is NOT in scope (Slice 35 deferred it); this file touches no materials, so the Slice 35 motorcycle-teal isolation is unaffected — the world-load test confirms the Bicycle frame still carries the scene's teal material (StandardMaterial3D, albedo 0.1/0.55/0.6/1).

Measured before → after (same harness driving the real `bicycle.gd`, full joystick input; turn rates are magnitudes over a 0.25 s window including the smoothing ramp, same method as Slices 31/33): 0→95% top speed 1.33 s → 1.78 s (slower outright by design; top speed unchanged 7.00); brake from top speed, holding reverse until speed ≤ 0.05: 1.40 s / 4.84 m → 0.80 s / 2.42 m (about half the stopping distance; the new figure includes the near-stop reverse crawl from 0.5 to 0.04 m/s — the old figure was a straight pass-through at 5.0/s with no stop at all); brake-then-release: new code stays at 0 (never rolls backwards by itself), while the old code sailed through zero to −2.50 within 0.5 s of continued reverse input (the new code's −1.73 after the same 0.5 s is gated reverse engagement from near-stop, by design, not runaway); coast from top speed 2.78 s / 9.74 m → 5.80 s / 20.36 m (the signature roll, doubled); reverse top −2.80 → −2.80 (cap unchanged); turn rate low speed 80.2 → 70.5 deg/s in-window (the window drop is the smoothing ramp — the old code snapped instantly; the instantaneous low-speed rate actually rose 1.4 → 2.0 rad/s = 114.6 deg/s); turn rate high speed 80.2 → 40.3 deg/s in-window (stable at speed — the key fix), and the settled high-speed rate is 51.6 deg/s = 0.9 rad/s exactly, the design value; wheel roll over 1 s at top speed: rotation about the axle 0 → 20.0000 rad vs 7.00/0.35 = 20.0000 expected (exact, rolling without slipping), axle-direction dot 1.0 (was 0.408).

Verification (load/simulation test, NOT a playtest). All scripts pass `--check-only` (same count as Slice 35 plus the edited file, no new script files). The main scene loads and instantiates headlessly with zero script/scene errors, the Bicycle node is present with its script, and the menu scene loads and instantiates. The exit contract holds: exit clears the driver, zeroes speed, and writes the (2.0, 0.5, 0.0) step-out offset (the out-of-tree harness reads `global_position` as 0, so the absolute beside-bike placement rests on the exit line itself, which is byte-identical to the car/motorcycle/tuk-tuk exit code verified in-tree in earlier slices — and the bicycle's exit line is unchanged from before except for resetting the new `steer_smooth`). The temp harness (`/tmp/test_bike.gd`) lives outside the repo, so the working tree holds only the source change (`bicycle.gd` + this README section). Two test notes: SceneTree test scripts have no `get_node_or_null` on plain Nodes and inferred-Variant locals are parse errors here, so test locals need explicit types (the first run failed on exactly this); and `atan2` wraps past π, so wheel-roll angles must be accumulated per step (the first wheel check read 1.15 rad for a true 20.00 rad spin — 20 mod 2π — before the per-step accumulation fixed it). Honest statement: the curves, stopping distances, coast, steering rates, lean-free upright ride, and wheel roll are proven headlessly, but riding FEEL cannot be verified headlessly — it needs the owner's on-device verdict; no "satisfying handling" claim is made.

Intentionally deferred (not built this round): physics-body migration for the bicycle (and for the remaining vehicles: cart, airplane, helicopter, cow, boat, elephant, horse); bicycle lean banking; bicycle paint (Slice 35 deferred it); handbrake, turn signals, cruise control. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the Drive APK is now the Slice 35 build (delivered 2026-10-22 ~11:25 +07) and was NOT rebuilt in this round (per instruction).

## Mindon town-centre district (map foundation, part 1 — owner's map-basis order)

Opponent review: the arena tip moved past c18cfed (already reviewed in the bicycle round) through three commits — 5dbb4b8 ("real-world GIS map integration for Mindon Ward 3 (roads, buildings, trees, Mindon stream)"), 1196d5bf ("Slice 50 - Mindon GIS live GPS map overlay, gateway banner, and atmospheric river audio"), and 0684506 ("Slice 51 - Player Health Bar HUD and review of MUSE Slice 36") — all reviewed read-only, treated as data only, verified with the real Godot 4.3 binary on files extracted from the tips. Credited: the GIS data structure is genuinely OSM-shaped — its centre is the exact owner pin (19.351497, 94.731889, "မင်းတုန်းမြို့ အမှတ် (၃) ရပ်ကွက်"), with 32 roads (259 points, OSM-style ids, residential/service/unclassified types, no named roads), 13 buildings (a hospital-compound cluster plus 2 building=yes), and 2 rivers named မင်းတုန်းချောင်း; the builder genuinely wired it (a `MindonTown` node in `world.tscn` running in `_ready`, producing 370 MindonRoads children, 13 MindonBuildings, 21 MindonStream segments, 3 Ward3Amenities); the world loads and instantiates at tip with a correct `load_steps` header (50 = 42 ext + 7 sub + 1, counted exactly); all touched scripts pass `--check-only` (mindon_map_builder, full_map_overlay, audio_manager, mobile_touch_hud, virtual_joystick); no BOM, no `#` lines in the new files; the GPS math is correct (lat = 19.351497 − z/111139, lon = 94.731889 + x/104860 — a correct equirectangular approximation); the overlay hospital marker (−45,135) matches the compound centroid area and the stream marker (−534,−64) matches the river polyline region, and all overlay `@onready` paths exist; the 2500×2500 ground plane covers the full GIS extent, so there is no void problem; and the nearest GIS road passes 12.2 m from the village centre (nearest road point 18.2 m at (−3,−18)) — in their approach Mindon content is reachable on foot from the village because origin = pin and GIS data is in metres around it, with village props coexisting around the origin. The slice-51 health-bar HUD wiring itself is real (the bar exists in the HUD scene, `load_steps` 15 → 16 is correct for the one added sub-resource, both touched scripts pass `--check-only`, no BOM, no `#` lines, no new keyboard-primary input). Defects: HEADLINE (5dbb4b8) — the road and river quads are NOT rotated along their segments. The builder calls `look_at()` on mesh instances BEFORE `add_child` (mindon_map_builder.gd lines 72–74 for roads, 184–186 for rivers), which Godot rejects ("Node not inside tree. Use look_at_from_position() instead" — observed in the headless run), and the result is verified: all sampled road quads carry identity rotation (z-axis (0,0,1), x-axis (1,0,0)) despite diagonal segments (first segment direction ≈ (0.84,0,0.55)), while their positions (midpoints) are right (e.g. (−547.25,−461.45) is the midpoint of (−565.4,−473.3) → (−529.1,−449.6)) — so the "real-world roads" render as disconnected axis-aligned bars, not continuous ribbons following the real paths, and the same bug hits the river boxes. The river water is OPAQUE despite its alpha: `water_river.gdshader` sets ALPHA = 0.85 but its render_mode lacks blend_mix (cull_back, diffuse_burley, specular_schlick_ggx only), so the alpha is ignored and the river renders opaque — the same broken approach Muse Slice 25 avoided. Building footprints are IGNORED: all 11 hospital buildings are identical fixed 12×4×10 boxes at footprint centroids, and the 2 "yes" buildings are fixed-size house scenes at centroids — positions are real, sizes and shapes are not, so "buildings exactly as reality" is overstated (verified: first building position (−136.54,115.86) is the centroid of footprint x −145.4..−123.2, z 107..125.7). Amenities are MISPLACED: the well, pot, and zayat sit at (5,−8), (3.5,−6.5), (−12,−14) — village-centre coordinates, not Ward 3 — despite the comment claiming "Ward 3 center", duplicating village props at village coordinates. River/birds audio is DORMANT: zero callers of `play_river_flow` / `play_tropical_birds` anywhere (grep-verified) — "atmospheric river audio" never plays (the same dormant pattern as slice-31's pedestrian group, slice-34's `get_daylight()`, and slice-39's mission manager). The "gateway" is a renamed sign: the village_gate.tscn change is only Label3D text ("မင်္ဂလာပါ — မင်းတုန်းမြို့ အမှတ်(၃)ရပ်ကွက်မှ ကြိုဆိုပါ၏", font 32 → 30) — no gateway structure, no road link, no teleport. There is NO trees key in the JSON despite the commit message "roads, buildings, trees" — vegetation is procedural roadside planting (capped 90 palms + 70 bananas), not GIS tree data. A runtime joystick error exists: `virtual_joystick.gd:12` assigns a ColorRect to a Panel-typed variable at `_ready` (parses cleanly, fails at runtime — observed in the headless world run; impact beyond the error itself is not over-claimed). The overlay player marker is still UNCLAMPED (at 0.55 px/m on a ~680 px canvas, walking to far GIS areas ±800 m flies off-canvas); distant roads are partially off-canvas by scale choice (a limitation, not a headline). Coverage is thin: 13 buildings for a "dense town centre" (the survey below shows a dense cluster) — hospital compound + 2 houses only, with no post office, shops, pagoda, temple, or school in the data (the overlay still shows the old village pagoda/market markers, not Mindon landmarks). HEADLINE (0684506) — the health bar is DECORATIVE-ONLY, and the claim of "full vitality architecture" tracking "dynamic player health states" is false in this peaceful game: `player.gd` only declares `health = 100.0` and `max_health = 100.0`, and the HUD mirrors that value every frame — while a grep across the whole tip tree finds ZERO references to damage, take_damage, heal, or any code that ever changes `health`, because no damage source exists (there is deliberately no combat and no damage system — Muse Slice 10 refused a health bar for exactly this reason: a bar with nothing behind it is fake). The bar can never move from 100.0; it is a permanent full red bar, honestly described as HUD wiring over a constant, not a vitality system. The slice-51 "review" of Muse Slice 36 lists ZERO concrete file/line defects — it acknowledges the bicycle physics and claims Antigravity "stays well ahead in total scope", which is rhetoric, not a duel-format review. Prior standing defects now FIXED at this tip (credited): their world loads and instantiates (the c18cfed trailing-`#` strip holds), `load_steps` is correct, and `myanmar_villager.gd` + `mobile_touch_hud.gd` both pass `--check-only`. No new mobile-first violation in any of the three commits.

District-first decision (stated plainly — the owner can redirect with one word): Mindon is built as a NEW explorable district CONNECTED to the existing village by a road link the player can walk and drive, and the existing village content is left FULLY intact — nothing is deleted, moved, or re-anchored in this round. Rationale: a full replacement of the fictional village layout in one round would break position-dependent quests (36 stages with proximity triggers), the traffic waypoint loops, and the villager schedules; the district-first approach delivers the real place now and keeps everything working, and every district node transfers directly if the owner later orders full replacement. This section does NOT claim the fictional village has been replaced, and the village-vs-city widget remains formally unanswered — this district is provisional, village-intact work, not a settled direction.

The survey (from the owner's pin, 19.351497, 94.731889 — Plus Code 9P2J+HQR Mindon, centre of Mindon town): an irregular, mostly-unnamed street grid with a roughly east–west street just south of the pin and north–south + diagonal streets branching off it, densest around the pin and to the east/southeast, sparser toward the south and the field edges; the Maton watercourse along the WEST side running roughly north–south and turning west at the southwest, plus a second Maton-labelled line east–west across the NORTHERN edge; no pond or lake in the town centre; pale-green open fields on all sides; a smaller settlement cluster across the water to the far west (partly labelled 'Oo village'); labelled landmarks — northwest: Su Taung Pyay Bagoda + Mindon Post Office; east: Buddhist temple, Than Kaday Aung (Gold & Jewellery), David Bowie's Diamond shop, YM Store; southwest: Ziwasae, Mindon Hospital, Township Education Office, MRTV; southeast: Myittar Mon Medical Store, Mya Specialist clinic; no school/market/monastery explicitly labelled in the visible view; individual trees not distinctly shown at default-map zoom (satellite survey is a later refinement).

This round (Muse): the district, east of the village, centred around x=+150 (north = −z, east = +x). The ground is enlarged to cover village + district in one plane: `BoxShape3D_ground` (100,1,100) → (320,1,220) and `PlaneMesh_ground` (100,100) → (320,220), recentred on (90, 0, 0), covering x −70..250, z −110..110 — the village sits fully inside it. The map transforms grow with the world (shared centre/span, one family): the world map moves to centre x 90, span 320 (`WORLD_HALF` 50 → 160, `WORLD_SPAN` 100 → 320, new `WORLD_CENTER_X` 90.0; `world_to_map` subtracts the centre, `map_to_world` adds it back and clamps to x −70..250, z −160..160), and the minimap formula moves from (wpos + 50)/100 to (wpos + 70)/320 over the same 170 px panel — waypoint tap, guidance, and the beacon are position-based and unaffected. Streets (dirt, Slice 25 material, drivable width): a road link from the village east edge (55, 0) to the bridge (dirt, width 5); the main east–west street (97, 0) → (235, 0), width 6; north–south branches at x=140 (z −60..60) and x=190 (z −55..55), width 5; a diagonal branch (140,−20) → (185,−70); a south stub (190,30) → (210,65) — irregular, NOT a perfect grid. Water (genuinely transparent water, Slice 25's proven approach — transparency mode alpha, 0.7 alpha — NOT alpha-without-blend-mode): the Maton N–S strip at x 84..92, z −90..75, width 8; the northern E–W line at z −90, x 88..250, width 7, meeting the N–S strip at (88,−90); the southwest diagonal turn (88,70) → (48,95); dirt banks flanking the strips. The BRIDGE at (88, 0) is a real crossing, not scenery: a low deck (top 0.275, spanning the water plus both banks, x 81..95) with gentle 4.5° ramps on both sides and real collision on deck + ramps, so feet AND cars cross — the headless drive test proves a car climbing it (see verification). Building clusters, matching the real pattern by density (every zone below is represented; per-house satellite exactness is a LATER refinement, NOT claimed now): centre dense — MDHouse1 (125,−14), MDHouse2 (125,14), MDHouse3 (155,−14), MDHouse4 (155,16), MDHouse5 (170,−16), MDHouse6 (170,14), MDHouse7 (148,−32), MDHouse8 (148,32); east/southeast — MDHouse9 (200,−14), MDHouse10 (200,16), MDHouse11 (220,30), MDHouse12 (215,−35); south sparse — MDHouse13 (150,60), MDHouse14 (195,62); Oo village west of the water — OoHouse1 (66,−16), OoHouse2 (66,16), OoHouse3 (74,−10), reachable over the bridge. Every house uses the House6 pattern (walls + terracotta roof) with a Slice 24 layer-2-only camera blocker, so the camera never clips through them; the camera works in the district exactly as in the village (blockers verified layer 2 / mask 0, and a horizontal ray through MDHouse1 provably hits its blocker). Named landmarks, all with minimap dots + world-map entries + proximity prompts: MindonPagoda "စုတောင်ပြည် ဘုရား" at (108,−62) — a real approachable StaticBody3D pagoda (platform, plinth, two terraces, gold bell, spire, hti, with its own collision, like the village pagoda); MindonTemple "ဘုန်းကြီးကျောင်း" at (218,−22) — a real approachable structure (larger house pattern, 1.5×1.2×1.4, with blocker); MindonPost "စာတိုက်" (148,26), MindonHospital "ဆေးရုံ" (122,58, larger white building with a blue roof), MindonEdu "ပညာရေးရုံး" (102,62), MindonMRTV "MRTV" (108,42), MindonShops "ဈေးဆိုင်" (205,38) — named buildings with prompts (stated plainly: only the pagoda and temple are approachable structures; the offices and shops are named buildings, not enterable interiors — the game has no interiors anywhere). Fields on all sides: north (x 60..240, z −107..−94), south (x 70..240, z 85..107), east (x 236..250, z −60..60), west strip (x 57..82, z −75..−35), all in the paddy material. Trees as LINES along field edges and streets (not random scatter), 21 trees: north field edge (z=−105, x 70..220), south field edge (z=88, x 100..220), east field edge (x=238, z −40..40), main-street lines (z=±8, offset ≥6 m from street centrelines so streets stay drivable) — tree lines, not per-tree satellite exactness (stated, later refinement). Everything else is untouched: all 36 quest stages, all 18 villager schedules, traffic (village loops only — traffic routes through the district are deferred, stated; existing traffic despawns beyond 75 m as before, so the district has no traffic yet), the world map + guidance (new landmarks appear on both), the mission framework, character + vehicle customization, settings, and all vehicle physics (car/motorcycle/tuk-tuk/bicycle). Scene accounting is exact: `main.tscn` `load_steps` 431 → 440 (20 ext + 419 sub + 1 — nine new sub-resources: link-road mesh, street mesh, bridge deck mesh + shape, bridge ramp mesh + shape, three camera-blocker shapes by size class); 212 new nodes; zero `#` lines added; the generator script is kept at `../mindon-gen37.py` (outside the repo) for the refinement round.

Verification (load/simulation test, NOT a playtest). All 27 scripts pass `--check-only`; the main scene loads and instantiates headlessly with zero script/scene errors and the menu scene loads and instantiates. District simulation, 86/86 green, run headless: all 14 district houses + 3 Oo houses + pagoda + temple + hospital + post + edu + MRTV + shops + bridge + all three water strips + all 21 trees present; all three water strips use the genuinely transparent material (transparency = 1); the sampled blockers are layer 2 / mask 0 and the camera ray through MDHouse1 hits its blocker; the WALK test (player teleported to the village side of the link road at (58, 0), walking +x on the real movement code) reaches x > 108 into the district, stays on the road (z = 0.00), stays grounded, and rides the bridge deck (origin y peaks above 0.75 on the span, vs 0.60 settled on flat ground); the DRIVE test (car teleported west of the bridge at (70, 0) facing +x, entered through the real `_try_enter_vehicle` flow, full throttle) drives into the district (x > 112), stays grounded, and rides the bridge deck (origin y peaks above 0.60 on the span, vs 0.50 settled); the pagoda prompt shows "အနီး: စုတောင်ပြည် ဘုရား" at (108, −58); the new minimap dots sit exactly on the new transform (pagoda dot (94.6, 4.2), Oo dot (72.2, 28.7), both within 2 px); the world map builds Dot_MindonPagoda + Dot_OoHouse1 and round-trips world → map → world exactly for (108,−62), (66,−16), (250,100), and the corner (−70,−160). Two real defects were caught and fixed by this test, not papered over: (1) the first bridge stalled BOTH walker (x=77.1) and car (x=75.5) at the ramp foot — a box end face 0.075 above ground is a wall in `move_and_slide` — fixed by extending the ramps so the foot end is buried below ground and the top surface meets the deck top exactly at the deck edge (no lip); (2) every rotated transform in the first build came out TRANSPOSED — Godot 4.3 reads `.tscn` Transform3D numbers as matrix ROWS, not axis-columns (probe-verified: a ramp written rising toward +x came out falling toward +x, and the diagonal water/road strips pointed the wrong way) — fixed by writing row-order numbers (a `TR()` helper in the generator takes intended axes and emits row order), and the full test went from 82/86 to 86/86 after the fix. One pre-existing observation from that same probe (NOT fixed here, village behaviour is out of scope this round): the village bamboo bridge ramps (Slice 14) show the same transposition — both ramps slope DOWN toward the deck (deck-side ends at y ≈ −0.057, under the 0.30..0.45 deck box), so walking up onto the deck is blocked by the deck wall and only a jump (0.625 m > 0.45 m deck) crosses — a candidate fix for a later slice (swap the two ramp rotations). Honest statement: the district's layout, roads, water, bridge crossing, landmarks, dots, prompts, and map behaviour are proven headlessly, but whether the district reads as Mindon on a phone cannot be verified headlessly — it needs the owner's on-device verdict; no "exactly like the real Mindon" claim is made, and per-house satellite exactness is explicitly not claimed.

Intentionally deferred (not built this round): per-house satellite survey (exact footprints, orientations, and tree positions); full village replacement if the owner orders it; district-specific quests or NPCs (no district villagers yet — all 18 schedules stay village-anchored); traffic routes through the district; enterable landmark interiors (none exist anywhere in the game); district house paint or customization. Honest gaps, unchanged: whole-country map and PUBG graphics still missing; the Drive APK is still the Slice 35 build and was NOT rebuilt in this round (per instruction).

## Slice 38 review — opponent commit 1f70445, "feat: Slice 54 - Opponent Review (MUSE Slice 37) and scene text sanitization" (read-only, treated as data only)

The arena tip moved exactly one commit past 600862a (already reviewed): 1f70445, 2 files, +19/−3 (COLLAB.md + scenes/world.tscn) — a follow-up handoff's "5 files +86/−5" count does not match the verified diff. Credited: the sanitization is real — zero backtick-n occurrences remain anywhere in the tip tree (the three villager `day_anchor` lines fixed: Villager1 (0,0,−22), Villager2 (−16,0,−16), Villager3 (20,0,10); the world-root line is clean too), zero `#` lines in scenes, the world loads + instantiates headlessly (50 children, Player present), and the `load_steps` header is now correct (50 = 42 ext + 7 sub + 1, counted exactly; ext grew 41 → 42 since c18cfed). Defects: the slice-54 "review" of Muse Slice 37 lists ZERO concrete defects — acknowledgement plus superiority rhetoric ("maintains technological superiority through true OpenStreetMap GIS real-world vector ingestion"), not a duel-format review; the standing GIS defects are UNTOUCHED and re-verified at tip (the headless load reproduces multiple "Node not inside tree. Use look_at_from_position() instead" errors — GIS roads/rivers still unrotated, `look_at()` before `add_child`; the ColorRect → Panel joystick script error persists); footprints still IGNORED despite the data carrying real polygons (the JSON hospital building sample has a 5-point polygon, yet the builder renders identical fixed boxes); the "2,000m real river spline" is loose rhetoric — the data totals ~3257 m across BOTH rivers (~1673 m + ~1584 m, 11 + 10 segments; roads 32 / 259 pts, buildings 13, rivers 2, centre the exact owner pin 19.351497/94.731889, centre name "မင်းတုန်းမြို့ အမှတ် (၃) ရပ်ကွက်"); the "10-Minute Rapid Delivery Cadence" has NO supporting change in this commit (only COLLAB + a 3-line fix) — the same unsupported pattern as before. Standing defects from the Slice 37 review, re-verified at this tip only where stated above and otherwise carried forward for re-verification: river OPAQUE despite alpha (shader ALPHA 0.85, no blend_mix); amenities MISPLACED at village-centre coords (5,−8), (3.5,−6.5), (−12,−14); river/birds audio DORMANT (zero callers); "Gateway" a renamed sign only; NO trees key in the JSON; overlay player marker still UNCLAMPED; slice-51 health bar DECORATIVE-ONLY (health = 100.0, zero damage/take_damage/heal references anywhere — the bar can never move in this deliberately combat-free game); slice-51 "review" of Slice 36 lists zero concrete defects; slice-52 "scene purity audit" has no supporting change; slice-53 caveats (degree, not breakage): WAV regenerated every step, one sound on all surfaces. No new mobile-first violation in this commit.

## Solidity round — solid houses, exit clearance, world bounds, stuck recovery, bamboo bridge fix (audit plan item 2)

This round lands the audit's item 2 as one round, because the four parts interact: solid houses create the wedges that exit clearance and stuck recovery exist for. No item count is padded — this is one round with five parts, and no vehicle, traffic, NPC, quest, or visual behaviour changes beyond what is stated here.

Solid houses (gameplay collision layer 1; the Slice 24 layer-2 camera blockers are untouched and stay camera-only): every one of the 36 existing camera blockers gains a layer-1 twin with the identical transform and shape (layer 1, mask 0) — village House1–8, School, Stilt5/6/13, LakesideHut; district MDHouse1–14, OoHouse1–3, MindonTemple, MindonHospital, MindonPost, MindonEdu, MindonMRTV, MindonShops — so the player can no longer walk through any of them. Added on top of the twins: Stilt15 + Stilt17 solids (the two stilt houses that had no Slice 24 blocker; Stilt15 uses the walls footprint 2×4, matching the Slice 24 pattern where stilt camblocks are walls-sized, not deck-sized — the 8.5×6.5 deck overhang of Stilt15_4 therefore remains passable underneath, a stated limitation consistent with Slice 24), GuestHouse post colliders (0.12-wide, at the four corners) + bed collider (the interior stays walkable between the posts — 5 m / 4 m gaps), and four pagoda pillar colliders (0.2-wide, 8 m from the village pagoda centre, outside the pre-existing base cylinder). Both pagoda base cylinders (village r=6.5, Mindon r=6.5) already existed and are unchanged. The Slice 13 gate arch stays WALKABLE (posts + beam, no blocking collision — verified: the player walks through it). Scene accounting is exact: `main.tscn` `load_steps` 440 → 445 (20 ext + 424 sub + 1 — five new shape sub-resources: stilt solids, post, bed, pillar shapes); 100 new `[node]` lines (49 bodies × body + shape child, + 2 HUD nodes); zero `#` lines.

Vehicle exit clearance (all 11 rideables — car, motorcycle, tuk-tuk, bicycle, cart, boat, cow, helicopter, elephant, horse, airplane — restructured identically in their own scripts): before the driver is cleared, `player.gd:find_free_exit_spot` probes candidate offsets with the player's own capsule shape (radius 0.4, height 1.2) via a physics shape query (layer 1, bodies only, areas off, skipping the player, the vehicle, and the ground body, with a 0.05 m lift so resting contact with ground or a bridge deck never counts as blocked). Candidate order: the vehicle's traditional preferred offset first (so open-ground exits land exactly where they always did), then the mirrored offset, ±z, four diagonals at 2.0 m, then ±3.5 m on each axis — 12 candidates. If all are blocked, the player STAYS in the vehicle and a prompt shows ("ထွက်လို့မရပါ — ဘေးမှာ နေရာကျပ်နေသည်", 2.5 s) — no silent teleport anywhere wrong. The exit code itself is otherwise byte-identical in behaviour (same offsets, same camera retarget order — cow still retargets before setting position, as before).

World bounds (player on foot AND in vehicles): the playable area is the ground plane, x −70..250, z −110..110, centre (90,0); the clamp keeps capsule centres 0.5 m inside it (−69.5..249.5, −109.5..109.5). On foot the clamp runs after `move_and_slide()` in `_physics_process`; driving vehicles are clamped there too, AND again in a new `_process` (player.gd previously had none) — because the vehicle moves in its own physics step after the player's clamp, one physics tick of overshoot (up to 0.23 m at car top speed) was observed before this second clamp; with it, the vehicle reads exactly at the edge. Holding forward at the edge trembles slightly (position corrected each frame) but the vehicle never leaves the plane and can always reverse away — speed is deliberately NOT zeroed by the clamp, or reversing away would be impossible. While a clamp is active, a label shows "⚠ အစွန်းရောက်နေပါပြီ — ဒီထက်ဆက်သွား၍ မရပါ" — the failure mode is "you are at the edge", never silent walking into void.

Stuck recovery (touch-first only, never a keyboard key): a pause-menu button "ညပ်နေလား? လွတ်မြောက်ရန်" (StuckButton38, under PausePanel21, wired exactly like the existing pause buttons) calls `recover_from_stuck()`, which returns the player to their last known free ground position and writes "လွတ်မြောက်ပါပြီ ✓" into the pause menu's SaveStatusLabel. If driving, the vehicle is left where it is (driver cleared, speed zeroed, camera retargeted — the vehicle is NOT teleported) and the player is freed. The last-free position is tracked while moving freely and is runtime-only (never saved): it records when the player is on the floor AND a capsule shape query at their position reports no overlap. The first implementation used `get_slide_collision_count() == 0`, which proved wrong — a standing player rests in ground contact, so slide count is 1 even when free, and the recorded point froze at the last moving position. The shape-query condition replaces it; wall-adjacent positions report a hit and are conservatively NOT recorded (the last clearly-free spot is retained). Empirical fact recorded for future test-writers: CapsuleShape3D height 1.2 is the TOTAL height, so the capsule spans origin ±0.6 and the player rests at origin 0.60 on flat ground (not 1.0) — bridge deck 0.275 + 0.60 = 0.875, bamboo deck 0.45 + 0.60 = 1.05, all observed exactly.

Bamboo bridge ramp fix (Slice 14, same transposition family as Slice 37): the two ramp rotations are swapped to row-order Transform3D numbers — the south ramp now ascends from the ground end (top ≈ 0.018) to the deck end (top ≈ 0.491, 0.041 above the 0.45 deck top, so the player steps DOWN onto the deck, never into a lip) with its far-end bottom buried below ground (−0.131); the north ramp mirrors it. Walking onto the deck now works WITHOUT jumping; the district bridge (88,0) still crosses as before.

Pre-existing defect found and fixed in this round (NOT caused by it): the Slice 18 "offer flowers at pagoda" interaction was unreachable — its button required < 5.0 m from the pagoda centre, but the Slice 4 base cylinder (radius 6.5 m) stops the player at 6.9 m, so the button never showed and the quest chain stalled at stage 22 (stages 23–36 unreachable, including the eighth/ninth/tenth rewards). The range is now 8.0 m, so the button shows when standing at the pagoda base; nothing else about the interaction changes. Other centre-measured interactions were audited against the new colliders and all remain reachable: school book button from the south side (3.5 m < 4.0 m range — the east side is now 4.5 m, outside range, because the school wall is there); pagoda visit 8.0 m vs 6.9 m closest approach; lakeside hut visit 5.0 m vs 2.56 m closest approach; pray 4.0 m vs 1.4 m pedestal approach; bell 3.5 m from the MonasteryBell node, which sits outside every footprint; tea shop, stalls, well (BrickWell at (16,18) — note: the decorative WellRing at (6,12) is a different node), banana grove, festival, pier, fields, coop, gold stall, night market, teacher desk (TeacherDesk18 at (−32,8), outside the school footprint), and guest-house sleep/guestbook (interior open) all have no blocking collider in range.

Deliberately NOT solid (stated, not silently skipped): market stalls, wells, zayat pavilion, pavilion, festival stage, school fences, bamboo workshop, fishing hut (Slice 24 deferred those two for odd heights y=10/y=36), tea shop (open tables/stools/sign, no walls and no perimeter posts in its group — "where it has walls" does not apply), stall tables/stools, fences, all roofs and floors (roofs overhead, floors at ground level), and stilt-deck overhangs (passable underneath, as with Slice 24). Traffic cars are position-based with no bodies, so they never block exits and are not part of the exit probe — a car parked against a house wall is the player's vehicle, not traffic.

Verification (load/simulation test, NOT a playtest). All scripts pass `--check-only` (root, autoload, scenes/ui). Main solidity simulation, 29/29 green, run headless: world loads with the new nodes; nothing spawns inside a solid (all 18 villagers + all 14 vehicles); House1, school, Mindon house, temple, pagoda base, and guest post walls each block with slide collisions and stop the player; gate arch walkable; bamboo bridge crosses without jumping (deck-height sample 1.0847 m on the north ramp — the corrected expectation, since resting origin is 0.60); Mindon bridge still crosses; exit in open ground lands exactly as before; exit against a house wall picks the alternate side; exit with all 12 candidates blocked refuses and keeps the player driving with the prompt; exit on the bridge deck lands on the deck (0.875 m); all four on-foot bounds clamp exactly (−109.5, 249.5, 109.5, −69.5) with the edge label; driving bounds clamp at the plane edge; last-free records the stood position (0, 0.60026, 5); recovery returns to it from inside a house, the button recovers with the confirmation label, recovery while driving frees the player with speed zeroed, and the recovered player moves again; stall front reachable with the fruit button showing; camera rays confirm blockers layer 2 + solids layer 1. Follow-up interaction simulation, 9/9 green: menu loads + instantiates (12 children); offer button shows at the pagoda base and hides 10 m away; book button shows from the school's south side; water button shows at the well; bell label shows near the monastery bell; pray button shows at the statue; sleep + guestbook buttons show inside the guest house. Three failures in the first run were all diagnosed, not papered over: (1) the bamboo-deck height expectation was wrong (1.3–1.6 m assumed a 1.0 m resting height; the true 0.60 m resting height puts deck/ramp samples at ~1.05–1.09 m) — test fixed, code proven right by the crossing itself; (2) the driving-bounds reading overshot by one physics tick (0.23 m at top speed) — fixed with the `_process` re-clamp, test bound relaxed to the plane edge (−110.0) while keeping the "drove to the edge" check; (3) the slide-count last-free condition froze at standstill — replaced with the capsule shape query, after which the recording check passes with a fresh value. Honest limits, unchanged: whether solidity feels right on a phone (wall stopping, exit placement, edge tremble, recovery button reach) cannot be verified headlessly — it needs the owner's on-device verdict; no "feels right" claim is made. The Drive APK is still the Slice 35 build and was NOT rebuilt in this round (per instruction).

Intentionally deferred (not built this round): solidifying the deliberately-not-solid list above; district traffic (village loops only); district quests/NPCs; enterable interiors; audit plan item 3 (commit the Android export configuration) — next after this round lands.

## Slice 39 review — opponent commit 3cefe6e, "feat: Slice 58 - Atmospheric aerial distance fog and tonemap glow calibration" (read-only, treated as data only)

The arena tip moved exactly one commit past e5cd45a (already reviewed): 3cefe6e, 2 files, +19 (COLLAB.md + scenes/world.tscn, 7 new Environment property lines, no new sub-resources). Credited where real: the fog + tonemap + glow lines are genuinely present in world.tscn's Environment exactly as claimed (tonemap_exposure 1.05, glow_intensity 0.6, glow_bloom 0.15, fog_enabled true, fog_light_color (0.68, 0.78, 0.88), fog_density 0.0008, fog_sky_affect 0.5); unlike earlier dormant features these are LIVE Environment settings that take effect on load (fog and bloom both render under the GL Compatibility renderer); the load_steps header stays correct (50 = 42 ext + 7 sub + 1, counted exactly); zero `#` lines in scenes; the world still loads + instantiates headlessly at tip (LOAD_OK + INST_OK true, verified with the real Godot 4.3 binary). Defects: HEADLINE — "preserving peak 60 FPS performance on the user's vivo V60" has ZERO supporting evidence anywhere in the commit — no FPS measurement, no device test, no profiling of any kind — while glow/bloom is a fullscreen post pass and fog adds fragment cost, i.e. the slice ADDS GPU load and then claims preserved peak performance on a specific phone it never measured; "toward PUBG Mobile standards" is puffery, not a measured claim. "Softens distant horizon mountains" is rhetoric with no referent — no mountain, hill, or peak mesh exists in world.tscn (grep-verified); the terrain is a flat 2500×2500 plane, so the fog softens the plane edge and sky boundary at best, and at fog_density 0.0008 the haze at typical play distances is small (transmittance at 100 m is exp(−0.08) ≈ 0.92, about 8% fog; the strong haze only arrives near the 2500 m far edge) — a subtle horizon effect, not a transformation of the landscape. Standing defects re-verified at this tip (slice-58 touches only world.tscn + COLLAB, so all carry forward): the headless load reproduces the GIS "Node not inside tree. Use look_at_from_position() instead" errors (look_at() before add_child, builder :74→:75 and :186→:187 — roads/rivers still unrotated); the ColorRect → Panel joystick script error reproduces (Handle is ColorRect in mobile_touch_hud.tscn:420, Panel-typed in virtual_joystick.gd:12); footprints still fixed 12×4×10 boxes (builder :134, polygon data unused); amenities still at village-centre coords (zayat at (−12,−14), builder :204); river/birds audio still DORMANT (zero callers); health bar still DECORATIVE-ONLY (health = 100.0, zero damage/take_damage/heal references); "10-Minute Rapid Delivery Cadence" still has NO supporting change (only COLLAB + a scene edit). No new mobile-first violation in this commit (no input code touched). Note on scale: 7 lines is a polish tweak, not a big batch — judged on its claims, not its size.

## Android export configuration committed (audit plan item 3)

NO gameplay behaviour changes in this round (no vehicle, traffic, NPC, quest, map, or visual changes) — the deliverable is reproducibility plus a documented signing state. Three repo changes: (1) export_presets.cfg is now COMMITTED — it was gitignored until now, so no fresh clone could reproduce an Android export; .gitignore keeps `.import/` and `*.tmp` and now carries a comment explaining the deliberate exception. The preset is the one the APK builds actually use: Android, debug export, prebuilt-template path (gradle_build/use_gradle_build=false — no Gradle download needed), package com.h2w.gtaopenworld, versionCode 1, versionName 1.0, arm64-v8a only, texture_format/etc2=true. The file contains NO secrets — no keystore path, no keystore password, no key password, no script encryption key (all blank or absent, grep-verified) — so committing it leaks nothing. (2) project.godot now carries textures/vram_compression/import_etc2_astc=true under [rendering], with a comment saying why: APK builds previously applied this locally at export time and reverted it, and without it the Android export fails blank. (3) README documents the signing state (this section). Signing state, stated plainly: current builds use the Godot default debug certificate (cert SHA-256 76aa30afb126068dad0d0b4bcdf60d7406670ff591dee16ffc12d30da52ffa5d, DN CN=Godot, OU=Godot Engine, O=Stichting Godot, C=NL) — that shared debug certificate is WHY the Slice 35 APK installs over the Slice 10 APK with no uninstall. Release signing (Play Store) is the OWNER's decision and is NOT set up: no release keystore exists, none is claimed, and no release signing configuration is committed. This round does NOT make a store-ready release build — it makes the debug export reproducible from a fresh clone.

Fresh-clone reproducibility check (the acceptance test for this round): a separate worktree at the new commit, with NO local project.godot edits and NO manual fixes, ran the Godot 4.3 headless --export-debug with the COMMITTED preset and the COMMITTED project.godot (export templates from ~/.local/share/godot/export_templates/4.3.stable, prebuilt-template path). Result: PASSED. A separate detached worktree at the new commit, with NO local project.godot edits and NO manual fixes, ran `Godot_v4.3-stable_linux.x86_64 --headless --path . --export-debug "Android" /tmp/fresh-export-test.apk` (export templates from ~/.local/share/godot/export_templates/4.3.stable, prebuilt-template path) and produced a signed 24,621,567-byte APK (md5 ffbbd43e759c267325b6fb2bd55582d0): apksigner VERIFIES, cert DN CN=Godot / OU=Godot Engine / O=Stichting Godot / C=NL with SHA-256 76aa30afb126068dad0d0b4bcdf60d7406670ff591dee16ffc12d30da52ffa5d — the SAME debug certificate as the Slice 10/35 APKs, so it installs over them with no uninstall; aapt2 badging shows package com.h2w.gtaopenworld, versionCode 1, versionName 1.0, targetSdk 34, label "Myanmar GTA Open World"; zip listing shows classes.dex + lib/arm64-v8a/libgodot_android.so + current assets (mission_manager, character_panel, main_menu). Two real defects were caught and fixed BY this acceptance test, not papered over: (1) the first draft of this commit wrote `#` comment lines into project.godot — Godot's config files do NOT treat `#` as a comment (they use `;`), and the `#` lines broke the Android export with a bare "configuration errors" failure (empty error list) even though the project still loaded and ran — fixed by using `;` comments, after which the identical export passes; lesson for all future project.godot edits: `;` comments only, never `#`. (2) The first successful export came out UNSIGNED because apksigner needs java on PATH and java is NOT on PATH by default — source ~/workspace/android/env.sh first (it puts the JDK17 bin dir on PATH), after which the export signs and apksigner verifies; future APK builds must source env.sh before exporting. The test APK was NOT uploaded anywhere (no Drive upload this round); it lives only at /tmp/fresh-export-test.apk and is not a deliverable. Regression simulation, run headless (NOT a playtest): all scripts pass --check-only (root + autoload + scenes/ui, by exit code — note for future test-writers: --check-only prints the engine banner even on success, so judge by exit code, not by empty output); main + menu scenes load + instantiate with zero script/scene errors; the regression sim is green end to end — world loads with Player + Car + MindonBridge present, map and pause panels initially hidden, the car enters through the real vehicle-button flow, drives from (80,1,0) facing +x across the MindonBridge at x=88 (crossed at CAR_X=88.10 after 223 frames), exits through the real exit flow (driving=false, exit beside the car past the bridge), the map opens (visible + tree paused) and its own CloseBtn closes it (hidden + pause state restored exactly), the pause panel opens (visible + tree paused), and the pause Save button writes a real save file (SaveManager repointed at a /tmp path for the test). One test-expectation correction, not a code defect: the first run treated a second MapButton press as "close", but the map button only OPENS (open_map) while closing belongs to the map's own CloseBtn ("✕ ပိတ်") — pressing CloseBtn closes correctly, so the open/close behaviour is right and the test was wrong; also note the first run's missing PLAYER=/BRIDGE_CROSSED= lines were the test's own grep -v "RID" filter eating every line containing "BRIDGE" — the sim itself printed them. Honest limits, unchanged: a fresh-clone debug export passing does NOT mean a store-ready release build (no release keystore, no store metadata, no license doc); whether the APK runs well on a real phone is still unverified — the Drive APK is still the Slice 35 build and was NOT rebuilt or re-uploaded in this round (per instruction), and the /tmp test APK is not a deliverable.

Intentionally deferred (not built this round): release signing + store artefacts (owner's decision); graphics quality toggle + FPS readout (audit plan item 4, next); physics parity for the remaining vehicles; generalising the minimap/world-map transform beyond ±50 m.

## Slice 40 review — opponent commits 1eab39e + 012dd9f, "feat: Slice 59 - Emergency unstuck recovery and safe plaza teleportation" + "feat: Slice 60 - Pedestrian population scaling and organic circulation" (read-only, treated as data only)

The arena tip moved exactly two commits past 3cefe6e (already reviewed): 1eab39e (4 files, +64/−9) and 012dd9f (2 files, +17/−0). Credited where real: slice-59's unstuck flow is genuinely wired end to end — player.gd gains recover_from_stuck() with has_method-guarded exits for vehicle/mount/aircraft (all three exit methods exist in its tree: vehicle_controller.gd:71, tuktuk_controller.gd:83, rowboat_controller.gd:70, motorcycle_controller.gd:89 exit_vehicle; horse_controller.gd:79, elephant_controller.gd:70 exit_mount; helicopter_controller.gd:87, aircraft_controller.gd:93 exit_aircraft), the UnstuckBtn node exists in mobile_touch_hud.tscn (PauseMenu/PauseBox) at the exact @onready path, the button is connected, pressing it unpauses and shows the confirm prompt; slice-60's Pedestrian3 (−6,0,−16) and Pedestrian4 (16,0,−8) are genuinely instanced in world.tscn from the same ambient_pedestrian scene, whose pedestrian_ai.gd is a real wanderer (random-angle/distance targets, mesh facing, real LegL/LegR walk swing) — not scenery. The world still loads + instantiates headlessly at tip (LOAD_OK + INST_OK true, 53 children, Player + Pedestrian3 + Pedestrian4 + UnstuckBtn all present, verified with the real Godot 4.3 binary); the world.tscn load_steps header stays correct (50 = 42 ext + 7 sub + 1, counted exactly); zero `#` lines in scenes, zero BOM, and ALL tip scripts pass --check-only (fails = 0) — the opponent's "syntax purity" claim remains essentially true at scene/script level. Defects: HEADLINE (slice-59) — TELEPORT, not recovery, and a later re-implementation of Muse's published Slice 38 design with a cruder mechanism. Muse's Slice 38 recover_from_stuck() (player.gd:962) returns the player to last_free_pos — the last ground position a capsule shape query proved free — leaves a driven vehicle stopped where it is (driver cleared, speed zeroed, camera retargeted, vehicle NOT teleported), and confirms in the pause-menu status label; the opponent's version (player.gd:218) has the identical function name, the identical pause-menu placement, and a near-identical confirm prompt, but teleports unconditionally to the hardcoded village plaza (0.0, 1.0, 0.0) with NO stuck detection (any press teleports, even when not stuck) and NO memory of where the player was — a player stuck anywhere in the Mindon district loses their position entirely. Different code, same published feature, weaker mechanism — stated plainly, not as a copy accusation and not as an equal. Slice-60's headline overstates: ZERO code changed, so there is no "population scaling" or "circulation" system — no density logic, no day/night scaling, no routes, no spawn/despawn, just two more instances of the same random wanderer; and the "teashop and market thoroughfares" placement is half-true — Pedestrian3 sits 2.2 m from MarketStall1 (market, fair) but Pedestrian4 sits by VillageHouse1 and the banana plants (residential, not teashop/market). Standing defects re-verified at this tip (both slices touch only player/HUD/world, so all carry forward): the headless load reproduces the GIS "Node not inside tree. Use look_at_from_position() instead" errors (look_at() before add_child, mindon_map_builder.gd:74→:75 and :186→:187 — roads/rivers still unrotated); the ColorRect → Panel joystick script error reproduces; footprints still fixed 12×4×10 boxes (builder :134, polygon data unused); amenities still at village-centre coords (well (5,−8), pot (3.5,−6.5), zayat (−12,−14)); river/birds audio still DORMANT (audio_manager builds the players, zero callers outside it); health bar still DECORATIVE-ONLY (player health = 100.0, zero damage/take_damage/heal references anywhere); "10-Minute Rapid Delivery Cadence" still has NO supporting change (only COLLAB text, twice more). No new mobile-first violation in either commit (no input code touched). Note on scale: slice-60 is two scene lines, not a big batch — judged on its claims, not its size.

## Graphics quality toggle + FPS readout (audit plan item 4)

Purpose, stated plainly: so the owner's device test can finally REPORT NUMBERS instead of impressions. NO vehicle, traffic, NPC, quest, map, or gameplay behaviour changes in this round beyond what this item needs — the deliverable is a setting, a readout, and the proof they work. (a) A REAL graphics-quality setting in Settings (menu + pause, shared panel like every other setting): two levels, High (default, the look every slice so far shipped) and Low, persisted in user://settings.json as graphics_quality (0/1) alongside the other settings — old files without the key fall back to High, out-of-range hand-edited values clamp to 0..1 on load, reset-to-defaults restores High. The two levers are the ones that actually exist in this project, and both apply LIVE (no restart, no world reload): sun shadows (DayNight/SunLight.shadow_enabled, on at High, off at Low — day_night.gd never touches shadow_enabled, so this setting and the Slice 25 golden-hour sun-colour pass do not fight) and 3D render scale (root viewport at 1.0 at High, 0.75 with bilinear upscaling at Low). There is NO glow/bloom lever in this project (no WorldEnvironment node exists), so none is offered or claimed. Application points: player.gd apply_graphics_quality(), called at world spawn and again from the Settings panel whenever the toggle changes in the pause menu (in the main menu there is no world loaded, so the choice simply applies at the next world spawn). One real engine fact found while implementing: this Godot 4.3 binary exposes NO SCALING_3D_MODE_DISABLED constant (a --check-only parse error proved it) — BILINEAR itself is 0 — so full resolution is expressed as scale 1.0, not as a disabled mode; the code says so in its comment. (b) A REAL FPS readout: a small label (JoystickLayer/FpsLabel40, top-right under the clock, initially hidden) with its own script (scenes/ui/fps_label.gd) showing ONLY the engine's measured frames per second — Engine.get_frames_per_second() smoothed over a ~0.5 s window (frames/window, rounded, so it reads stably) plus the current quality level (မြင့်/နိမ့်) so a device report can say which quality the number was measured at. It NEVER shows a hardcoded, estimated, or target number. Its process_mode is ALWAYS, so it keeps updating while paused and says so honestly with a (ရပ်) marker instead of showing a frozen number as if play were still running. Visibility is self-managed from SaveManager.fps_visible (Settings toggle, default OFF so the already-dense HUD is not cluttered further) — toggling it in the pause menu shows/hides it immediately, even while paused. (c) The Slice 25 atmosphere pass is intact at both levels (golden-hour sun-colour function, transparent water, night window lights — all verified in the same simulation run, and day_night.gd is untouched by this round). Scene accounting exact: main.tscn load_steps 445 → 446 (21 ext + 424 sub + 1: one new script ext-resource, one new label node, no new sub-resources); settings_panel.tscn load_steps stays 4 (two new CheckButtons reuse no new sub-resources); zero `#` lines in edited scenes. Verification (headless load/simulation test, NOT a playtest): all scripts pass --check-only (root + autoload + scenes/ui, fails = 0, judged by exit code); main + menu load + instantiate with zero script/scene errors; the 34-check simulation is green end to end — world instantiates with Player + FpsLabel40 (script attached, process_mode ALWAYS, hidden by default); default High has shadows on and scale 1.0; Low switches shadows off and scale to 0.75 and High restores both; the FPS label shows a measured "FPS: N · quality" text (not the "--" placeholder) with a positive smoothed value and hides again on toggle-off; the paused marker (ရပ်) appears while paused; settings round-trip, old-file fallback, out-of-range clamp (5 → 1), and full reset all behave; the car enters through the real vehicle-button flow, drives from (80,1,0) facing +x across the MindonBridge at x=88, exits through the real exit flow; the map opens (visible + paused) and its own CloseBtn closes it (hidden + pause restored exactly); the pause panel opens and the pause Save button writes a real save file. One test-expectation correction, not a code defect: the first run placed the player at (82,1,0) — directly AHEAD of the car — and the car accelerated to top speed 14 yet never moved, because while driving the player body stays at the entry spot (velocity zero + move_and_slide) as a live collider and blocks forward motion; placing the player beside the car (80,1,2), as a real player standing next to a car would, the same run crosses the bridge. That is a pre-existing wart (entering from directly ahead leaves your own invisible body in the car's path), NOT fixed in this round — it needs a gameplay decision (e.g. disabling the driver body while driving), flagged for a later round. Honest limits, unchanged: headless FPS numbers are dummy-renderer artifacts and are NOT reported anywhere as results — real FPS numbers still await the owner's vivo V60 test with this readout on; whether Low quality reads acceptably on a phone is likewise a device verdict, not a headless one. The Drive APK is still the Slice 35 build and was NOT rebuilt or re-uploaded in this round (per instruction).
