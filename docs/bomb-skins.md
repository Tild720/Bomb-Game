# Bomb skins

Runtime code is synced by Rojo. ReplicatedStorage.BombSkins supplies the six sample BasePart/MeshPart templates. BombSkinCatalog orders them by price and generates stable alphanumeric IDs from their names. A numeric Price attribute on a template overrides its sample price; the default Bomb is always free.

| Skin | Price |
| --- | ---: |
| Bomb | Free |
| Smile | $1,000 |
| SoccerBall | $1,500 |
| Beach Ball | $2,500 |
| Epic | $4,000 |
| Eye Ball | $6,000 |

System.SkinShopHitbox opens the red BombSkinShop. X dismisses it until the player exits and re-enters; leaving, dying or joining a round also closes it. Existing menu panels and the skill shop close when the skin shop opens. Every row shows a rotating 3D preview and BUY / EQUIP / EQUIPPED controls. The UI clones the finished skill shop layout, font, texture, shadow and patterns. BombSkinUI also constructs it if no authored copy exists.

The server validates loaded player data, living character, shop proximity, round state, known skin, ownership and balance. Purchases deduct MONEY once and set ownership; equipping is free. Failures and successes use the existing MiniMessageLabel. OwnedBombSkins and EquippedBombSkin are saved alongside MONEY, WIN and skills in the existing session-locked record. Old saves get Bomb automatically; malformed or removed selections fall back to Bomb.

Each bomb holder uses their equipped skin, including when receiving a pass. Swapping the visual does not change fuse time, holder identity, pass range or rewards. Every clone receives the standard BombTimer and has template scripts/sounds removed. Studio dummies use Bomb.

Verification uses Luau compilation and tools/verify-bomb-skins.luau in Edit mode, with unparented temporary clones only. No playtest is started.
