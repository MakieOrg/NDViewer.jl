# Getting Started

This guide walks you through creating your first NDViewer visualization.

## Basic Usage

### Viewing a Simple Array

The simplest way to use NDViewer is with a multi-dimensional array:

```julia
using NDViewer, WGLMakie

# Create sample 3D data (e.g., temperature over time)
data = [sin(x/10) * cos(y/10) * sin(t/5) for x in 1:100, y in 1:100, t in 1:50]

# Define the visualization
layers = [
    Dict("figure" => Dict("size" => [800, 600])),
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "attributes" => Dict("aspect" => "DataAspect"),
        "plots" => [
            Dict(
                "type" => "image",
                "args" => [[1, 2]],  # Display dimensions 1 and 2
                "attributes" => Dict("colormap" => "viridis")
            )
        ]
    )
]

# Create the viewer
viewer = NDViewer.wgl_create_plot(data, layers)
display(viewer)
```

This creates an interactive viewer where you can:
- Use the slider to animate through the third dimension
- Click the play button to auto-animate
- See the current value displayed

### Using DimensionalData Arrays

NDViewer works seamlessly with labeled arrays from DimensionalData.jl:

```julia
using NDViewer, WGLMakie, DimensionalData

# Create a labeled array
data = DimArray(
    rand(100, 100, 24),
    (X(1:100), Y(1:100), Ti(1:24))  # X, Y spatial dims, Ti for time
)

layers = [
    Dict("figure" => Dict("size" => [800, 600])),
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "plots" => [
            Dict("type" => "heatmap", "args" => [[1, 2]])
        ]
    )
]

viewer = NDViewer.wgl_create_plot(data, layers)
```

The dimension names (X, Y, Ti) will appear in the widget labels automatically.

## Loading from Files

### NetCDF Files

```julia
using NDViewer

# Load and view a NetCDF file
viewer = NDViewer.yaml_viewer("path/to/config.yaml")
display(viewer)
```

With a YAML configuration file:

```yaml
data:
  path: "./temperature_data.nc"
layers:
  - figure:
      size: [1000, 800]
  - type: Axis
    position: [1, 1]
    attributes:
      aspect: DataAspect
    plots:
      - type: image
        args: [[1, 2]]
        attributes:
          colormap: viridis
```

## Multiple Plots

You can create complex layouts with multiple axes:

```julia
layers = [
    Dict("figure" => Dict("size" => [1200, 600])),
    # Main heatmap view
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "plots" => [
            Dict("type" => "heatmap", "args" => [[1, 2]])
        ]
    ),
    # Line plot showing a 1D slice
    Dict(
        "type" => "Axis",
        "position" => [1, 2],
        "plots" => [
            Dict(
                "type" => "lines",
                "args" => [[1]],
                "attributes" => Dict("color" => "blue", "linewidth" => 2)
            )
        ]
    )
]
```

## Next Steps

- Learn about [YAML Configuration](yaml_config.md) for declarative setups
- Customize the look with [Theming](theming.md)
- Explore the full [API Reference](api.md)
