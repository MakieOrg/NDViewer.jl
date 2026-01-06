# YAML Configuration

NDViewer supports declarative visualization configuration via YAML files. This allows you to define complex multi-panel layouts without writing code.

## Basic Structure

Every YAML configuration has two required top-level keys:

```yaml
data:
  path: "./mydata.nc"  # Path to your data file

layers:
  - # Layer 1: Figure configuration
  - # Layer 2: Axis and plots
  - # Layer 3: More axes...
```

## Data Sources

### Local NetCDF Files

```yaml
data:
  path: "./temperature_data.nc"
```

### Cloud Data (CMIP6)

```yaml
data:
  path: "gs://cmip6/CMIP6/CMIP/..."
```

### HDF5 Files

```yaml
data:
  path: "./data.hdf5"
```

## Layer Types

### Figure Layer

Define the overall figure size:

```yaml
- figure:
    size: [1000, 800]  # Width x Height in pixels
```

### Layout Layer

Control row/column sizing:

```yaml
- layout:
    rowsize: [0.8, 0.2]  # Relative sizes (80% for first row, 20% for second)
```

Or for columns:

```yaml
- layout:
    colsize: [1.0, 1.0, 0.5]  # Three columns
```

### Axis Layers

Define visualization axes with plots:

```yaml
- type: Axis
  position: [1, 1]  # Grid position [row, column]
  attributes:
    aspect: DataAspect  # Preserve data aspect ratio
    title: "Temperature"
  plots:
    - type: image
      args: [[1, 2]]  # Display dimensions 1 and 2
      attributes:
        colormap: viridis
```

## Plot Types

### Heatmap

```yaml
- type: heatmap
  args: [[1, 2]]
  attributes:
    colormap: thermal
```

### Image

```yaml
- type: image
  args: [[1, 2]]
  attributes:
    colormap: viridis
    interpolate: true
```

### Lines

```yaml
- type: lines
  args: [[1]]  # 1D slice
  attributes:
    color: blue
    linewidth: 2
```

### Surface (3D)

```yaml
- type: surface
  args: [[1, 2]]
  attributes:
    colormap: viridis
    shading: true
```

### Volume (3D)

```yaml
- type: volume
  args: [[1, 2, 3]]
  attributes:
    colormap: plasma
    algorithm: absorption
```

## Geographic Visualizations

Use Tyler.jl for map overlays:

```yaml
- type: Tyler
  position: [1, 1]
  attributes:
    provider: OpenStreetMap  # Or Esri, Stamen, etc.
  plots:
    - type: heatmap
      args: [[1, 2]]
      attributes:
        colormap: viridis
        alpha: 0.6
```

## Complete Example

Here's a full configuration showing multiple panels:

```yaml
data:
  path: "./climate_data.nc"

layers:
  # Figure configuration
  - figure:
      size: [1200, 800]

  # Layout: 80% for main view, 20% for profile
  - layout:
      rowsize: [0.8, 0.2]

  # Main heatmap view
  - type: Axis
    position: [1, 1]
    attributes:
      aspect: DataAspect
      title: "Surface Temperature"
      xlabel: "Longitude"
      ylabel: "Latitude"
    plots:
      - type: heatmap
        args: [[1, 2]]  # lon, lat
        attributes:
          colormap: thermal
          interpolate: true

  # Vertical profile
  - type: Axis
    position: [2, 1]
    attributes:
      xlabel: "Longitude"
      ylabel: "Temperature"
    plots:
      - type: lines
        args: [[1]]
        attributes:
          color: darkred
          linewidth: 3
```

## Dimension Indexing

The `args` field specifies which dimensions to display:

- `[[1, 2]]` - Display dimensions 1 and 2 (creates a 2D plot)
- `[[1]]` - Display dimension 1 only (creates a line plot)
- `[[1, 2, 3]]` - Display all three dimensions (creates a 3D plot)

Any remaining dimensions become interactive sliders in the UI.

## Colormap Options

Common colormaps:
- `viridis`, `plasma`, `inferno`, `magma` - Perceptually uniform
- `thermal`, `ice`, `solar` - Diverging
- `balance` - Symmetric around zero
- `matter`, `turbid` - Scientific
- See [ColorSchemes.jl](https://juliagraphics.github.io/ColorSchemes.jl/stable/) for more

## Tips

1. **Start simple**: Begin with a single axis and add complexity
2. **Test locally**: Use small data files while developing your config
3. **Check dimensions**: Use `ncdump -h file.nc` to see dimension names
4. **Layout ratios**: Use relative sizes (e.g., [0.7, 0.3]) not absolute pixels
