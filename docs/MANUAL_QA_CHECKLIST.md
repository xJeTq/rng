# Manual QA Checklist

## Session boot and onboarding

- [ ] New account receives tutorial and can complete within 60s.
- [ ] Returning account skips tutorial and receives objective banner.
- [ ] Tutorial skip/failsafe never leaves blocked UI state.

## Crystal flow

- [ ] Open Basic/Nova/Nebula crystals with expected currency costs.
- [ ] Rare pull overlay and toast trigger correctly.
- [ ] Low-balance errors show clear, friendly copy.

## Quests + daily rewards

- [ ] Quest progress increments from crystal opens.
- [ ] Earn-stardust quest progresses from passive and rewards.
- [ ] Quest claim grants reward once and blocks duplicates.
- [ ] Daily claim streak increments and blocks same-day repeat.

## Trading

- [ ] Trade request success path works with valid IDs.
- [ ] Invalid/expired/duplicate/not-owned states show clear toasts.
- [ ] Confirm flow cannot be spammed into confusing states.

## Shop and purchases

- [ ] Product and pass prompts open for configured IDs.
- [ ] Success/cancel flows show correct feedback.
- [ ] Ownership restoration appears after rejoin for gamepasses.

## Persistence / reconnect

- [ ] Data survives reconnect mid-session.
- [ ] Trade and quest states recover safely after server rejoin.
- [ ] Shutdown save path works (private server + close test).

## Device QA

- [ ] Phone portrait and landscape layout are readable.
- [ ] Tablet UI scales correctly; no clipped panels.
- [ ] PC keyboard/mouse navigation still usable.
- [ ] Low-end graphics mode keeps stable framerate during reveal effects.

## Network edge cases

- [ ] Simulated high ping does not break crystal/trade claim flows.
- [ ] Rapid tapping stays rate-limited with stable client messaging.

## Moderation / reporting

- [ ] Report flow works from Social cards.
- [ ] Report flow works from Trade panel target reporting.
- [ ] Report category validation and anti-spam messaging behave correctly.
- [ ] Local block hides blocked players from social list in-session.

## Edge-case stabilization

- [ ] Reconnect during/after habitat visit resets UI state safely.
- [ ] Favorite creature removed/desynced path resets favorite without errors.
- [ ] Network failure during remote calls returns friendly messaging (no hard client errors).
- [ ] Trade local cancel clears pending state and prevents accidental confirm spam.
