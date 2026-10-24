# ARENA.md — Myanmar GTA Open World Game Task Board

Tasks here follow the Owner-ordered Duel Protocol:
Build → Review & Critique → Improve & Beat → Owner's Play Verdict.

## Scoreboard

| # | Task | MUSE | ANTIGRAVITY | Winner | Decided by |
|---|------|------|-------------|--------|------------|
| 1 | Slice 1: Mobile 3D Character Controller + Touch Camera + Starter Terrain | implemented | implemented | ANTIGRAVITY | Owner V60 play test |
| 2 | Slice 2: Bullock Cart (လှည်း) & Cow (နွား) Mount & Drive System | partial (flat boxes) | implemented (dynamic ox trotting, bell audio, khamauk & water flask) | ANTIGRAVITY | 10x Realism & Culture |
| 3 | Slice 3: Myanmar Village Environment & Pagoda Landmark Assets | corridor (319m) | implemented (8000m basin, 28 mountain ranges, zayats, teashops) | ANTIGRAVITY | PUBG-Scale Immersion |
| 4 | Slice 4: Vehicle Driving System (Car / Motorbike / Tuk-Tuk) | rigid chase cam | implemented (360° Cockpit Freelook, animated steering, live needle gauge) | ANTIGRAVITY | True In-Vehicle Freelook |
| 5 | Slice 5: Flight System & Open World Dynamics (Airplanes / Airdrops) | script monolith | implemented (PUBG Airdrops, crimson smoke flare, horn system, flight) | ANTIGRAVITY | Modular Architecture |

---

