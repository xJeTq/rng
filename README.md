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
   - `ClaimQuest` (RemoteFunction)
   - `GetSocialSnapshot` (RemoteFunction)
   - `GetCreatureInventory` (RemoteFunction)
   - `SetFavoriteCreature` (RemoteFunction)
   - `VisitHabitat` (RemoteFunction)
   - `TrackClientEvent` (RemoteFunction)
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

## Production Readiness (Current State)

This repository is a **strong prototype scaffold**, but it is **not fully polished for immediate public launch** yet.

Before publishing to a large audience, complete at least:

- Full GUI implementation (inventory, trading UX, quests, shop confirmations)
- Moderation-safe text filtering and reports for social surfaces
- Comprehensive QA on live servers and mobile devices
- Balancing pass for economy inflow/outflow and progression pacing
- Event content pipeline (weekly events, limited creatures, admin tools)
- End-to-end purchase testing with real product/game pass IDs

## Launch Tickets Completed In This Repo

- Server-side quest claim endpoint (`ClaimQuest`) with validation and reward payout
- Daily quest reset based on UTC day (`QuestDay`)
- Trade hardening (ownership checks, duplicate guard, self-trade block, 120s expiry)
- Remote anti-spam rate limits added beyond crystal opens (daily, quests, trade, habitat)
- Safer persistence with retry + `UpdateAsync`, plus `BindToClose` full-save flush
- Economy hardening for crystal open costs and rollback on failure

## Still Required Before A Polished Public Launch

- Production UI/UX (inventory grids, trade confirmation flows, shop modal states, quest panel)
- Full observability backend (persistent analytics export, dashboards, alerts)
- Content ops tooling for weekly events / limited creatures / live balancing toggles
- End-to-end platform QA: console/tablet coverage, reconnect/latency tests, purchase rollback tests
- Safety systems: robust player report flow, moderation queues, abuse review tooling

## Phase 2 UX Polish Added

- Fully rebuilt player-facing UI shell in `Main.client.lua` with mobile-first HUD, tabbed panels, and non-overlapping modal state handling.
- Added improved onboarding/tutorial flow with objective prompts, completion reward, and return-player auto-skip behavior.
- Added polished player feedback loops: reveal overlays, toasts, rare celebration shake, and purchase feedback hooks.
- Added shop and trade UX presentation layers on top of hardened backend remotes.
- Added launch planning docs in `docs/` for checklist, known blockers, and manual QA pass.

## Phase 3 Launch-Polish Added

- Trade UX rebuilt to visual picker flow (player list, creature cards, rarity badges, add/remove offers, timer, confirm safety messaging).
- Social layer expanded with visit flow, player collection summaries, and favorite showcase integration.
- Premium presentation pass for cards, rarity color language, and hierarchy improvements in key panels.
- Audio pass upgraded with centralized SFX + tiered rarity reveal audio mappings in `UIConfig.lua`.
- Soft-launch telemetry hooks added for tutorial, first-time milestones, trade funnel, purchase funnel, and social interactions.
