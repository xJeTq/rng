# Cosmic Critters Launch Checklist (Phase 2)

## A) Player-facing polish

- [x] Mobile-first HUD with large tap targets and safe-area-aware top bar.
- [x] Core menu tabs and modal panels: Crystals, Creatures, Quests, Shop, Trade, Habitat.
- [x] Consistent close/back behavior with single-active-panel modal state.
- [x] Toast notifications for all key actions.

## B) Onboarding

- [x] Guided tutorial sequence (< 60s target) with objective banner.
- [x] Skips automatically for returning users (`CreatureCount > 0`).
- [x] Failsafe state restoration and anti-stuck step timing.
- [x] Tutorial completion reward and next objective handoff.

## C) Retention / game feel

- [x] Crystal reveal overlay animation and rare-pull emphasis.
- [x] Rare pull celebration (screen shake + messaging).
- [x] Quest complete and daily reward celebration hooks.
- [x] Polished server announcement toast styling.

## D) Shop / monetization presentation

- [x] Category-style product cards with kid-friendly text.
- [x] Starter-offer visual presentation.
- [x] Purchase success/cancel feedback handlers.
- [x] Convenience/style framing language (no pay-to-win wording).

## E) Trade UX

- [x] Trade request form with expiration messaging.
- [x] Confirm path and clear warnings/toasts.
- [x] Handles backend invalid states and duplicate/ownership errors via feedback.

## F) Mobile optimization

- [x] Touch-friendly button sizes.
- [x] Scrollable inventory/quest/shop areas.
- [x] Reduced visual complexity and short-lived effects.

## G) Final pre-launch must-do (remaining)

- [ ] Art pass for final icons, gradients, creature cards, and themed illustrations.
- [ ] Final SFX/music replacement from placeholder asset IDs.
- [ ] Full moderation/reporting UX and support tooling integration.
- [ ] Device QA matrix sign-off (real low-end phones/tablets, not just Studio).
- [ ] Creator Dashboard monetization IDs configured and purchase sandbox verified.

## H) Phase 3 completed in code

- [x] Visual trading flow with player roster + inventory picker + rarity badges + timer + confirm state.
- [x] Social profile summaries and habitat visiting request flow.
- [x] Favorite creature showcase wiring from inventory to habitat/social surfaces.
- [x] Premium card hierarchy pass across quests/shop/trade/social panels.
- [x] Centralized audio mapping with tier-based rarity reveal sounds and purchase/trade/daily cues.
- [x] Soft-launch telemetry events for onboarding, first-time actions, trade/purchase funnels, and announcements.

## I) Phase 4 pre-QA completed in code

- [x] In-world habitat instancing with server-owned visit points.
- [x] Visit flow teleports players to target habitat points in-session.
- [x] Favorite creature showcase pedestal labels update from live profile data.
- [x] Asset replacement structure added (`AssetCatalog.lua`) for final art/audio swaps.
- [x] Low-end fallback mode added for reduced client feedback load.

## J) Final stabilization completed in code

- [x] Moderation/reporting UX integrated into social and trade contexts.
- [x] Server-side report intake with category validation + anti-spam rate limiting.
- [x] Edge-case hardening for network failures, reconnect panel state reset, trade local cancel, and favorite desync handling.
- [x] Economy balance pass for first-session progression and first-10-minute cadence.

## K) Exact soft-launch checklist (must pass)

- [ ] All product/game pass IDs set in `GameConfig.lua` and verified in private server.
- [ ] Moderation report flow tested across Social and Trade contexts.
- [ ] Device matrix smoke pass complete (phone/tablet/PC + low-end quality mode).
- [ ] Telemetry sampling reviewed for tutorial, trade funnel, purchase funnel, and rarity drops.
- [ ] Economy pacing signoff from first 10-minute test script.

## L) Exact public-launch checklist (must pass)

- [ ] Final art pack swapped through `AssetCatalog.lua` and visual QA approved.
- [ ] Final audio ID swap and loudness normalization approved.
- [ ] Full regression QA (reconnect, bad network, purchases, trading expiry, moderation).
- [ ] Moderation triage playbook and on-call owner assigned.
- [ ] Go/no-go review signed with risk log and rollback plan.
