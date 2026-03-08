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
