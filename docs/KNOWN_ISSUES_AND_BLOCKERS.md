# Known Issues / Remaining Blockers

## Current classification

The game is **soft-launch ready candidate**, not polished full public-launch ready.

## Top blockers

1. **Art/content completeness**: UI currently uses functional but temporary visual styling and basic cards.
2. **Audio finalization**: SFX hooks are present, but IDs are placeholders and need final mix pass.
3. **Trading UX depth**: backend is hardened, but client still uses UserId + comma-id entry workflow (needs richer picker UI).
4. **Social systems depth**: habitat visiting and showcase are represented by UI hooks/messages, not full networked scene flow.
5. **QA breadth**: full live-device testing and purchase edge-case sign-off remains required.

## Minor known issues

- Crystal/tutorial interactions rely on timing-based guidance; arrow/highlight should be upgraded to true target pinning per button.
- Collection panel currently visualizes unlock states from aggregate count, not full server inventory snapshots.
- Shop card ordering and badge states should read dynamic ownership and sale flags from live config.
