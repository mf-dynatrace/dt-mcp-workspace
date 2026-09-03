# Element Name Data Quality & Coverage

## The Three States of `ui_element.detected_name`

| State | DQL condition | Meaning | Action |
|---|---|---|---|
| **Named** | `isNotNull(detected_name) and detected_name != "masked"` | OneAgent found an aria-label, visible text content, or `data-dt-name` attribute. Readable and useful. | Use as-is |
| **Masked** | `detected_name == "masked"` | Intentional privacy/PCI masking by the Dynatrace OneAgent masking rules. Working as designed — do not try to un-mask. | Leave as-is |
| **Unnamed** | `isNull(detected_name)` | Purely structural element (anonymous `<div>`, `<span>`, etc.) with no accessible name. OneAgent could not find any text to describe it. | Fix via instrumentation (see below) |

## Checking Coverage

```dql
fetch user.events, from:now()-1h
| filter frontend.name == "$APP" and page.name == "$PAGE"
| filter characteristics.has_user_action and interaction.type == "click"
| fieldsAdd quality = if(
    isNotNull(ui_element.detected_name) and ui_element.detected_name != "masked",
    "Named",
    else: if(ui_element.detected_name == "masked", "Masked", else: "Unnamed"))
| summarize clicks = count(), by:{quality, ui_element.tag_name}
| sort clicks desc
```

## Typical Distribution

| Coverage | Interpretation |
|---|---|
| >50% Named | Good — most interactions are interpretable |
| 20–50% Named | Moderate — some key elements labelled, structural containers unnamed |
| <20% Named | Poor — application uses mostly anonymous containers. High value in adding labels. |

## How to Improve Unnamed Coverage (query-side guidance only)

The following guidance is for communication to the engineering team — do NOT modify application code as part of this skill.

### Option 1: `data-dt-name` HTML attribute (recommended)
Add to any element that users click and that currently appears as unnamed:
```html
<div class="product-card" data-dt-name="product-card">...</div>
<div class="filter-chip" data-dt-name="filter: [category]">...</div>
```
OneAgent automatically picks up this attribute. No JavaScript changes needed. One attribute per element.

### Option 2: ARIA labels
If the element already should have an accessible name for screen readers, an `aria-label` also works:
```html
<button aria-label="Add to basket — [Brand] [Product Name]">...</button>
```

### Option 3: Visible text content
Elements with readable text content (headings, link text, button labels) are automatically named by OneAgent without any code changes.

## What "Masked" Means in Practice

Masking is configured in the Dynatrace RUM settings (Data Privacy → Session Replay & Masking). Common patterns:
- Form field values (passwords, card numbers, personal data)
- Custom masking rules applied by the application team

`masked` clicks are counted in the total but their element name is intentionally hidden. This is correct behaviour — do not flag as a data gap.

## Example: Labelling Product Cards on a Search Page

Before (unnamed):
```html
<div class="product-card">
  <img src="..."><h3>Product Name</h3><span class="price">£12.99</span>
</div>
```
95% of clicks on this card land on the `<div>` wrapper → show as unnamed.

After (named):
```html
<div class="product-card" data-dt-name="product-card">
  <img src="..."><h3>Product Name</h3><span class="price">£12.99</span>
</div>
```
All clicks on the wrapper now appear as "product-card" in Dynatrace.

**Business value:** transforms thousands of anonymous div clicks per hour into a measurable "product card click rate" that can be tracked over time as a conversion signal.
