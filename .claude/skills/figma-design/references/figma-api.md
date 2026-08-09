# Figma REST API Reference

Base URL: `https://api.figma.com/v1`
Auth header: `X-Figma-Token: <PAT>`

## Rate Limits (enforced since 2025-11-17)

The three endpoints this skill relies on — `GET /files/:key`, `GET /files/:key/nodes`, `GET /images/:key` — are all **Tier 1**, the most restricted tier. Per-minute quota depends on the token's seat and the plan:

| Seat / plan | Tier-1 quota |
| --- | --- |
| View / Collab seat (any plan) | ~6 requests **per month** — effectively unusable for extraction |
| Dev / Full, Starter | ~10 / min |
| Dev / Full, Professional | ~15 / min |
| Dev / Full, Organization | ~20 / min |
| Dev / Full, Enterprise | custom |

Implications for this skill:
- Use a **Dev or Full seat** PAT. A View/Collab token returns 429 with header `X-Figma-Rate-Limit-Type: low`.
- 429 responses carry `Retry-After` (seconds; can be minutes for the per-minute quota, days for an exhausted monthly quota) plus `X-Figma-Plan-Tier` and `X-Figma-Rate-Limit-Type`. `figma_client.py` honors `Retry-After` up to a 180s cap, then aborts with an actionable message.
- Duplicate concurrent runs are the main way this skill trips the limit — the run lock prevents them.
- Personal access tokens expire after 90 days (Figma change 2025-04-28); regenerate with `setup_token.py`.
- Prefer granular scopes (`file_content:read`, `file_variables:read`) over the legacy, no-longer-recommended `files:read`.

Source: https://developers.figma.com/docs/rest-api/rate-limits/

## Endpoints Used

### GET /files/:key
Returns the full document tree, styles map, and component metadata.

**Key response fields:**
```json
{
  "name": "My Design File",
  "lastModified": "2025-01-15T10:30:00Z",
  "document": { /* full node tree */ },
  "styles": {
    "S:abc123": {
      "key": "abc123",
      "name": "primary/500",
      "styleType": "FILL",  // FILL | TEXT | EFFECT | GRID
      "description": ""
    }
  },
  "components": {
    "C:xyz789": {
      "key": "xyz789",
      "name": "Button/Primary",
      "description": "Primary action button"
    }
  }
}
```

### GET /files/:key/nodes?ids=id1,id2
Fetches specific nodes by ID. Used to resolve style node details (colors, typography values).

**Key response fields:**
```json
{
  "nodes": {
    "S:abc123": {
      "document": {
        "id": "S:abc123",
        "name": "primary/500",
        "type": "RECTANGLE",
        "fills": [{ "type": "SOLID", "color": { "r": 0.1, "g": 0.45, "b": 0.9, "a": 1 } }]
      }
    }
  }
}
```

### GET /files/:key/variables/local
Returns all Figma Variables (design token system). Requires Pro/Org plan.

**Key response fields:**
```json
{
  "meta": {
    "variables": {
      "VariableID:1:1": {
        "id": "VariableID:1:1",
        "name": "color/primary/500",
        "resolvedType": "COLOR",  // COLOR | FLOAT | STRING | BOOLEAN
        "variableCollectionId": "VariableCollectionId:1:1",
        "valuesByMode": {
          "1:0": { "r": 0.1, "g": 0.45, "b": 0.9, "a": 1 }
        }
      }
    },
    "variableCollections": {
      "VariableCollectionId:1:1": {
        "id": "VariableCollectionId:1:1",
        "name": "Primitives",
        "defaultModeId": "1:0",
        "modes": [
          { "modeId": "1:0", "name": "Default" },
          { "modeId": "1:1", "name": "Dark" }
        ],
        "variableIds": ["VariableID:1:1"]
      }
    }
  }
}
```

### GET /images/:key?ids=id1,id2&format=png
Exports node(s) as images. Not used by default scripts — for manual asset export.

### GET /teams/:team_id/components
Lists all published components in a team library. Use when working with shared component libraries.

## Node Types Relevant to UI

| Type | Description |
|------|-------------|
| `FRAME` | Screens, containers with auto-layout |
| `COMPONENT` | Reusable component definition |
| `COMPONENT_SET` | Group of component variants |
| `INSTANCE` | Component instance placed in a frame |
| `TEXT` | Text element |
| `RECTANGLE` | Shape, often used for style definitions |
| `GROUP` | Non-layout grouping |
| `VECTOR` | SVG-like path |

## Common Node Properties

```json
{
  "id": "1:23",
  "name": "Button",
  "type": "COMPONENT",
  "description": "...",

  // Layout (auto-layout)
  "layoutMode": "HORIZONTAL",  // HORIZONTAL | VERTICAL | NONE
  "primaryAxisSizingMode": "FIXED",  // FIXED | AUTO (hug)
  "counterAxisSizingMode": "AUTO",
  "primaryAxisAlignItems": "CENTER",  // MIN | CENTER | MAX | SPACE_BETWEEN
  "counterAxisAlignItems": "CENTER",
  "paddingLeft": 16, "paddingRight": 16, "paddingTop": 12, "paddingBottom": 12,
  "itemSpacing": 8,

  // Size
  "absoluteBoundingBox": { "x": 0, "y": 0, "width": 200, "height": 44 },

  // Appearance
  "fills": [{ "type": "SOLID", "color": { "r": 0.1, "g": 0.45, "b": 0.9, "a": 1 }, "opacity": 1 }],
  "strokes": [{ "type": "SOLID", "color": {...} }],
  "strokeWeight": 1,
  "cornerRadius": 8,
  "rectangleCornerRadii": [8, 8, 8, 8],
  "opacity": 1,
  "effects": [{ "type": "DROP_SHADOW", "color": {...}, "offset": {"x": 0, "y": 2}, "radius": 4, "spread": 0 }],

  // Text-specific
  "characters": "Button Label",
  "style": {
    "fontFamily": "Inter",
    "fontSize": 16,
    "fontWeight": 600,
    "lineHeightPx": 24,
    "letterSpacing": 0,
    "textCase": "ORIGINAL",
    "textDecoration": "NONE"
  },

  // Component-specific
  "componentPropertyDefinitions": {
    "Label": { "type": "TEXT", "defaultValue": "Button" },
    "Size": { "type": "VARIANT", "defaultValue": "md", "variantOptions": ["sm", "md", "lg"] },
    "Disabled": { "type": "BOOLEAN", "defaultValue": false },
    "Icon": { "type": "INSTANCE_SWAP", "defaultValue": "icon/arrow-right" }
  },

  "children": [...]
}
```

## Rate Limits

- 60 requests per minute for file reads
- 30 requests per minute for image exports
- Batch node fetches with comma-separated IDs to stay within limits (max ~50 IDs per request)

## PAT Scopes

| Scope | What it enables |
|-------|----------------|
| `file:read` | Read files, styles, components — sufficient for most use cases |
| `variables:read` | Read Figma Variables (design tokens) |
| `file:write` | Write to files (not needed for spec reading) |
