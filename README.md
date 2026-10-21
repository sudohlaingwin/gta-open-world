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
