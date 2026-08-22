# FallingFurni

A Roblox party minigame inspired by musical chairs — players wait in a queue, get teleported into an arena, and race to sit down as chairs rain from the sky and the clock runs out. Last player standing (or last one seated) wins the round.

Built and synced with [Rojo](https://rojo.space/), so the project lives as plain-text Luau source under version control instead of inside a `.rbxl` binary.

## Gameplay Loop

1. **Queue** — Players stand in the `QueueArea` in the lobby. Once enough players are in the zone, the round manager starts a countdown.
2. **Round start** — Players are teleported to the arena spawn and a random/selected map is loaded.
3. **Falling chairs** — Chairs spawn high above the arena at staggered intervals and fall (physics-simulated, welded together) until there's one fewer chair than players.
4. **Elimination** — When the round timer expires, any player not sitting in a chair (`Humanoid.Sit == false`) is eliminated and teleported back to the lobby/spectator area.
5. **Repeat / Win** — The process repeats with fewer chairs each cycle until one player remains. The winner's `GamesWon` stat is incremented and persisted.

## Project Structure

```
src/
├── ReplicatedStorage/       # Shared modules/values replicated to clients
│   ├── Timer.luau           # Countdown timer module (writes to RoundTimer)
│   └── RoundTimer/          # RoundTimer value + init script
├── ServerScriptService/
│   ├── roundManager.server.luau   # Core game loop: queue → round → elimination → winner
│   ├── ChairSpawning.server.luau  # Legacy/alt chair-spawning + round-state logic
│   ├── ArenaWalls.server.luau     # Procedurally builds the arena boundary walls
│   ├── Lobby.server.luau          # Procedurally builds the lobby (platform, seating, signage, music)
│   ├── LobbyInit/                 # Lobby initialization script + decor models
│   ├── Leaderboard.server.luau    # Creates leaderstats (GamesWon) for each player
│   ├── DataStore.server.luau      # Persists player stats via Roblox DataStoreService
│   ├── MapService.luau            # Loads/cycles arena maps from ServerStorage.Maps
│   └── Timer.server.luau          # Server-side timer driver
├── ServerStorage/
│   ├── Chair.rbxm           # Chair model template cloned during rounds
│   ├── Maps/                # Arena map models (e.g. ClassicArena.rbxm)
│   └── Modules/             # QueueManager, QueueStationBuilder, LobbyBuilder
├── StarterGui/               # Client UI (round timer display, etc.)
├── StarterPlayer/            # StarterCharacterScripts / StarterPlayerScripts
└── Workspace/                 # Baseplate, spawns, queue area, camera, terrain
```

Other notable files:

- `default.project.json` — Rojo project manifest mapping `src/` folders to Roblox services (also sets place properties like streaming and camera zoom).
- `rokit.toml` — [Rokit](https://github.com/rojo-rbx/rokit) toolchain manifest, pins the Rojo CLI version.
- `backups/` — Local `.rbxl` place file backups (git-ignored).

## Requirements

- [Roblox Studio](https://www.roblox.com/create)
- [Rokit](https://github.com/rojo-rbx/rokit) (manages the pinned Rojo version) — or [Rojo](https://rojo.space/) installed manually
- The [Rojo Studio plugin](https://www.roblox.com/library/13916111004/Rojo) installed in Roblox Studio

## Getting Started

1. Clone the repository:
   ```bash
   git clone https://github.com/Jreejuggin/FallingFurni.git
   cd FallingFurni
   ```
2. Install the pinned toolchain with Rokit:
   ```bash
   rokit install
   ```
3. Start the Rojo server:
   ```bash
   rojo serve
   ```
4. In Roblox Studio, open the Rojo plugin and click **Connect** to sync `src/` into your place.

## Development Notes

- Server-authoritative round state is exposed to clients via a `StringValue` (`RoundState`) and an `IntValue` (`RoundTimer`) in `ReplicatedStorage`.
- Player stats (`GamesWon`) are tracked under `leaderstats` and persisted per-user with `DataStoreService`.
- Arena size, wall height, chair fall timing, and queue thresholds are tunable constants near the top of `roundManager.server.luau` / `ArenaWalls.server.luau`.

## License

No license specified yet.
