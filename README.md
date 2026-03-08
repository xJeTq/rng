# Cosmic Critters ⭐ (Roblox)

A viral-ready Roblox collection game concept and implementation scaffold focused on:

- **RNG collectible discovery** (non-gambling framing)
- **Long-term progression** (stardust economy, habitats, unlocks)
- **Social flex loops** (announcements, showcases, leaderboards)
- **Monetization** via speed/convenience/cosmetics

## Folder Structure

```text
src/
  ReplicatedStorage/
    Config/
      GameConfig.lua
      RarityConfig.lua
    Modules/
      RNG.lua
      CreatureCatalog.lua
  ServerScriptService/
    Main.server.lua
    Services/
      AnalyticsService.lua
      AntiExploitService.lua
      CurrencyService.lua
      DataService.lua
      HabitatService.lua
      MonetizationService.lua
      QuestService.lua
      TradingService.lua
  StarterPlayer/
    StarterPlayerScripts/
      Main.client.lua
```

## Core Systems Included

- RNG crystal opening with pity logic
- Creature inventory and rarity metadata
- Stardust passive generation loop
- Daily rewards + streak + quests starter logic
- Trading validation and anti-exploit checks
- RemoteEvent/RemoteFunction server-authoritative APIs
- Monetization hooks for developer products + passes + subscription flags
- Leaderstats and analytics event sink

## Roblox Studio Installation

1. Create a new Roblox place.
2. Add the following containers if they do not exist:
   - `ReplicatedStorage`
   - `ServerScriptService`
   - `StarterPlayer > StarterPlayerScripts`
3. Copy each Lua file from this repository into matching Roblox instances.
4. In `ReplicatedStorage`, create a folder called `Remotes`.
5. Run the place once in Studio to let `Main.server.lua` auto-create missing remotes:
   - `OpenCrystal` (RemoteFunction)
   - `ClaimDailyReward` (RemoteFunction)
   - `CreateTrade` (RemoteFunction)
   - `AcceptTrade` (RemoteFunction)
   - `UpgradeHabitat` (RemoteFunction)
   - `ServerAnnouncement` (RemoteEvent)
   - `DataReady` (RemoteEvent)

## UI Setup (Mobile-first)

Create a `ScreenGui` with large tap-friendly buttons and tabs:

- Open Crystals
- Creatures
- Shop
- Habitat
- Trade
- Quests

Bind the buttons to calls shown in `Main.client.lua`.

## Monetization Setup

Set IDs in `GameConfig.lua` for:

- Developer Products:
  - CrystalBundle
  - LuckBoostPotion
  - InstantOpen
  - HabitatUpgrade
  - EnergyRefill
- Game Passes:
  - VIPHabitat
  - AutoOpener
  - ExtraCreatureSlots
  - DoubleStardust
  - ExclusiveThemes

Then configure matching IDs in Roblox Creator Dashboard.

## Publish Checklist

1. Configure game icon + thumbnail with bright cosmic art.
2. Add age-appropriate descriptions.
3. Enable API services if needed for analytics integrations.
4. Test on mobile emulator and low graphics quality.
5. Verify DataStore keys in a private test server.
6. Publish and monitor retention metrics.

## Policy Notes

- RNG is presented as collectible discovery from gameplay currency.
- Paid products accelerate progression or add cosmetics; they do **not** directly sell random outcomes.
- All critical economy logic remains server-authoritative.
