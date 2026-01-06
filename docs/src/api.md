# API Reference

Complete API documentation for NDViewer.jl.

## Main Functions

```@docs
NDViewer.wgl_create_plot
NDViewer.yaml_viewer
NDViewer.load_from_yaml
NDViewer.create_app_from_yaml
```

## Data Structures

### DataViewerApp

```julia
struct DataViewerApp
    layers      # Layer configuration
    data        # Input data array
    figure      # Makie Figure
    slices      # Dictionary of array slices
    widgets     # Dictionary of UI widgets
    axes        # Makie axes
end
```

The main application structure that combines visualization and interactivity.

### PlaySlider

```julia
struct PlaySlider
    name::String
    range::Vector{Int}
    lookup::Union{Nothing,Dict{Int, Any}}
    value::Observable{Int}
end
```

Interactive slider widget with play/pause functionality for animating through dimensions.

**Constructor:**
```julia
PlaySlider(name, range, lookup=nothing)
```

### SelectOptions

```julia
struct SelectOptions
    name::String
    options::Any
    option::Observable
    value::Observable
end
```

Dropdown selection widget for choosing from discrete options.

**Constructor:**
```julia
SelectOptions(name, pairs)
```

## Widget Functions

```@docs
NDViewer.slice_dim
NDViewer.select_dim_widget
```

## Array Interface

```@docs
NDViewer.get_dim_names
NDViewer.get_axis
```

## Dimension Matching

```@docs
NDViewer.match_dims
NDViewer.accessor2dim
NDViewer.dim2accessor
```

## Styling Functions

### Theme Module

```julia
NDViewer.Theme
```

Contains color constants, spacing values, and design tokens.

**Color Constants:**
- `PRIMARY`, `PRIMARY_DARK`, `PRIMARY_LIGHT`
- `SURFACE`, `BACKGROUND`, `SURFACE_HOVER`
- `TEXT_PRIMARY`, `TEXT_SECONDARY`, `TEXT_MUTED`
- `BORDER`, `BORDER_LIGHT`
- `SUCCESS`, `WARNING`, `ERROR`

**Spacing:**
- `SPACING_XS`, `SPACING_SM`, `SPACING_MD`, `SPACING_LG`, `SPACING_XL`

**Shadows:**
- `SHADOW_SM`, `SHADOW_MD`, `SHADOW_LG`

**Border Radius:**
- `RADIUS_SM`, `RADIUS_MD`, `RADIUS_LG`, `RADIUS_ROUND`

**Typography:**
- `FONT_FAMILY`, `FONT_SIZE_SM`, `FONT_SIZE_MD`, `FONT_SIZE_LG`

**Transitions:**
- `TRANSITION_FAST`, `TRANSITION_NORMAL`

### Style Helper Functions

```julia
NDViewer.widget_card_style() -> Styles
```
Returns styling for widget container cards.

```julia
NDViewer.button_style(; variant=:primary) -> Styles
```
Returns button styling. Variants: `:primary`, `:secondary`, `:icon`.

```julia
NDViewer.label_style(; variant=:default) -> Styles
```
Returns label styling. Variants: `:default`, `:heading`, `:muted`.

```julia
NDViewer.slider_theme() -> NamedTuple
```
Returns slider styling parameters including colors and styles.

```julia
NDViewer.dropdown_style() -> Styles
```
Returns dropdown menu styling.

```julia
NDViewer.app_container_style() -> Styles
```
Returns main application container styling.

```julia
NDViewer.viewer_card_style() -> Styles
```
Returns Makie figure card styling.

```julia
NDViewer.widget_panel_style() -> Styles
```
Returns widget panel container styling.

## Visualization Functions

```julia
NDViewer.create_plot(data, layers; figure=(;))
```
Creates a Makie figure with sliced views and widgets from layer configuration.

**Returns:** `(figure, sliced_arrays, widgets, axes)`

```julia
NDViewer.create_slices(layers, data::AbstractArray)
```
Prepares array slices and widgets based on layer specifications.

**Returns:** `(sliced_arrays, widgets)`

```julia
NDViewer.layer_to_axis!(fig, sliced_arrays, dict, fcolor, cmaps)
```
Converts a layer dictionary to a Makie axis.

```julia
NDViewer.layer_to_plot!(ax, sliced_arrays, dict, fcolor, cmaps)
```
Adds a plot to an axis from layer specification.

## Data Loading

```julia
NDViewer.load_data(data_path::String)
```
Loads data from NetCDF (.nc), HDF5 (.hdf5), or cloud sources (gs://cmip6/...).
Results are cached globally.

## Value Formatting

```julia
NDViewer.format_value(v) -> String
```
Formats values for display in widgets. Rounds floats to 3 decimal places.

## Internal Functions

```julia
NDViewer.access2slice(sliced_arrays, arg::Vector)
```
Retrieves or creates an array slice for given dimension indices.

```julia
NDViewer.replace_slices(sliced_arrays, args)
```
Replaces dimension indices with actual observable slices.

```julia
NDViewer.get_dims!(arrays, widgets, target_dims, names)
```
Recursively creates sliced views and widgets to reach target dimensions.

```julia
NDViewer.remove_dicts!(f, dicts)
```
Filters and extracts dictionaries matching a predicate from layer list.

```julia
NDViewer.resolve_symbol(s)
```
Resolves string symbol names to Julia types/values (e.g., "DataAspect" → DataAspect()).

## Examples

### Basic Usage

```julia
using NDViewer, WGLMakie

# Create 3D data
data = rand(100, 100, 50)

# Define layers
layers = [
    Dict("figure" => Dict("size" => [800, 600])),
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "plots" => [Dict("type" => "image", "args" => [[1, 2]])]
    )
]

# Create viewer
viewer = NDViewer.wgl_create_plot(data, layers)
display(viewer)
```

### YAML Configuration

```julia
# View data from YAML config
app = NDViewer.yaml_viewer("config.yaml")
display(app)
```

### Custom Widgets

```julia
# Create a play slider
slider = NDViewer.PlaySlider("time", collect(1:100))

# Create select options
options = NDViewer.SelectOptions("variable", ["temp" => 1, "pressure" => 2])
```
