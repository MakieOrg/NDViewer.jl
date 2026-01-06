# Theme constants for NDViewer
# Uses CSS variables compatible with BonitoBook, with fallbacks for standalone use

using Bonito: Styles, CSS, RGBA

module Theme
    # Color palette - these are used as fallbacks when BonitoBook variables aren't available
    const PRIMARY = "#4a90d9"
    const TEXT_PRIMARY = "#212529"
    const TEXT_SECONDARY = "#6c757d"
    const BORDER = "#dee2e6"
    const SURFACE = "#ffffff"
    const BACKGROUND = "#f8f9fa"
end

# Global NDViewer styles that work both standalone and inside BonitoBook
# Uses CSS variables with fallbacks
const NDVIEWER_BASE_STYLES = Styles(
    # Define fallback CSS variables for standalone use
    CSS(
        ":root",
        "--ndviewer-bg-primary" => "var(--bg-primary, #ffffff)",
        "--ndviewer-text-primary" => "var(--text-primary, #212529)",
        "--ndviewer-text-secondary" => "var(--text-secondary, #6c757d)",
        "--ndviewer-border-primary" => "var(--border-primary, rgba(0,0,0,0.1))",
        "--ndviewer-border-secondary" => "var(--border-secondary, #dee2e6)",
        "--ndviewer-hover-bg" => "var(--hover-bg, #f8f9fa)",
        "--ndviewer-accent" => "var(--accent-blue, #4a90d9)",
        "--ndviewer-border-radius" => "var(--border-radius-large, 6px)",
        "--ndviewer-spacing-sm" => "var(--spacing-sm, 0.5rem)",
        "--ndviewer-spacing-md" => "var(--spacing-md, 0.75rem)",
        "--ndviewer-font-size-sm" => "var(--font-size-sm, 0.8125rem)",
        "--ndviewer-transition" => "var(--transition-slow, 0.2s ease)",
    ),
    # Container styling
    CSS(
        ".ndviewer-container",
        "display" => "flex",
        "flex-direction" => "column",
        "gap" => "var(--ndviewer-spacing-sm)",
    ),
)

# Helper functions kept for API compatibility with tests
function widget_card_style()
    return Styles()
end

function button_style(; variant=:primary)
    return Styles()
end

function label_style(; variant=:default)
    return Styles()
end

function slider_theme()
    return (
        slider_height = 20,
        track_color = "#eee",
        track_active_color = "#ddd",
        thumb_color = "#fff",
        backgroundcolor = "transparent",
        track_style = Styles(),
        thumb_style = Styles(),
        track_active_style = Styles(),
    )
end

function dropdown_style()
    return Styles()
end

function app_container_style()
    return Styles()
end

function viewer_card_style()
    return Styles()
end

function widget_panel_style()
    return Styles()
end
