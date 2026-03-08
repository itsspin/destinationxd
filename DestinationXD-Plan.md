# DestinationXD — The Ultimate WoW Navigation Addon

## Project Plan & Claude Code Development Prompt

**Author:** Spacebutt (Travis)
**Target:** World of Warcraft: Midnight (Patch 12.0.x, TOC: 120000)
**License:** All Rights Reserved (or your preference)
**Language:** Lua (WoW Addon API)

---

## 1. VISION & IDENTITY

**DestinationXD** is a premium in-world navigation addon for World of Warcraft: Midnight that makes getting anywhere in the game world intuitive, beautiful, and effortless. It solves the #1 problem every waypoint addon ignores: **telling you WHERE something actually is in 3D space** — not just its map coordinates.

### What Makes DestinationXD Different

Most waypoint addons (including WaypointUI, TomTom, Map Pin Enhanced) operate in 2D. They project a beam or arrow onto the map surface and call it a day. When your destination is inside a cave below you, on a different floor, behind a cliff, or accessible only through a portal — those addons leave you running in circles.

DestinationXD is a **3D-aware, elevation-conscious, route-intelligent** navigation system that:

1. Shows a stunning in-world waypoint beam (visually competitive with WaypointUI)
2. Provides clear **elevation indicators** (above/below/same level) at all times
3. Decomposes distance into **horizontal + vertical** components
4. Detects when you're **obstructed by terrain** and indicates "find an entrance"
5. Includes a **Smart Travel Planner** — click a zone, get routed via the fastest path (portals, hearthstones, flight paths)
6. Works **out of the box** with zero configuration
7. Is built from the ground up for **WoW Midnight (12.0)** API compatibility

### Name Rationale

"DestinationXD" — "Destination" describes exactly what it does. "XD" adds personality, is memorable, and resonates with the WoW community's tone. The tagline: **"You'll actually get there."**

---

## 2. MIDNIGHT API COMPATIBILITY NOTES

### What Changed in Midnight (12.0)

Blizzard implemented "addon disarmament" — restricting combat addons via "secret values" that hide real-time combat data. **This does NOT affect navigation addons.** Per Blizzard's own communication: *"The changes are not intended to prevent 'look and feel' customization of UI elements."*

### APIs We Use (All Confirmed Working in 12.0)

| API | Purpose | Status in 12.0 |
|-----|---------|----------------|
| `C_Map.GetPlayerMapPosition(uiMapID, "player")` | Player 2D map position | ✅ Working |
| `C_Map.GetBestMapForUnit("player")` | Current map ID | ✅ Working |
| `C_Map.GetMapInfo(uiMapID)` | Map metadata (name, type, parent) | ✅ Working |
| `C_Map.GetMapChildrenInfo(uiMapID)` | Child zone enumeration | ✅ Working |
| `C_Navigation.GetDistance()` | Distance to tracked waypoint (yards) | ✅ Working |
| `C_Navigation.GetFrame()` | Navigation frame reference | ✅ Working |
| `C_SuperTrack.GetSuperTrackedQuestID()` | Currently tracked quest | ✅ Working |
| `C_SuperTrack.IsSuperTrackingAnything()` | Tracking state check | ✅ Working |
| `C_SuperTrack.IsSuperTrackingUserWaypoint()` | User waypoint check | ✅ Working |
| `C_SuperTrack.SetSuperTrackedUserWaypoint()` | Set user waypoint tracking | ✅ Working |
| `UnitPosition("player")` | **3D world position (Y, X, Z, instanceID)** | ✅ Working (open world) |
| `C_QuestLog.GetQuestTagInfo(questID)` | Quest type metadata | ✅ Working |
| `C_QuestLog.GetInfo(index)` | Quest log data | ✅ Working |
| `C_Map.GetWorldPosFromMapPos()` | Convert map coords → world coords | ✅ Working |
| `C_TaxiMap.GetAllTaxiNodes(uiMapID)` | Flight path data | ✅ Working |

### TOC File Header

```
## Interface: 120000
## Title: DestinationXD
## Notes: You'll actually get there. 3D-aware navigation with elevation tracking, smart routing, and stunning visuals.
## Author: Spacebutt
## Version: 1.0.0
## SavedVariables: DestinationXDDB
## IconTexture: Interface\AddOns\DestinationXD\Media\icon
## X-Category: Map & Minimap
## X-Website: https://github.com/YOUR_REPO_HERE
```

---

## 3. CORE ARCHITECTURE

### File Structure

```
DestinationXD/
├── DestinationXD.toc
├── Core/
│   ├── Init.lua              -- Addon initialization, saved variables, event bootstrap
│   ├── Config.lua             -- Default settings (works out of box, no config needed)
│   ├── SlashCommands.lua      -- /dxd, /way command handling
│   └── Utils.lua              -- Math helpers, color utilities, throttle functions
├── Modules/
│   ├── Beacon/
│   │   ├── Beacon.lua         -- The in-world waypoint beam (the "wow factor")
│   │   ├── BeaconAnimations.lua -- Pulse, glow, proximity morphing animations
│   │   └── BeaconPool.lua     -- Object pooling for multiple waypoints
│   ├── Elevation/
│   │   ├── ElevationTracker.lua  -- Z-coordinate tracking & delta calculation
│   │   ├── ElevationHUD.lua      -- On-screen UP/DOWN/LEVEL indicator
│   │   └── FloorDetection.lua    -- Multi-floor area detection
│   ├── Navigator/
│   │   ├── DirectionArrow.lua    -- 3D-aware directional arrow with pitch
│   │   ├── DistanceDisplay.lua   -- Decomposed distance (horizontal + vertical)
│   │   └── ProximityManager.lua  -- Smart arrival detection (Z-aware)
│   ├── Tracker/
│   │   ├── QuestTracker.lua      -- Hook into quest supertracking
│   │   ├── WaypointTracker.lua   -- /way and user pin tracking
│   │   └── IntegrationBridge.lua -- TomTom, HandyNotes compatibility
│   ├── TravelPlanner/
│   │   ├── TravelPlanner.lua     -- Smart route calculation engine
│   │   ├── PortalDatabase.lua    -- Known portals, hearthstone networks, mage portals
│   │   ├── FlightPathGraph.lua   -- Flight master network graph
│   │   ├── ZoneBrowser.lua       -- UI for browsing continents → zones
│   │   └── RouteDisplay.lua      -- Step-by-step route visualization
│   └── Pinpoint/
│       ├── Pinpoint.lua          -- In-world quest info display
│       └── PinpointFormatting.lua -- Context-aware text/icon formatting
├── UI/
│   ├── MinimapButton.lua      -- Minimap icon (LibDBIcon integration or custom)
│   ├── SettingsPanel.lua      -- Options panel (Interface → AddOns → DestinationXD)
│   ├── TravelPlannerFrame.lua -- The zone browser / route planner window
│   └── Widgets.lua            -- Reusable UI components (buttons, dropdowns, scrolling)
├── Media/
│   ├── icon.tga               -- Minimap/addon icon
│   ├── beacon_beam.tga        -- Beam texture (tall gradient)
│   ├── beacon_glow.tga        -- Beam base glow
│   ├── beacon_ring.tga        -- Proximity ring texture
│   ├── arrow_up.tga           -- Elevation: above indicator
│   ├── arrow_down.tga         -- Elevation: below indicator
│   ├── arrow_level.tga        -- Elevation: same level indicator
│   ├── arrow_direction.tga    -- Navigator arrow texture
│   ├── wall_icon.tga          -- Obstruction indicator
│   ├── portal_icon.tga        -- Portal marker
│   ├── sounds/
│   │   ├── waypoint_set.ogg
│   │   ├── waypoint_arrive.ogg
│   │   └── elevation_change.ogg
│   └── fonts/
│       └── destination.ttf    -- (optional) Custom clean font
├── Data/
│   ├── PortalData.lua         -- Static portal/teleport location database
│   ├── ZoneData.lua           -- Zone hierarchy (Continent → Zone → Subzone)
│   ├── FloorData.lua          -- Known multi-floor areas with Z ranges
│   └── MidnightZones.lua      -- Midnight-specific zone data (Quel'Thalas, etc.)
└── Libs/                      -- Embedded libraries
    ├── HereBeDragons/         -- Coordinate math library
    ├── LibStub/               -- Library loading
    ├── CallbackHandler/       -- Event callbacks
    └── LibDBIcon/             -- Minimap button standard
```

