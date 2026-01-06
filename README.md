# NDViewer.jl

[![Build Status](https://github.com/MakieOrg/NDViewer.jl/workflows/CI/badge.svg)](https://github.com/MakieOrg/NDViewer.jl/actions)

**NDViewer** is an interactive N-dimensional array viewer with a modern, polished web interface. Built on [Makie.jl](https://docs.makie.org) and [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl), it provides powerful visualization tools for exploring multi-dimensional scientific datasets.

## Features

✨ **Interactive Slicing** - Navigate through dimensions with animated play sliders
📝 **YAML Configuration** - Define complex visualizations declaratively
🎨 **Modern UI** - Clean, professional styling with responsive design
🗺️ **Geographic Data** - Tyler.jl integration for map overlays
⚡ **WebGL Rendering** - Fast, GPU-accelerated visualization
📊 **Multiple Plot Types** - Heatmaps, surfaces, volumes, lines, and more
🏷️ **Labeled Arrays** - Full DimensionalData.jl support

## Quick Start

```julia
using NDViewer, WGLMakie

# Create sample 3D data
data = rand(100, 100, 50)

# Define visualization
layers = [
    Dict("figure" => Dict("size" => [800, 600])),
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "plots" => [Dict("type" => "image", "args" => [[1, 2]])]
    )
]

# Create and display viewer
viewer = NDViewer.wgl_create_plot(data, layers)
display(viewer)
```

## YAML Configuration

For complex setups, use declarative YAML:

```yaml
data:
  path: "./temperature_data.nc"
layers:
  - figure:
      size: [1000, 800]
  - type: Axis
    position: [1, 1]
    plots:
      - type: heatmap
        args: [[1, 2]]
        attributes:
          colormap: thermal
```

Load with: `app = NDViewer.yaml_viewer("config.yaml")`

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/MakieOrg/NDViewer.jl")
```

## Goals

* Usage for large simulation or any other use case that generates lots of 2d-4d data (satellites, neuro imaging, etc.)
* Drag & Drop HDF5 or NetCDF files and get simple UI to select columns and visual styles
* Offer UI for simple usage, but expose all functionality programmatically as well
* All functionality is exposed via very simple plugins, which anyone can extend
* Have sliders to select slice or step through time
* Do analytics on data slices and display interactive overview plots
* Work with large time series of 2d/3d data (terabytes if streaming)
* One click export of movies animating selected time/slice
* Executable that runs on windows/linux/osx, or stream data to WGLMakie in browser

### NDViewer with SpeedyWeather Dataset and slices 
[![image](https://github.com/MakieOrg/NDViewer.jl/assets/1010467/31917161-8c8d-4b8f-a592-62ea2a0090db)](https://www.youtube.com/watch?v=kOVuiXnfF1o)

### NDViewer with SpeedyWeather on top of Tyler.jl
[![image](https://github.com/MakieOrg/NDViewer.jl/assets/1010467/8c17f76d-6372-4ba4-9b81-5df6bcefdd3a)](https://youtu.be/_6EpHnwRyHo)

### NDViewer with a 64gb cloud Dataset
[![image](https://github.com/MakieOrg/NDViewer.jl/assets/1010467/c75376ca-be66-44ec-bc12-589acb4a10c2)](https://www.youtube.com/watch?v=eHeZNPTANIQ)