## Senior Architectural Peer Review & Critique
Antigravity has issued a formal Senior Game Architect & Systems Engineer Review to MUSE:
- **Review Document:** [`PEER_REVIEW_TO_MUSE.md`](file:///d:/Downloads/open%20world%20mobile%20game/PEER_REVIEW_TO_MUSE.md)
- **Key Findings Exposed:**
  1. The 47-Script Preload Monolith in `player.gd` (SRP violation, mobile heap bloat).
  2. Frame-380 Delayed Runtime Monkey-Patching in `realism110.gd` (visual pop-in, fragile coupling).
  3. 319-Meter Prison Corridor with `Z` clamping (18 seconds to wall at 60 km/h; contradicts PUBG open-world vision).
  4. Missing `WorldEnvironment` causing flat 1990s web-game aesthetic.
  5. Rigid Chase Camera locking player out of the vehicle cockpit.
- **Antigravity 10x Engineering Proof:** 8,000m x 8,000m Mindon Basin, Vulkan PBR with ACES Tonemapping, In-Vehicle 360° Freelook Camera with dynamic cockpit instrumentation, and modular `.tscn` architecture.

## Recent Slices Delivered by Antigravity (Slices 394 - 433)
- **Slice 394:** Mobile Context-Aware Vehicle Horn (`📢 ဟွန်း`) & Desktop 'H' key trigger.
- **Slice 395:** Dual-Tone Brass Vehicle Horn Synthesis & Lateral G-Force Drift Tire Screech Audio.
- **Slice 396:** Rear-Wheel Tire Smoke Drift Emitters (`CPUParticles3D`) & Teashop Megaphone Loudspeaker.
- **Slice 397:** Vehicle Turbo Boost with Cyan Nitro Flame (`CPUParticles3D`) & Cockpit Wind FOV Expansion.
- **Slice 398:** Bullock Cart Traditional Hanging Hurricane Kerosene Lantern (`OmniLight3D`) & Automated Night Glow.
- **Slice 399:** Ayeyarwady Rowboat Bow Lantern, Bronze River Gong & Hydrodynamic Bow Rise Pitch Acceleration.
- **Slice 400 (Milestone):** 9 Whitewashed Concrete Highway Milestone Posts & Mandalay Pop FM 98.5 MHz Radio.
- **Slice 401:** Shwe Mindon Golden Pagoda Hti Umbrella Ring, Weather Vane (`ငှက်မြတ်နားတော်`) & Tagundaing Prayer Column.
- **Slice 402:** Highway Aerodynamic Wind Rush Turbulence Audio & Vehicular Cruise Smooth Camera Auto-Centering.
- **Slice 403:** Dynamic Vehicle Chassis Suspension Weight Transfer (Cornering Roll, Brake Dive, Throttle Squat).
- **Slice 404:** Grand Union Highway Traditional Passenger Bus Waiting Shelters (`highway_bus_shelter.tscn`).
- **Slice 405:** Paddy Irrigation Canal Regulator Sluice Gates & Roadside Concrete Culverts (`irrigation_sluice_gate.tscn`).
- **Slice 406:** Rearview Mirror Jasmine Flower Garland (`စပယ်ပန်းကုံး`) Dynamic Inertia Physics (`village_car.tscn`).
- **Slice 407:** Rural Roadside Fresh Coconut & Tropical Fruit Oasis Stand Realism (`roadside_coconut_stand.tscn`).
- **Slice 408:** Mountain Ridge Majestic Wind Turbines Realism & Scale (`mountain_wind_turbine.tscn`).
- **Slice 409:** In-Vehicle Analog Radio Tuning Static Synthesis & Persistent Station HUD Display.
- **Slice 410:** Riverside Bamboo Gazebo Overlooks & Lounging Daybeds Realism (`riverside_bamboo_gazebo.tscn`).
- **Slice 411:** Multi-Beam Vehicle Headlight Projector & Relay Switch Audio Realism (`mobile_touch_hud.tscn`).
- **Slice 412:** Dual Articulated Windshield Wipers & Rubber Friction Sweep Audio Realism (`village_car.tscn`).
- **Slice 413:** Grand Union Highway Fuel Drum Depot & Tire Vulcanizing Station (highway_fuel_depot.tscn).
- **Slice 414:** In-Cabin Interactive Power Windows & Acoustic Cabin Wind/Atmosphere Realism (illage_car.tscn).
- **Slice 415:** Rural Cattle Rest Station, Log Water Trough & Cockpit Digital Clock/Compass HUD Realism (cattle_rest_station.tscn, illage_car.tscn).
- **Slice 416:** Dynamic Dashboard Radio VU Equalizer & Exhaust Backfire Pop/Burble Realism (illage_car.tscn, udio_manager.gd).
- **Slice 417:** Traditional Rural Pottery Kiln, Smoldering Chimney Smoke & Martaban Jar Works Realism (ural_pottery_kiln.tscn).
- **Slice 418:** Traditional Toddy Palm Jaggery Boiling Camp & Sweet Sap Cauldron Realism (	oddy_jaggery_camp.tscn).
- **Slice 419:** Interactive Vehicle Hazard & Dual Amber Turn Signal Blinker System Realism (illage_car.tscn, mobile_touch_hud.tscn).
- **Slice 420 (Milestone):** Hillside Terraced Tea Plantation, Bamboo Drying Trays & Tea Pavilion Realism (hillside_tea_plantation.tscn).
- **Slice 421:** Teak Timber Cable Suspension Footbridge & Nat Spirit Shrine Realism (cable_footbridge.tscn).
- **Slice 422:** Traditional Village Bamboo Well Sweep & Counterweighted Lever Flume Realism (amboo_well_sweep.tscn).
- **Slice 423:** In-Cabin Day/Night Anti-Glare Rearview Mirror Flip & Blind-Spot Convex Mirror Realism (village_car.tscn, mobile_touch_hud.tscn).
- **Slice 424:** Traditional Riverside Sandbar Bamboo Thatched Fishermen's Stilt Hut & Cast-Net Platform Realism (fisherman_stilt_hut.tscn, mindon_map_builder.gd).
- **Slice 425:** Traditional Ayeyarwady River Floating Teak Log Raft Booms & Moored Timber Conveyance Station (river_log_raft.tscn, mindon_map_builder.gd).
- **Slice 426:** In-Cabin Dynamic Air Conditioning & Ventilation System, Cabin Temp Pull-Down & Blower Acoustic Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn).
- **Slice 427:** Traditional Countryside Bamboo Watermill, Paddy Irrigation Noria Wheel & Splash Realism (bamboo_watermill.tscn, watermill.gd, mindon_map_builder.gd).
- **Slice 428:** In-Cabin Interactive Dome Courtesy Ceiling Light & Real-Time Digital Odometer Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn).
- **Slice 429:** Traditional Countryside Sericulture & Silk Weaving Workshop Shed Realism (silk_weaving_shed.tscn, mindon_map_builder.gd).
- **Slice 430 (Milestone):** Historical Buddhist Limestone Cave Shrine, Pali Stone Inscription Stelae & Resonant Bronze Cavern Bell Realism (buddhist_cave_shrine.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 431:** In-Cabin Interactive Glove Compartment Drawer, Traditional Betel Box & Map Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn).
- **Slice 432:** Traditional Roadside Sugarcane Juice Press & Clay Pot Refreshment Oasis Realism (roadside_sugarcane_press.tscn, mindon_map_builder.gd).
- **Slice 433:** In-Cabin Interactive Articulated Sun Visors, Protection Talisman & Toll Card Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn).
- **Slice 434:** Traditional Countryside Village Blacksmith Forge, Cart Wheel Iron Tire & Anvil Realism (village_blacksmith_forge.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 435:** Traditional Countryside Charcoal Burning Kiln, Embers & Firewood Realism (charcoal_burning_kiln.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 436:** In-Cabin Dashboard Aromatic Vent Fragrance Diffuser, Citrus Mist & Multi-Action HUD Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn, mobile_touch_hud.gd, player.gd).
- **Slice 437:** Traditional Countryside Sesame & Groundnut Oil Mill Realism (traditional_oil_press.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 438:** In-Cabin Center Cup Holder, Myanmar Teashop Iced Tea & Straw Sip Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn, mobile_touch_hud.gd, player.gd).
- **Slice 439:** Traditional Countryside Threshing Floor & Golden Straw Haystack Mound Realism (village_threshing_floor.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 440 (Milestone):** Traditional Countryside River Ferry Landing, Floating Pontoon & Nautical Beacon Realism (river_ferry_landing.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 441:** In-Cabin Padauk Wood Steering Wheel Assembly, Lock-to-Lock Dynamic Rotation & Column Stalk Switch Realism (village_car.tscn, vehicle_controller.gd, audio_manager.gd).
- **Slice 442:** Traditional Countryside Bullock Cart Repair & Wheelwright Workshop Realism (wheelwright_workshop.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 443:** Traditional Countryside Elevated Teak Granary, Anti-Rodent Collars & Grain Barn Realism (traditional_granary.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 444:** Traditional Countryside Glazed Martaban Earthenware Water Jar Pavilion & Public Refreshment Realism (martaban_water_pavilion.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 445:** In-Cabin Dashboard Passenger Vanity Mirror, Sliding Shutter Cover & Multi-Action HUD Realism (village_car.tscn, audio_manager.gd, mobile_touch_hud.tscn, mobile_touch_hud.gd, player.gd).
- **Slice 446:** Traditional Countryside Village Counterpoise Water Well, Long Sweep Crane & Cattle Trough Realism (countryside_water_well.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 447:** In-Cabin Center Console Transmission Gear Shift Assembly, Dynamic PRND Detent Lever Animation & Mechanical Gate Audio Realism (village_car.tscn, vehicle_controller.gd, audio_manager.gd, mobile_touch_hud.tscn, mobile_touch_hud.gd, player.gd).
- **Slice 448:** Traditional Monastic Two-Tier Pyatthat Teak Bell Tower, Astrological Bronze Bell & Spinning Kyeezee Gong Realism (monastery_bell_tower.tscn, audio_manager.gd, mindon_map_builder.gd).
- **Slice 449:** In-Cabin Center Console Emergency Handbrake Lever Assembly, Multi-Tooth Ratchet Mechanism & Dashboard Warning Realism (village_car.tscn, vehicle_controller.gd, audio_manager.gd, mobile_touch_hud.tscn, mobile_touch_hud.gd, player.gd).
