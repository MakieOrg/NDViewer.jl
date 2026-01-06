# Theming

NDViewer includes a modern, polished theme system built on Bonito's styling capabilities. The theme provides consistent colors, spacing, and visual design across all UI elements.

## Theme Colors

The default theme uses a professional blue color scheme:

```julia
using NDViewer

# Access theme colors
NDViewer.Theme.PRIMARY          # "#4a90d9" - Primary blue
NDViewer.Theme.PRIMARY_DARK     # "#3a7bc8" - Hover states
NDViewer.Theme.PRIMARY_LIGHT    # "#6ba3e0" - Active states

NDViewer.Theme.SURFACE          # "#ffffff" - Card backgrounds
NDViewer.Theme.BACKGROUND       # "#f8f9fa" - Page background

NDViewer.Theme.TEXT_PRIMARY     # "#212529" - Main text
NDViewer.Theme.TEXT_SECONDARY   # "#6c757d" - Muted text
```

## Spacing System

Consistent spacing throughout the UI:

```julia
NDViewer.Theme.SPACING_XS       # "4px"
NDViewer.Theme.SPACING_SM       # "8px"
NDViewer.Theme.SPACING_MD       # "12px"  - Default
NDViewer.Theme.SPACING_LG       # "16px"
NDViewer.Theme.SPACING_XL       # "24px"
```

## Shadows and Borders

```julia
NDViewer.Theme.SHADOW_SM        # Subtle elevation
NDViewer.Theme.SHADOW_MD        # Medium elevation
NDViewer.Theme.SHADOW_LG        # High elevation

NDViewer.Theme.RADIUS_SM        # "4px" - Buttons
NDViewer.Theme.RADIUS_MD        # "8px" - Cards
NDViewer.Theme.RADIUS_LG        # "12px" - Panels
```

## Styling Functions

NDViewer provides helper functions for consistent styling:

### Widget Styles

```julia
# Widget container cards
card_style = NDViewer.widget_card_style()

# Dropdown menus
dropdown_style = NDViewer.dropdown_style()

# Slider theme (returns NamedTuple)
slider_theme = NDViewer.slider_theme()
```

### Button Styles

```julia
# Primary action button (blue)
primary_btn = NDViewer.button_style(variant=:primary)

# Secondary button (white)
secondary_btn = NDViewer.button_style(variant=:secondary)

# Icon button (transparent)
icon_btn = NDViewer.button_style(variant=:icon)
```

### Label Styles

```julia
# Default label
label = NDViewer.label_style(variant=:default)

# Heading label (larger, bold)
heading = NDViewer.label_style(variant=:heading)

# Muted label (gray)
muted = NDViewer.label_style(variant=:muted)
```

### Container Styles

```julia
# Main app container
app_style = NDViewer.app_container_style()

# Figure viewer card
viewer_style = NDViewer.viewer_card_style()

# Widget panel
panel_style = NDViewer.widget_panel_style()
```

## Custom Styling

While NDViewer has a cohesive default theme, you can customize individual components using Bonito's `Styles`:

```julia
using Bonito

# Create custom widget with modified styling
custom_card_style = Styles(
    NDViewer.widget_card_style(),  # Start with defaults
    Styles("background-color" => "#f0f0f0")  # Override
)
```

## Typography

The theme uses system fonts for best performance and native feel:

```julia
NDViewer.Theme.FONT_FAMILY
# "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, ..."

NDViewer.Theme.FONT_SIZE_SM     # "0.875rem" - Small text
NDViewer.Theme.FONT_SIZE_MD     # "1rem" - Default
NDViewer.Theme.FONT_SIZE_LG     # "1.125rem" - Headings
```

## Transitions

Smooth animations for interactive elements:

```julia
NDViewer.Theme.TRANSITION_FAST      # "all 0.15s ease"
NDViewer.Theme.TRANSITION_NORMAL    # "all 0.25s ease"
```

## Design Principles

The NDViewer theme follows these principles:

1. **Clarity**: High contrast text, clear visual hierarchy
2. **Consistency**: Uniform spacing and sizing throughout
3. **Professionalism**: Subtle shadows, modern rounded corners
4. **Accessibility**: WCAG-compliant color contrasts
5. **Performance**: System fonts, minimal CSS

## Future Customization

Theme customization is planned for future releases. This will allow:

- Custom color schemes
- Dark mode support
- Adjustable spacing scales
- Font family selection

For now, the default theme provides a polished, professional appearance out of the box.
