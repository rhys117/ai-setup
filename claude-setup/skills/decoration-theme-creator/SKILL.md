---
name: decoration-theme-creator
description: "End-to-end workflow for creating new decoration themes for the They Said Yes invitation app. Covers theme ideation, Midjourney image generation, image downloading and processing, YAML config integration, theme set creation, and visual testing. Use this skill whenever the user wants to add a new decoration theme, create invitation decorations, generate background textures or border images, or mentions Midjourney in the context of this app."
---

# Decoration Theme Creator

Create new decoration themes for the They Said Yes app. Themes are entirely YAML-config-driven — no Ruby code changes needed.

## Theme Layout Types

| Layout | Description | Image assets needed | Aspect ratio |
|--------|-------------|-------------------|--------------|
| `corner` | Top-right / bottom-left corner borders | `{slug}-top.png`, `{slug}-bottom.png`, `{slug}-preview.png` | 3:4 |
| `horizontal` | Full-width top/bottom borders | `{slug}-top.png`, `{slug}-bottom.png`, `{slug}-preview.png` | 8:1 |
| `vignette` | Frame around all edges, clear center | `{slug}-top.png`, `{slug}-bottom.png`, `{slug}-preview.png` | 3:4 |
| `background` | Subtle full-page background texture | `{slug}-background.png`, `{slug}-preview.png` | 3:4 |
| `box` | CSS-only bordered box | None | — |
| `divider` | CSS-only minimalist line | None | — |

## Workflow

1. **Ideate** — Check existing themes in `config/decoration_themes.yml`, suggest gaps
2. **User confirms** — Theme slug, visual direction, layout type
3. **Generate on Midjourney** via browser
4. **User selects** images (never choose for them)
5. **Download and process** images
6. **Add YAML config** — `decoration_themes.yml` + `theme_sets.yml`
7. **Restart server** — `touch tmp/restart.txt` (config is loaded at boot and frozen)
8. **Visual test** — Check text readability and adjust opacity

---

## Step 1: Theme Ideation

Read `config/decoration_themes.yml` and review `app/assets/images/decorations/` to see what exists.

Suggest themes that fill gaps in aesthetic style, season, formality, or cultural diversity. Present 3-5 concepts with brief visual descriptions. Wait for user confirmation.

## Step 2: User Confirms Direction

Lock in:
- Theme slug (kebab-case, e.g., `coastal-mist`)
- Layout type (corner, horizontal, vignette, or background)
- Visual direction (key elements, colours, mood)

## Step 3: Generate on Midjourney

Navigate to midjourney.com in the browser.

### Prompt Patterns by Layout

**Corner themes:**
```
[descriptive elements], arranged as corner border decoration cascading from the top right, on a clean white background, [style descriptors] --v 7 --style raw --ar 3:4
```

**Background themes:**
```
[texture/pattern description], seamless background texture, [style descriptors] --v 7 --style raw --ar 3:4
```

Background prompts should describe textures, washes, or patterns — NOT dense photographic subjects. The image renders behind text at reduced opacity, so it must be low-contrast and uniform enough to not compete with text.

Generate 2-4 variations. Present to the user and wait for selection.

## Step 4: Download and Process Images

### Downloading from Midjourney

Midjourney CDN is blocked from the VM. Use browser JavaScript:

```javascript
fetch('IMAGE_URL')
  .then(r => r.blob())
  .then(blob => {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'theme-name-source.png';
    a.click();
  });
```

The file lands in the Downloads folder.

### Processing — Corner/Horizontal/Vignette Themes

Install Pillow if needed: `pip install Pillow --break-system-packages`

1. **Remove white background** — Convert white/near-white pixels to transparent
2. **Gradient edge smoothing** — Soft fade at transparency boundaries
3. **Auto-crop** transparent padding
4. **Resize** to ~1500px longest edge

```python
from PIL import Image
import numpy as np

def process_decoration_image(input_path, output_path, alpha_threshold=240):
    img = Image.open(input_path).convert('RGBA')
    data = np.array(img)

    r, g, b, a = data[:,:,0], data[:,:,1], data[:,:,2], data[:,:,3]
    white_mask = (r > alpha_threshold) & (g > alpha_threshold) & (b > alpha_threshold)
    data[white_mask, 3] = 0

    brightness = (r.astype(float) + g.astype(float) + b.astype(float)) / 3.0
    near_white = (brightness > 200) & (~white_mask)
    fade_factor = (brightness[near_white] - 200) / (alpha_threshold - 200)
    data[near_white, 3] = (255 * (1 - fade_factor)).astype(np.uint8)

    result = Image.fromarray(data)
    bbox = result.getbbox()
    if bbox:
        result = result.crop(bbox)

    max_dim = max(result.size)
    if max_dim > 1500:
        scale = 1500 / max_dim
        new_size = (int(result.width * scale), int(result.height * scale))
        result = result.resize(new_size, Image.LANCZOS)

    result.save(output_path, 'PNG', optimize=True)
    return result
```

**Create top and bottom borders** from the source:
- Top (`{slug}-top.png`): Source image, elements flowing from top-right
- Bottom (`{slug}-bottom.png`): 180° rotation of top (keeps elements pointing outward)