### Initialization Flow

```
1. ADDON_LOADED → Register saved variables, set defaults
2. PLAYER_LOGIN → Initialize all modules, create frames
3. PLAYER_ENTERING_WORLD → Start position polling, detect current zone
4. SUPER_TRACKING_CHANGED → Update beacon target
5. OnUpdate (throttled 20fps) → Update beam position, elevation, distance, arrow
```

---

## 4. MODULE SPECIFICATIONS

### 4.1 BEACON MODULE (The In-World Waypoint)

The Beacon is the visual centerpiece — a vertical beam of light projected at the destination in world-space. It must look stunning from distance but transform into something more useful at close range.

**Visual Design (Minimalist — Think Laser, Not Lighthouse):**

- **Far (100+ yards):** A thin, luminous vertical line of light — 2-4px wide on screen. NOT a thick pillar. Think laser beam, not search light. Soft gaussian glow aura around the line (layered textures, 8-12px blur feel). Tiny circular glow on the ground at the base, no ring, no marker. Gentle sine-wave opacity pulse (70% → 90% → 70%) over 3 seconds. Color is contextual (gold = quest, cyan = user pin, etc.)
- **Medium (30-100 yards):** Same thin line, height reduces proportionally. Glow intensifies slightly. Tiny elevation chevrons (▲ or ▼) appear spaced along the beam shaft, drifting slowly upward or downward — the only hint you need.
- **Close (<30 yards):** Beam dissolves into a single floating point of light (firefly-like). The point gently bobs 2-3px vertically (breathing). If significant elevation delta, the point stretches into a thin arrow shape pointing up or down. Ground marker: single soft dot, no ring, no border.
- **Arrival (<5 yards, same level):** Point blooms outward (1x → 2x over 0.4s), opacity fades to 0 over 0.8s with cubic easing. Subtle white flash (0.2s, 40% max). Gone. Clean. Nothing lingers.

**Technical Implementation:**

```lua
-- Beacon uses a combination of:
-- 1. WorldFrame-anchored Model or Texture for the beam
-- 2. C_Map.GetWorldPosFromMapPos() to convert waypoint map coords to world position
-- 3. WorldToScreenPoint() (or manual projection math) to position screen elements
-- 4. Alpha/scale interpolation based on distance for smooth transitions

-- Key consideration: WoW doesn't allow true 3D model placement by addons.
-- We use screen-space projection of world coordinates onto UIParent.
-- The "beam" is actually a tall, narrow texture frame positioned at the
-- screen projection of the waypoint's world coordinates, with height
-- scaled by distance and perspective.

-- Alternative: Use the Pin system via HereBeDragons-Pins for world map,
-- and a screen-space projected frame for the in-world beam effect.
```

**Contextual Colors:**

| Source | Color | Hex |
|--------|-------|-----|
| Quest Objective | Warm Gold | #FFD700 |
| User Waypoint (/way) | Cyan Blue | #00BFFF |
| TomTom Import | Orange | #FF8C00 |
| Corpse Run | Red | #FF4444 |
| Flight Path | Green | #44FF88 |
| Dungeon/Raid Entrance | Purple | #AA66FF |
| Travel Planner Route | White/Silver | #E0E0E0 |

### 4.2 ELEVATION MODULE (The Game Changer)

This is what separates DestinationXD from every other waypoint addon.

**ElevationTracker.lua:**

```lua
-- Core elevation tracking logic:
-- 1. Get player Z via UnitPosition("player") → returns (posY, posX, posZ, instanceID)
-- 2. Get or estimate destination Z:
--    a. For /way commands with Z: use directly
--    b. For quest objectives: use C_Navigation distance + 2D distance to triangulate
--    c. For known multi-floor areas: use FloorData lookup
--    d. Fallback: estimate from map floor system
-- 3. Compute: elevationDelta = destZ - playerZ
-- 4. Classify: ABOVE (delta > 8), BELOW (delta < -8), LEVEL (|delta| <= 8)
-- 5. Compute decomposed distance:
--    horizontalDist = sqrt(dx^2 + dy^2)  -- 2D distance on map plane
--    verticalDist = abs(elevationDelta)
--    totalDist = sqrt(horizontalDist^2 + verticalDist^2)  -- true 3D distance

-- Z estimation when destination Z is unknown:
-- If we know 2D map distance (d2D) and C_Navigation.GetDistance() gives us
-- the true 3D distance (d3D), then:
-- verticalDist = sqrt(d3D^2 - d2D^2)  -- if d3D > d2D
-- This gives us the MAGNITUDE of elevation difference, though not the sign.
-- For the sign, we use floor detection data or track Z changes as player moves.
```

**ElevationHUD.lua:**

A compact, always-visible HUD element anchored to screen (not world-space). Shows:

