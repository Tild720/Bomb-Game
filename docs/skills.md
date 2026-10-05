# Skill system

Runtime source is synced by Rojo. UI is authored in StarterGui.SubGui. For reconstruction in Edit mode, run `tools/build-skill-ui.luau`, then `tools/polish-menu-ui.luau`, `tools/section-shop-ui.luau`, and `tools/gradient-menu-ui.luau` in that order. The final skill rows are ImageLabels with independent Action ImageButtons. Do not rebuild existing UI without preserving Studio edits.

The final visual finish now lives in the Rojo-managed `MenuTheme` module, applied once before either menu client binds controls. `tools/tone-menu-ui.luau` previews that same finish in Edit mode. It adds larger text, slate blue tones, rounded outlines, centered 1.5% button hover, clipped stripes and Sunburst asset 76707185718665. Original viewport icons hover at 3.5%.

Dash and double jump start immediately on the owning client, without transferring physics ownership or changing the humanoid to Jumping. The server validates ownership, round state and cooldown and confirms/rejects the prediction. Dash ends after 0.2s or 9 studs, checks walls, fades into the current walking input and explicitly restores walking velocity. Double jump keeps horizontal momentum and sets upward velocity to 34. SkillMotion contains these parameters. Push/slip still use short server-controlled constraints, with both explicit delayed cleanup and Debris expiry. Local effects interpolate trails and pulses, and swaps ease the local camera after teleporting. These refinements have not been playtested.

Each skill row reserves a square SkillImage area left of the name and description. Set the item's Image field in SkillCatalog to an image content ID; the default is blank.

Walk into Workspace.System.ShopHitbox to open the shop / inventory. Leaving or pressing X closes it. After X, leave and re-enter to reopen. Existing SHOP button remains the VIP shop. Buy once, then equip one skill in the skill shop. No skill icons are used.

| Skill | Price | Cooldown | Behavior |
| --- | ---: | ---: | --- |
| Double jump | Free | 0.25s + landing | One additional midair jump. Default owned/equipped. |
| Dash | $3,000 | 2s | Up to 9 studs over 0.2s, shortened by obstructions. No immunity. |
| Push | $5,000 | 3s | Nearest opponent in a forward cone, within 9 studs. Brief knockback, no stun. |
| Banana | $8,000 | 5s | Peel lasts 15s or until stepped on. Opponent speed ×0.6 for 1.5s. Owner unaffected. |
| Swap | $25,000 | 8s | Closest forward opponent within 24 studs. Both flash for 0.65s before swapping; rechecks availability, range, obstacles, and destinations. Bomb ownership is unchanged. |

PC: Q for active skills; jump again for double jump. Gamepad: X for active skills, A again for double jump. Touch: skill button or jump again. Skills run only in Playing with a living round participant. Studio dummies are valid targets but do not autonomously use skills.

Purchase cost, ownership, shop proximity, round state, targeting, and cooldown are checked on the server. Insufficient funds, unavailable targets, cooldown, failed swaps, and shop timeouts use MiniMessageLabel. Failed validation does not consume a cooldown or charge money.

MONEY, WIN, OwnedSkills, and EquippedSkill are stored together in the existing session-locked record, using its existing autosave and leave-save lifecycle. Older records get DoubleJump automatically. Studio API-disabled fallback remains session-only, consistent with existing leaderstats behavior.

Prices and cooldowns are centralized in SkillCatalog.luau. Previous hourly earnings estimates predate coin pickups and no longer describe current progression.

Verification: offline `luau tests/skill-catalog.spec.luau`, Luau compilation, Rojo sourcemap/sync checks, read-only hitbox-boundary checks, and Edit-mode UI previews. No Studio playtest was run; physics feel, touch controls, and real DataStore persistence still need a later authorized gameplay test.

Round coins: ReplicatedStorage.Coin is cloned at random map SpawnPoints, with a world-Y offset of 1 stud. The first batch appears 3s after Playing starts; subsequent batches appear every 4-7s, each containing one coin per starting participant. Living players in the round collect each coin once for $50. Clients animate rotation, pickup fade and sound; the server validates and awards currency. Round end removes remaining coins. Character placement preserves the character's existing rotation instead of inheriting marker orientation.

Smoke has been removed. Stored Smoke ownership is discarded on load; equipped Smoke falls back to DoubleJump.
