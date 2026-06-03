# Assets

Placeholder folder. The MSIX manifest references three PNG icons that **must
exist** before `makeappx pack` will succeed:

| File                  | Required size |
|-----------------------|---------------|
| `Square44x44Logo.png` | 44 × 44       |
| `Square150x150Logo.png` | 150 × 150   |
| `StoreLogo.png`       | 50 × 50       |

Drop in any PNGs of the right dimensions to unblock packaging. They show up as
the app's tile/list icon in Settings → Apps; they aren't shown in the actual
context menu (the menu icon comes from each `commands.json` entry's `icon`
field).