```
┌─────────────────────┐
│   ▲ 34y above       │  ← Orange arrow + text when destination is above
│   → 52y  ▲ 34y     │  ← Decomposed: 52 yards horizontal, 34 yards up
└─────────────────────┘

┌─────────────────────┐
│   ▼ 18y below       │  ← Blue arrow + text when destination is below
│   → 12y  ▼ 18y     │  ← Decomposed: 12 yards horizontal, 18 yards down
└─────────────────────┘

┌─────────────────────┐
│   ═ Same Level      │  ← Green when within vertical tolerance
│   → 47y             │  ← Just horizontal distance
└─────────────────────┘
```

**Color Coding:**

- **Above you:** Orange (#FF8C00) with ▲ chevron
- **Below you:** Deep Blue (#4488FF) with ▼ chevron
- **Same level:** Green (#44FF88) with ═ indicator
- Smooth color interpolation as you transition between states

**FloorDetection.lua:**

Maintains a database of known multi-floor areas with Z-range boundaries:

```lua
-- Example floor data structure:
FloorData = {
    -- Midnight Quel'Thalas areas
    [mapID_SilvermoonCity] = {
        { name = "Ground Level", zMin = 0, zMax = 25 },
        { name = "Upper Walkways", zMin = 25, zMax = 50 },
        { name = "Spire Level", zMin = 50, zMax = 100 },
    },
    -- Underground areas, caves
    [mapID_SomeZone] = {
        { name = "Surface", zMin = 0, zMax = 999 },
        { name = "Cave System", zMin = -50, zMax = 0 },
    },
}
```

### 4.3 NAVIGATOR MODULE (The Directional Arrow)

An improved directional arrow that includes vertical pitch.

**DirectionArrow.lua:**

- Smooth-rotating arrow that points toward destination
- **Pitch component:** Arrow tilts upward when destination is above, downward when below
- Pitch angle capped at ±45° for readability
- Arrow scales up slightly when destination is directly behind you (don't-miss-it indicator)
- Small distance text below the arrow
- Arrow color matches the Beacon's contextual color

**DistanceDisplay.lua:**

Shows distance in a clean, decomposed format:

```
47y                 ← Total 3D distance (when same level)
→ 38y  ▲ 27y       ← Horizontal + Vertical (when elevation differs)
```

- Font: Clean sans-serif, white with subtle shadow
- Numbers update at 10fps (throttled for performance)
- ETA display option: "~12 sec" based on current movement speed

**ProximityManager.lua — Smart Arrival Detection:**

```lua
-- Standard addons: arrived = (2D_distance < threshold)
-- DestinationXD: arrived = (2D_distance < threshold) AND (|Z_delta| < Z_threshold)
--
-- This prevents false arrivals when standing directly above/below destination.
-- Z_threshold defaults to 10 yards (tuned for most cave/building scenarios).
--
-- Arrival behavior:
-- 1. At 10 yards: Beacon pulses faster, sound cue plays
-- 2. At 5 yards (3D): "Arrived!" flash, beacon fades with a satisfying dissolve
-- 3. Waypoint auto-clears (configurable: auto-clear vs. manual dismiss)
```

### 4.4 OBSTRUCTION DETECTION

When you're close on the map but can't reach the destination (cliff, wall, cave entrance needed):

```lua
-- Heuristic obstruction detection:
-- Track player movement vector and distance-to-target over time.
-- If player is moving TOWARD the 2D target (bearing within ±30°)
-- but the 3D distance is NOT decreasing (or increasing) for > 5 seconds,
-- the path is likely obstructed.
--
-- When obstruction detected:
-- 1. Show a wall/barrier icon on the HUD
-- 2. Text: "Look for an entrance nearby"
-- 3. If elevation delta is significant, suggest: "Try going UP/DOWN"
--
-- This is an approximation — we can't do true line-of-sight checks via API.
-- But it catches 80%+ of the "running into a cliff" scenarios.

local ObstructionDetector = {
    sampleInterval = 0.5,       -- Check every 0.5 seconds
    sampleWindow = 5.0,         -- Look at last 5 seconds of movement
    bearingThreshold = 30,      -- Moving within 30° of target bearing
    distanceStallThreshold = 2, -- Distance must decrease by at least 2 yards
    samples = {},               -- Ring buffer of {time, distance, bearing} tuples
}
```

### 4.5 TRAVEL PLANNER MODULE (The Route Brain)

This is the "killer feature" that no other addon has done well. A smart route planner that considers portals, hearthstones, flight paths, and tells you the optimal way to get anywhere.

**Architecture:**

```lua
-- The Travel Planner builds a weighted graph of the WoW world where:
-- Nodes = Locations (zones, cities, portal endpoints, flight masters)
-- Edges = Travel methods with time costs:
--   - Walking/Flying: distance / movement_speed
--   - Flight Path: known flight time from taxi data
--   - Portal: near-instant (cost = time to reach portal + 2 sec cast)
--   - Hearthstone: 0 travel time + cooldown consideration
--   - Mage Portal: if in group with mage (future feature)
--
-- Dijkstra's algorithm finds the shortest-time path.

TravelMethods = {
    WALK_FLY = 1,       -- Dragonriding/Skyriding speed
    FLIGHT_PATH = 2,    -- Taxi
    PORTAL = 3,         -- Standing portal (Orgrimmar, Stormwind hubs, etc.)
    HEARTHSTONE = 4,    -- Hearthstone (considers current bind location + cooldown)
    DUNGEON_TELEPORT = 5, -- "Teleport to Dungeon" for queued content
    BOAT_ZEPPELIN = 6,  -- Transport routes
}
```

**PortalDatabase.lua — Known Portal/Teleport Network:**

This is the critical data file. It must contain every known portal, where it goes, which faction can use it, and its exact coordinates.

```lua
-- Structure:
PortalDB = {
    -- Format: { sourceMapID, sourceX, sourceY, destMapID, destX, destY, faction, name }
    -- faction: "Alliance", "Horde", "Both"

    -- === ORGRIMMAR PORTAL ROOM ===
    { src = {mapID=85, x=0.46, y=0.38}, dst = {mapID=525, z="Frostwall"}, faction="Horde", name="Ashran" },
    -- ... hundreds of entries covering:
    -- Major city portal rooms (Orgrimmar, Stormwind, Dalaran)
    -- Expansion hub portals (Oribos, Valdrakken, Dornogal, Midnight hubs)
    -- Midnight-specific: Quel'Thalas portals, Silvermoon connections
    -- Seasonal/event portals (Darkmoon Faire, etc.)
    -- Mage tower portals, dungeon entrances with teleport options
}
```

**ZoneBrowser UI (TravelPlannerFrame.lua):**

A clean, hierarchical zone picker accessible from the minimap button:

```
┌─────────────────────────────────────────────┐
│  DestinationXD — Where do you want to go?   │
├─────────────────────────────────────────────┤
│                                             │
│  ▸ Eastern Kingdoms                         │
│  ▸ Kalimdor                                 │
│  ▾ Quel'Thalas (Midnight)                   │
│    ├── Silvermoon City                       │
│    ├── Eversong Woods                        │
│    ├── Ghostlands                            │
│    ├── The Sunwell                           │
│    └── [Midnight Zone 1, 2, 3...]            │
│  ▸ Northrend                                │
│  ▸ Pandaria                                 │
│  ▸ Broken Isles                             │
│  ▸ Zandalar / Kul Tiras                     │
│  ▸ Shadowlands                              │
│  ▸ Dragon Isles                             │
│  ▸ Khaz Algar                               │
│  ▸ Dungeons & Raids                         │
│                                             │
│  ┌─── ROUTE (Dalaran → Silvermoon City) ──┐ │
│  │ 1. Use Dalaran Portal to Orgrimmar      │ │
│  │ 2. Take Orgrimmar Portal to Silvermoon  │ │
│  │ 3. Estimated: ~45 seconds               │ │
│  │                                         │ │
│  │ [START NAVIGATION]                      │ │
│  └─────────────────────────────────────────┘ │
└─────────────────────────────────────────────┘
```

When user clicks "START NAVIGATION":
1. First waypoint is set to the nearest portal/transport
2. On arrival, auto-advances to next step
3. Continues until final destination reached
4. Real-time ETA updates throughout

### 4.6 TRACKER MODULE (Integration Layer)

Hooks into WoW's tracking systems to automatically display beacons for:

- **Super-tracked quests:** Listens to `SUPER_TRACKING_CHANGED`
- **User waypoints:** `/way` commands and map pin clicks
- **Quest POI clicks:** When user clicks a quest objective on the map
- **TomTom compatibility:** Reads TomTom waypoints if TomTom is installed
- **HandyNotes compatibility:** Can track HandyNotes pins

```lua
-- Priority system (highest wins):
-- 1. Travel Planner route step (if active)
-- 2. User /way waypoint
-- 3. Super-tracked quest objective
-- 4. TomTom imported waypoint
-- 5. Corpse location (when dead)
```

### 4.7 PINPOINT MODULE (In-World Info Display)

Floating text near the waypoint showing contextual information:

- Quest name + objective text for quest waypoints
- Coordinate text for /way waypoints
- Distance + ETA
- Route step info for Travel Planner

Clean, readable font with subtle background panel. Scales with distance (larger when far, smaller when close to avoid clutter).

---

## 5. PERFORMANCE REQUIREMENTS

This addon must be **buttery smooth**. WoW players notice frame drops.

```lua
-- Performance budget per frame:
-- Target: < 0.5ms per OnUpdate cycle
-- Update frequencies (staggered, not all on same frame):
--   Position polling:     20 fps (every 0.05s)
--   Beacon position:      20 fps
--   Elevation calc:       10 fps (every 0.1s)
--   Distance display:     10 fps
--   Arrow rotation:       20 fps
--   Obstruction check:    2 fps (every 0.5s)
--   Travel Planner route: On-demand only (not per-frame)

-- Techniques:
-- 1. Object pooling for all frames/textures
-- 2. Throttled updates with staggered timers
-- 3. Early-out checks (don't process beacon if not visible)
-- 4. Cache expensive calculations (map conversions, floor lookups)
-- 5. Use C_Timer.After() for deferred non-critical work
-- 6. Minimize garbage generation (reuse tables, avoid string concat in loops)
-- 7. Profile with /script UpdateAddOnMemoryUsage(); print(GetAddOnMemoryUsage("DestinationXD"))
```

---

## 6. USER EXPERIENCE REQUIREMENTS

### Works Out of the Box

- **ZERO configuration required.** Install it, all features active immediately.
- Sensible defaults for every setting.
- No tutorial popup, no wizard. Just works.
- `/dxd` opens settings if user wants to customize (but they shouldn't need to).

### Slash Commands

```
/dxd                    -- Opens settings panel
/dxd travel             -- Opens Travel Planner
/dxd reset              -- Reset all settings to defaults
/way [mapName] x y      -- Standard waypoint command (compatible with TomTom format)
/way x y                -- Waypoint in current zone
/dxd clear              -- Clear current waypoint
/dxd test               -- Debug: spawn a test waypoint 50 yards away
```

### Minimap Button

- Clean, recognizable icon (compass rose or destination pin design)
- Left-click: Toggle Travel Planner
- Right-click: Quick options menu (clear waypoint, toggle elevation HUD, etc.)
- Tooltip shows current destination + distance

### Settings Panel (for power users)

Accessible via `/dxd` or Interface → AddOns → DestinationXD:

```
General:
  ☑ Enable DestinationXD
  ☑ Play sounds on arrival
  ☑ Auto-clear waypoint on arrival
  Arrival distance: [5] yards

Beacon:
  Beam style: [Modern Glow ▾]  (Modern Glow / Classic Pillar / Minimal Dot)
  Beam opacity: [████████░░] 80%
  ☑ Show beam through terrain (occluded)

Elevation:
  ☑ Show elevation indicator
  ☑ Show decomposed distance
  Vertical tolerance: [8] yards

Navigator:
  ☑ Show direction arrow
  ☑ Show ETA
  Arrow size: [████████░░] Medium

Travel Planner:
  ☑ Consider hearthstone cooldown
  Hearthstone location: [Auto-detect]
  Preferred flight style: [Shortest time ▾]

Integrations:
  ☑ TomTom compatibility
  ☑ HandyNotes compatibility
```

---

## 7. VISUAL DESIGN LANGUAGE — "LESS IS EVERYTHING"

### Design Philosophy: Radical Minimalism

DestinationXD's aesthetic is **radically minimal**. Every pixel must earn its place on screen. If an element doesn't directly help the player navigate, it doesn't exist. The addon should feel like it was designed by someone who removes things for a living — like the navigation HUD in a premium sci-fi film, not a busy game UI.

The guiding principle: **The game world is the star. We are invisible until you need us, and beautiful when you see us.**

Think of it this way — if WaypointUI is a neon sign, DestinationXD is a laser. Precise, clean, unmistakable, but never loud.

### The 10 Commandments of DestinationXD Aesthetics

```
1. NO BORDERS. No chunky WoW-style borders. No panel edges. Elements float.
2. NO BACKGROUNDS (almost). If a background is needed, it's a barely-there
   dark gradient at 15-25% opacity. Never solid. Never a "box."
3. BREATHING ROOM. Generous spacing between every element. Nothing touches
   anything else. White space (or rather, transparent space) IS the design.
4. ONE FONT. FRIZQT__ (WoW's native font) everywhere. No mixing. Consistency
   over variety. Let size and opacity create hierarchy, not font changes.
5. OPACITY IS YOUR BEST FRIEND. Information hierarchy is controlled almost
   entirely through opacity: primary info at 90-100%, secondary at 50-60%,
   tertiary at 30-40%. This creates depth without adding visual weight.
6. COLOR IS SCARCE AND MEANINGFUL. The addon is mostly white/silver text on
   transparency. Color ONLY appears for: elevation state (orange/blue/green),
   waypoint type (the beacon), and arrival feedback. When color appears, it
   means something. It's never decorative.
7. ANIMATIONS ARE SLOW AND SMOOTH. No snapping. No bouncing. No "spring"
   physics. Everything eases with long curves — 0.3s minimum for transitions.
   Elements fade in, drift into position, breathe slowly. Urgency is conveyed
   by speeding up an existing slow animation, never by adding new motion.
8. TEXT IS SCARCE. If you can say it with an icon or a color change, don't use
   text. If you must use text, use the fewest possible characters.
   "47y" not "47 yards away". "▲ 34" not "34 yards above you".
9. THE BEACON IS THE ONLY "LOUD" ELEMENT. The in-world beam is where all the
   visual drama lives. Everything else — the HUD, the arrow, the distance —
   is a whisper. This contrast makes the beacon feel magical and makes the
   HUD feel sophisticated.
10. NOTHING BLINKS. Nothing flashes aggressively. Arrival is a gentle bloom
    of light, not a strobe. Urgency is a faster pulse, not a color explosion.
```

### Color Palette — "Moonlight"

The palette is inspired by moonlight and starlight — cool, ethereal, minimal. Warm tones only appear for elevation and waypoint context.

```lua
-- PRIMARY PALETTE (used for all HUD/UI elements)
COLORS = {
    -- Text & UI Chrome
    TEXT_PRIMARY     = { r=0.92, g=0.92, b=0.95, a=0.90 },  -- Near-white, cool tint
    TEXT_SECONDARY   = { r=0.75, g=0.75, b=0.80, a=0.55 },  -- Muted silver
    TEXT_TERTIARY    = { r=0.60, g=0.60, b=0.65, a=0.35 },  -- Ghost text
    PANEL_BG         = { r=0.05, g=0.05, b=0.08, a=0.20 },  -- Barely visible dark
    PANEL_BG_HOVER   = { r=0.10, g=0.10, b=0.15, a=0.30 },  -- Subtle hover state
    DIVIDER          = { r=0.40, g=0.40, b=0.45, a=0.15 },  -- Hairline dividers

    -- Elevation States (the ONLY bold colors in the HUD)
    ELEV_ABOVE       = { r=1.00, g=0.60, b=0.20, a=0.90 },  -- Warm amber
    ELEV_BELOW       = { r=0.30, g=0.60, b=1.00, a=0.90 },  -- Cool blue
    ELEV_LEVEL       = { r=0.30, g=0.90, b=0.50, a=0.80 },  -- Soft green

    -- Beacon Contextual Colors (only affects the beam itself)
    BEACON_QUEST     = { r=1.00, g=0.84, b=0.00, a=0.85 },  -- Gold
    BEACON_WAYPOINT  = { r=0.40, g=0.85, b=1.00, a=0.85 },  -- Cyan
    BEACON_CORPSE    = { r=0.90, g=0.25, b=0.25, a=0.70 },  -- Muted red
    BEACON_TRAVEL    = { r=0.88, g=0.88, b=0.92, a=0.80 },  -- Silver-white
    BEACON_DUNGEON   = { r=0.70, g=0.45, b=1.00, a=0.80 },  -- Soft purple

    -- Feedback
    ARRIVE_BLOOM     = { r=1.00, g=1.00, b=1.00, a=0.60 },  -- White bloom on arrival
}
```

### Typography — One Font, Pure Hierarchy

```lua
-- ALL text uses FRIZQT__ (WoW's built-in). No custom fonts.
-- Hierarchy is created ONLY through size and opacity. Never bold vs regular
-- (WoW doesn't reliably support font weights). Never different fonts.

FONT_SIZES = {
    -- Distance readout (the most important number on screen)
    DISTANCE_PRIMARY  = 18,  -- "47y" — large, confident, unmistakable

    -- Elevation delta
    ELEVATION_VALUE   = 14,  -- "▲ 34" — clear but secondary to distance

    -- Labels and ETA
    LABEL             = 10,  -- "quest" / "~12s" — whisper-quiet

    -- Travel Planner
    ZONE_NAME         = 13,  -- Zone names in the browser
    ROUTE_STEP        = 11,  -- Route instructions
    HEADER            = 15,  -- Panel titles (still modest)
}

-- CRITICAL: No text shadows heavier than (0, 0, 0, 0.5) at 1px offset.
-- Heavy shadows make text look chunky. Light shadow just ensures readability.
FONT_SHADOW = { x = 1, y = -1, color = { r=0, g=0, b=0, a=0.5 } }
```

### Element-by-Element Visual Specs

**THE BEACON (In-World Beam):**
```
Far (100+ yards):
  - Thin vertical line of light (NOT a thick pillar — think laser, not lighthouse)
  - Width: 2-4px on screen (scales with distance naturally)
  - Height: extends from ground to ~40% of screen height
  - Soft gaussian glow around the line (8-12px blur radius feel via layered textures)
  - Base: tiny circular glow on the ground, no ring, no circle marker
  - Gentle sine-wave opacity pulse: 70% → 90% → 70% over 3 seconds
  - Color: waypoint type color (see palette)

Medium (30-100 yards):
  - Same thin line, height reduces proportionally
  - Glow intensifies slightly as you approach
  - Elevation chevrons appear ON the beam line (tiny ▲ or ▼ symbols
    spaced along the shaft, drifting upward or downward slowly)

Close (<30 yards):
  - Beam dissolves into a single floating point of light (like a firefly)
  - The point gently bobs up/down by 2-3px (breathing motion)
  - If significant elevation delta: the point stretches into a
    vertical arrow shape pointing up or down
  - Ground marker: single soft dot of light, no ring, no circle border

Arrival (<5 yards, same level):
  - Point blooms outward (scale 1x → 2x over 0.4s)
  - Opacity fades to 0 over 0.6s
  - Subtle white flash (0.2s, 40% opacity max)
  - Gone. Clean. No lingering particles.
```

**THE ELEVATION HUD:**
```
Position: Screen center-right, vertically centered (above minimap area)
         Offset enough to never overlap character model.

Layout (when elevation differs):
  ┌──────────────┐
  │  ▲ 34        │   ← Elevation icon + vertical yards
  │  → 52        │   ← Horizontal yards (smaller, lower opacity)
  └──────────────┘
  (no actual border — these are just floating text lines)

Layout (when same level):
  ┌──────────────┐
  │  → 47        │   ← Just horizontal distance
  └──────────────┘

- The ▲/▼/→ symbols are texture icons, not font characters (crisper rendering)
- Icon size: 12x12px, tinted with elevation color
- Number font: FRIZQT__ at DISTANCE_PRIMARY size
- The elevation line fades in/out over 0.3s when state changes
- The horizontal line is always visible when tracking (at TEXT_SECONDARY opacity)
- NO background panel. Just floating text with a gentle shadow.
- The entire element fades to 15% opacity when player is not moving
  (gets out of the way during combat/standing around) and fades back to
  full opacity within 0.2s of movement resuming.
```

**THE DIRECTION ARROW:**
```
Position: Top-center of screen, below the minimap (configurable)

Design:
  - A single thin chevron shape: ∧ (not a chunky arrow)
  - Stroke weight: 2px equivalent
  - Fill: TEXT_PRIMARY color at 70% opacity
  - Size: 28x28px (small and precise)
  - Rotation: smooth interpolation toward bearing (lerp factor 0.12)
  - Pitch tilt: the chevron tilts on its X-axis up to ±30° based on
    elevation delta. Subtle but perceptible.
  - When destination is directly behind: chevron flips to ∨ and opacity
    bumps to 90% briefly (0.5s) then settles back to 70%
  - NO circle behind it. NO compass rose. Just the chevron, floating.
```

**THE TRAVEL PLANNER WINDOW:**
```
Design Language: "Frosted glass, barely there"

Background: 
  - Single rectangle, NO border, NO title bar chrome
  - Fill: (0.03, 0.03, 0.06, 0.75) — very dark, slightly blue, 75% opacity
  - Edges: 1px inset line at 8% white opacity (just enough to define the edge)
  - NO rounded corners (WoW textures don't do this well — sharp is cleaner)

Title:
  - "DESTINATION" in FRIZQT__ at 15pt, TEXT_SECONDARY color, letter-spaced +2px
  - Sits 12px from top-left with generous padding. No underline. No separator.

Zone List:
  - Each zone name is plain text at ZONE_NAME size
  - Unselected: TEXT_SECONDARY opacity
  - Hovered: TEXT_PRIMARY opacity (smooth 0.15s fade)
  - Selected: TEXT_PRIMARY opacity + tiny 2px dot to the left (elevation color)
  - Continent headers: same size but TEXT_TERTIARY opacity, uppercase
  - Expand/collapse: no icon. Just indent children 16px. Parent zones show
    child count in parentheses at TERTIARY opacity: "Quel'Thalas (6)"
  - Scrolling: no scrollbar track. Just a 2px-wide indicator line on the
    right edge that appears only while scrolling and fades after 1s.

Route Display:
  - Steps are numbered with circled numbers (①②③) at TEXT_SECONDARY
  - Step text at ROUTE_STEP size, TEXT_PRIMARY
  - Method icons (portal, flight, walk) are 10x10px, monochrome white
  - Total time estimate at bottom: "~2 min" at LABEL size, TEXT_TERTIARY
  - "GO" button: just the word "GO" in TEXT_PRIMARY at 15pt.
    No button background. No border. On hover: opacity 100% + 
    underline fades in (1px, TEXT_PRIMARY at 30%). On click: text
    briefly scales to 105% and back (0.2s). That's it.

Close button: 
  - Just an "×" character at top-right, TEXT_TERTIARY
  - Hover: TEXT_PRIMARY. That's the entire close button.
```

**THE MINIMAP BUTTON:**
```
- Clean circular icon, 24x24px
- Design: a simple compass needle / destination pin silhouette
- Color: monochrome white on transparent
- No border ring (breaks from LibDBIcon convention, but looks cleaner)
- Tooltip: minimal — just "DestinationXD" on line 1, 
  "Left-click: Travel Planner" at TERTIARY on line 2
- When actively navigating: a tiny colored dot (3px) appears at the
  bottom-right of the icon, tinted with the beacon's current color.
  This is the ONLY indication that navigation is active. Subtle.
```

**THE PINPOINT (In-World Quest Text):**
```
- Quest name at 11pt, TEXT_PRIMARY
- Objective text at 9pt, TEXT_SECONDARY
- NO background panel. NO border. Just text with shadow, floating in world.
- Max width: 200px (wraps naturally)
- Fades based on distance: 100% at 20-50 yards, fades to 0% beyond 80 yards
- Fades to 30% when player camera isn't facing it (dot product check)
- Position: slightly above the beacon point, offset upward by 20px
```

### Animation Timing — Slow and Smooth

```lua
-- Everything is slow. Slow = premium. Fast = cheap.
-- The only thing that speeds up is the beacon pulse on approach.

ANIMATION = {
    -- Easing function: smooth cubic ease-in-out for everything
    -- f(t) = t < 0.5 ? 4*t*t*t : 1 - (-2*t+2)^3/2

    BEACON_PULSE_PERIOD   = 3.0,    -- Full breath cycle (slow, meditative)
    BEACON_PULSE_CLOSE    = 1.5,    -- Faster pulse when <30 yards
    BEACON_FADE_IN        = 0.4,    -- Appear
    BEACON_FADE_OUT       = 0.8,    -- Dissolve on arrival (slow, satisfying)
    BEACON_ARRIVE_BLOOM   = 0.5,    -- Scale bloom on arrival

    ARROW_LERP_FACTOR     = 0.12,   -- Per-frame rotation smoothing (lower = smoother)
    ARROW_PITCH_LERP      = 0.08,   -- Pitch changes even slower than rotation

    ELEVATION_FADE        = 0.3,    -- State change color/icon transition
    ELEVATION_IDLE_FADE   = 1.5,    -- Fade to idle opacity when not moving

    HUD_FADE_IN           = 0.25,   -- Element appearance
    HUD_FADE_OUT          = 0.4,    -- Element disappearance (slower than appear)

    TRAVEL_PANEL_OPEN     = 0.3,    -- Panel fade in (with slight scale 0.97 → 1.0)
    TRAVEL_PANEL_CLOSE    = 0.2,    -- Panel fade out
    TRAVEL_HOVER          = 0.15,   -- Hover state transitions

    -- CRITICAL: Never use WoW's :SetScript("OnUpdate") with linear interpolation.
    -- Always use: current = current + (target - current) * factor
    -- This creates natural deceleration as values approach their target.
}
```

### What We NEVER Do

```
❌ Blizzard-style gold/brown borders
❌ Parchment or leather textures
❌ Drop shadows heavier than 1px at 50% black
❌ Gradients with more than 2 stops
❌ Any texture that looks like it came from the WoW default UI
❌ Scrollbar tracks or thumb elements (use invisible scroll zones)
❌ Button backgrounds (text IS the button, hover state IS the affordance)
❌ Tooltip-style panels with pointed tails
❌ Multiple font faces in the same view
❌ Bold/italic text (WoW font rendering makes these look bad)
❌ Animations faster than 0.15s (looks janky at WoW's frame rates)
❌ Pulsing or blinking UI elements (the beacon pulses; nothing else does)
❌ Color gradients on text
❌ More than 3 colors visible in the HUD at any given moment
❌ Any element wider than 250px (keep everything compact)
```

### What We ALWAYS Do

```
✅ Opacity for hierarchy (90% / 55% / 35% — three tiers only)
✅ Generous padding (minimum 8px between any two elements)
✅ Cubic easing on all transitions
✅ Monochrome HUD with color reserved for meaning
✅ Elements that fade away when not needed (idle detection)
✅ Text shadows at exactly 1px offset, 50% black opacity
✅ Icons and text at the same visual weight (thin, precise)
✅ Screen-anchored HUD elements (never wobble with camera)
✅ Consistent 4px grid alignment for all element positioning
✅ The beacon as the SOLE source of visual drama in the addon
```

### Design Reference Mood

If you need a mental image for the aesthetic, think:

- **Dead Space** (2008) — the holographic HUD projected on Isaac's suit. Minimal, diegetic, information-dense but visually quiet.
- **Warframe** — clean geometric UI with transparency and subtle glow.
- **Destiny 2 Ghost overlay** — floating text and icons with no borders, just light.
- **Elite: Dangerous cockpit HUD** — monochrome with color used only for state changes.

NOT: WoW's default UI. NOT: ElvUI (too many borders and panels). NOT: any addon that looks like a website toolbar bolted onto the game.

---

## 8. DATA FILES TO BUILD

### PortalData.lua (Critical — Most Research-Intensive)

This needs to be comprehensive. Every portal, teleport, and transport in the game:

**Categories to cover:**

1. **Major City Portal Rooms:** Orgrimmar, Stormwind, Dalaran (all versions), Valdrakken, Dornogal
2. **Midnight-Specific:** All new Quel'Thalas/Silvermoon portals and connections added in 12.0
3. **Expansion Hub Portals:** Oribos → Shadowlands zones, Valdrakken → Dragon Isles, etc.
4. **Boats & Zeppelins:** All transport routes with approximate travel times
5. **Dark Portal:** Both directions
6. **Mage Portals:** (for future: detect party member mage portals)
7. **Engineering Wormholes:** (optional)
8. **Dungeon Teleports:** Hero's Call Board / Dungeon Finder teleports

### ZoneData.lua

Complete zone hierarchy for the Travel Planner browser:

```lua
ZoneHierarchy = {
    ["Eastern Kingdoms"] = {
        continent = true,
        children = {
            ["Silvermoon City"] = { mapID = 110, faction = "Horde", level = "1-30" },
            ["Eversong Woods"] = { mapID = 94, faction = "Horde", level = "1-30" },
            -- ... all zones
        }
    },
    ["Quel'Thalas"] = {  -- Midnight expansion content
        continent = true,
        children = {
            -- All new Midnight zones with correct mapIDs
        }
    },
    -- ... all continents
}
```

### FloorData.lua

Known multi-level areas where Z matters most. Start with Midnight zones (since that's the active content) and major cities, then expand.

---

## 9. TESTING PLAN

### Unit Testing (In-Game)

```
/dxd test beacon       -- Spawn test beacon at various distances
/dxd test elevation    -- Simulate elevation scenarios (above/below/level)
/dxd test obstruction  -- Test obstruction detection heuristic
/dxd test travel       -- Run travel planner pathfinding tests
/dxd test performance  -- 60-second performance benchmark with memory/CPU tracking
```

### Scenario Testing

1. **Open field waypoint:** Set /way across Eversong Woods. Beam visible? Arrow correct? Arrival triggers?
2. **Cave/underground:** Set waypoint inside a cave. Does elevation indicator show "below"? Does it say "look for entrance" when above the cave?
3. **Multi-floor building:** Waypoint on different floor of Silvermoon. Floor detection working?
4. **Behind cliff:** Waypoint on other side of terrain. Obstruction detection activating?
5. **Cross-continent travel:** Open Travel Planner, pick a distant zone. Route makes sense? Steps are correct?
6. **Corpse run:** Die, verify corpse waypoint appears with correct elevation data.
7. **TomTom compat:** Install TomTom, set a TomTom waypoint, verify DestinationXD picks it up.
8. **Quest tracking:** Accept quest, track it, verify beacon appears at quest objective.
9. **Performance:** Run through busy Silvermoon City with beacon active. FPS stable? Memory stable?

---

## 10. DEVELOPMENT PHASES

### Phase 1: Core Foundation (MVP)
- [ ] Project scaffold, TOC, Init, SavedVariables
- [ ] Basic Beacon (in-world beam at tracked waypoint)
- [ ] Basic Navigator arrow (2D, no pitch yet)
- [ ] Distance display
- [ ] /way command support
- [ ] Quest supertracking integration
- [ ] Minimap button (basic)

### Phase 2: Elevation System
- [ ] UnitPosition Z tracking
- [ ] Elevation delta calculation + Z estimation
- [ ] Elevation HUD (above/below/level indicator)
- [ ] Decomposed distance display
- [ ] Z-aware arrival detection
- [ ] Arrow pitch component

### Phase 3: Visual Polish
- [ ] Beacon animations (pulse, proximity morph, fade)
- [ ] Contextual coloring system
- [ ] Smooth transitions and easing
- [ ] Occluded beacon rendering (through terrain)
- [ ] Sound effects
- [ ] Pinpoint module (floating quest text)

### Phase 4: Travel Planner
- [ ] Portal database (research + populate)
- [ ] Zone hierarchy data
- [ ] Graph pathfinding (Dijkstra)
- [ ] Travel Planner UI window
- [ ] Multi-step route navigation
- [ ] Hearthstone cooldown awareness

### Phase 5: Polish & Integration
- [ ] Obstruction detection heuristic
- [ ] Floor detection for known areas
- [ ] TomTom compatibility bridge
- [ ] HandyNotes compatibility
- [ ] Settings panel
- [ ] Performance optimization pass
- [ ] Midnight-specific zone data completion

### Phase 6: Release
- [ ] Full testing pass
- [ ] CurseForge packaging
- [ ] Screenshots + description
- [ ] GitHub repo cleanup

---

## 11. CLAUDE CODE DEVELOPMENT PROMPT

Copy the entire block below and use it as your initial prompt when starting Claude Code on this project:

---

```
You are building a World of Warcraft addon called "DestinationXD" for the Midnight expansion (Patch 12.0, TOC: 120000). This is a premium in-world navigation addon that provides:

1. A stunning beacon (beam of light) projected at waypoint destinations in world-space
2. 3D elevation awareness — showing if destinations are ABOVE, BELOW, or at the SAME LEVEL
3. Decomposed distance display (horizontal + vertical yards)
4. A pitch-aware directional arrow
5. Obstruction detection (warns when terrain blocks your path)
6. A Smart Travel Planner that calculates optimal routes using portals, hearthstones, and flight paths
7. A minimap-button-accessible zone browser for navigating anywhere in the game world

CRITICAL TECHNICAL CONSTRAINTS:
- WoW addons are written in Lua 5.1
- The addon API is event-driven with frame-based OnUpdate for real-time updates
- WoW 12.0 "Midnight" restricted COMBAT addon APIs but navigation APIs are fully intact
- UnitPosition("player") returns (posY, posX, posZ, instanceID) — this gives us the Z coordinate for elevation tracking
- C_Navigation.GetDistance() returns distance in yards to the supertracked waypoint
- C_SuperTrack API handles quest and waypoint tracking
- C_Map API handles all map coordinate systems
- HereBeDragons library should be embedded for robust coordinate math
- Screen-space projection is needed to render world-positioned UI elements (beams, markers)
- Performance target: < 0.5ms per OnUpdate cycle, throttled updates, object pooling
- Must work out-of-the-box with zero configuration

IMPORTANT MIDNIGHT (12.0) NOTES:
- TOC Interface version: 120000
- "Secret values" only affect combat data — navigation APIs unaffected
- Some deprecated APIs removed (see Patch_12.0.0/API_changes on warcraft.wiki.gg)
- New zones: Quel'Thalas content, revamped Silvermoon City, Midnight-specific areas
- Skyriding (dragonriding) is the default flight mode — factor this into travel time estimates

ADDON FILE STRUCTURE:
[Refer to Section 3 of the plan document for complete file tree]

DEVELOPMENT APPROACH:
- Start with Phase 1 (Core Foundation) and work through each phase sequentially
- Each module should be self-contained with clear APIs
- Use a namespace pattern: DestinationXD = LibStub("AceAddon-3.0"):NewAddon(...) OR a simple global table
- Prefer the simpler approach: global DestinationXD table with module sub-tables, no heavy framework dependency
- All settings via SavedVariables with sensible defaults
- Embed HereBeDragons, LibStub, CallbackHandler, LibDBIcon as libraries

VISUAL REQUIREMENTS — RADICAL MINIMALISM:
This addon must be BEAUTIFUL in its restraint. Think Dead Space HUD, not WoW default UI.
- NO Blizzard-style borders. NO parchment textures. NO button backgrounds.
- The HUD is almost invisible: white/silver text floating with subtle shadow, no panels
- Opacity creates hierarchy: 90% primary, 55% secondary, 35% tertiary. Three tiers ONLY.
- Color is ONLY used for meaning: orange=above, blue=below, green=level, plus beacon type color
- ONE font everywhere (FRIZQT__). Size and opacity create hierarchy, never font changes.
- All animations use cubic easing, minimum 0.15s duration. Slow = premium. Fast = cheap.
- The Beacon beam is THIN (like a laser, not a lighthouse). It's the only "loud" visual.
- Everything else whispers. The Travel Planner window is a dark transparent rectangle, no chrome.
- Buttons are just text. Hover = opacity change. That's it. No backgrounds, no borders.
- Elements fade to near-invisible when player is idle. They breathe, they don't shout.
- The game world is the star. The addon is invisible until needed, beautiful when seen.
- Reference mood: Dead Space holographic suit HUD, Warframe UI, Destiny 2 Ghost overlay.
- NEVER: chunky borders, parchment textures, bold shadows, blinking elements, busy layouts.

The author name for this addon is "Spacebutt" and the addon tagline is "You'll actually get there."

Begin by creating the project scaffold with the TOC file, Core/Init.lua, and a basic working beacon that appears at the supertracked waypoint location.
```

---

## 12. RESOURCES & REFERENCES

### API Documentation
- Warcraft Wiki API: https://warcraft.wiki.gg/wiki/World_of_Warcraft_API
- Patch 12.0.0 API Changes: https://warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes
- C_SuperTrack API: https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_SuperTrack
- C_Navigation API: https://warcraft.wiki.gg/wiki/API_C_Navigation.GetDistance
- UnitPosition API: https://warcraft.wiki.gg/wiki/API_UnitPosition
- C_Map API: https://wowpedia.fandom.com/wiki/Category:API_namespaces/C_Map

### Libraries
- HereBeDragons: https://www.curseforge.com/wow/addons/herebedragons
- LibDBIcon: https://www.curseforge.com/wow/addons/libdbicon-1-0
- LibStub: https://www.curseforge.com/wow/addons/libstub

### Inspiration / Competitive Analysis
- WaypointUI by AdaptiveX: https://www.curseforge.com/wow/addons/waypointui (the visual benchmark)
- TomTom: https://www.curseforge.com/wow/addons/tomtom (the compatibility standard)
- Map Pin Enhanced: https://www.curseforge.com/wow/addons/map-pin-enhanced (Midnight-updated pin system)

### Addon Development
- WoW Addon Development Guide: https://warcraft.wiki.gg/wiki/Creating_a_WoW_addon
- Lua 5.1 Reference: https://www.lua.org/manual/5.1/
- WoWUIDev Discord: Primary source for Midnight API discussions

---

## 13. QUICK START FOR CLAUDE CODE

After opening the repo in Claude Code:

1. **First command:** "Read the full DestinationXD-Plan.md file to understand the project"
2. **Second command:** "Create the complete project scaffold with all directories, the TOC file, and Core/Init.lua"
3. **Third command:** "Implement Phase 1 — the basic beacon, navigator arrow, distance display, /way support, and quest tracking integration"
4. Continue through phases as outlined above.

Keep each module self-contained. Test each phase before moving to the next. The plan document is your source of truth for architecture decisions.

**Let's build the best damn waypoint addon WoW has ever seen.** 🎯