**Preview** (`{slug}-preview.png`): Resize top image to 800x800.

### Processing — Background Themes

Background themes are simpler — NO background removal needed. The source image IS the background.

1. Resize to **928x1232** (standard background/preview size, RGB mode)
2. Save as `{slug}-background.png`
3. **Copy** the background as `{slug}-preview.png` (they're identical for background themes)

```python
from PIL import Image

img = Image.open('source.png')
resized = img.resize((928, 1232), Image.LANCZOS).convert('RGB')
resized.save('{slug}-background.png')
resized.save('{slug}-preview.png')
```

### File Placement

All images go in `app/assets/images/decorations/`.

## Step 5: YAML Configuration

### `config/decoration_themes.yml`

Add the theme entry. Example for a background theme:

```yaml
coastal-mist:
  name: Coastal Mist
  layout: background
  image_extension: png
  default_colour_palette: DustyBlue
  elements:
    background:
      position: full
      size: full
      opacity: 30
```

Example for a corner theme:

```yaml
tropical-leaf:
  name: Tropical Leaf
  layout: corner
  image_extension: png
  default_colour_palette: SageGreen
  elements:
    top:
      position: right
      size: medium
    bottom:
      position: left
      size: medium
```

### Opacity Guidelines for Background Themes

Opacity depends heavily on the image content. Dense, high-contrast, or photorealistic images need much lower opacity than subtle textures:

| Image character | Recommended opacity | Examples |
|----------------|-------------------|----------|
| Subtle watercolour wash | 25-40% | blush-watercolor, sage-watercolor |
| Soft texture (damask, marble, veil) | 20-30% | cream-damask, marble-texture, ethereal-veil |
| Fine detailed texture (linen, paper) | 10-20% | soft-linen |
| Bold painterly brushstrokes | 15-30% | dusty-blue-wash |
| Strong colour blocks / shapes | 40-70% | terracotta-wash |
| Dense photorealistic (florals, botanicals) | 40-60% | midnight-garden |
| Dark/moody scenes | 40-60% | celestial-night |

**Key principle**: The text on the invitation must always be easily readable. Test visually and adjust. Some images that look subtle at source can be surprisingly dominant at even low opacity because of high local contrast or busy detail.

### `config/theme_sets.yml`

Create a curated theme set that bundles the decoration theme with a colour palette and font pairing. Sets without `enabled: false` appear in the theme selection dropdown.

```yaml
coastal-mist:
  name: Coastal Mist
  decoration_theme: coastal-mist
  colour_palette: DustyBlue
  font_pairing: timeless
  uppercase_names: true
  preview_description: Soft coastal watercolour with gentle blue tones
```

Available colour palettes: `Olive`, `DarkOlive`, `Lavender`, `LavenderHaze`, `SageGreen`, `DustyBlue`, `Blush`, `SoftMint`, `PalePeach`, `IvoryBlue`

Available font pairings: `classic`, `romantic`, `modern`, `timeless`, `whimsical`, `refined`

**Every image-based decoration theme must appear in at least one theme set.**

### No Ruby Code Changes Needed

The system is fully YAML-config-driven:
- `DecorationTheme` loads all themes from `decoration_themes.yml` at boot
- `ThemeSet` loads all sets from `theme_sets.yml` at boot
- Constants, factory methods, and registry entries are auto-generated from the YAML
- Element types are resolved from the element name (`top`/`bottom` → `BorderImage`, `background` → `Base`, `divider` → `Divider`)

## Step 6: Restart and Test

### Server Restart Required

The YAML config is loaded once at class load time and frozen. After any YAML changes:

```bash
touch tmp/restart.txt
```

This triggers puma-dev to restart the server. Wait a few seconds before testing.

### Visual Testing

Test on the live invitation page, not just the settings preview.

1. Go to settings: `http://<directory>.test/app/settings/customisation/edit`
2. Select the new theme from the dropdown
3. Save changes
4. Check the invitation page directly (use an impersonation link or guest URL)
5. Verify:
   - **Text readability** — All text (names, dates, location, RSVP line, buttons) is clearly legible
   - **Button visibility** — "Politely Decline" and "RSVP" buttons are visible and readable
   - **No artifacts** — No white background showing through, no harsh edges
   - **Works across palettes** — Try different colour palettes; text should stay readable

### Adjusting After Testing

If text is hard to read, adjust opacity in `decoration_themes.yml` and restart:
```bash
touch tmp/restart.txt
```

Re-test on the invitation page (not just the settings preview — the preview iframe can cache).

---

## Quick Reference: Adding a New Theme

| Step | What to do |
|------|-----------|
| Generate image | Midjourney via browser |
| Process image | Pillow — resize/crop, background removal (corner only) |
| Place assets | `app/assets/images/decorations/{slug}-*.png` |
| Config theme | Add entry in `config/decoration_themes.yml` |
| Config set | Add entry in `config/theme_sets.yml` |
| Restart | `touch tmp/restart.txt` |
| Test | Visual check on invitation page, adjust opacity if needed |
