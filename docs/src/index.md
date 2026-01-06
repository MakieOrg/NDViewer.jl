# NDViewer.jl

**NDViewer** is an interactive multi-dimensional array viewer built on [Makie.jl](https://docs.makie.org) and [Bonito.jl](https://github.com/SimonDanisch/Bonito.jl). It provides a polished, modern web interface for exploring and visualizing N-dimensional datasets.

## Features

- **Interactive Slicing**: Navigate through dimensions with animated play sliders
- **YAML Configuration**: Define complex visualizations declaratively
- **Multiple Plot Types**: Support for heatmaps, images, surfaces, volumes, lines, and more
- **Geographic Data**: Tyler.jl integration for map overlays
- **Modern UI**: Clean, professional styling with customizable themes
- **WebGL Rendering**: Fast, GPU-accelerated visualization via WGLMakie

## Quick Start

```julia
using NDViewer, WGLMakie

# Create a 3D test dataset
data = rand(100, 100, 50)

# Define visualization layers
layers = [
    Dict("figure" => Dict("size" => [800, 600])),
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "attributes" => Dict("aspect" => "DataAspect"),
        "plots" => [
            Dict(
                "type" => "image",
                "args" => [[1, 2]],
                "attributes" => Dict("colormap" => "viridis")
            )
        ]
    )
]

# Create and display the viewer
viewer = NDViewer.wgl_create_plot(data, layers)
display(viewer)
```

## Installation

NDViewer is not yet registered. Install from the repository:

```julia
using Pkg
Pkg.develop(url="https://github.com/MakieOrg/NDViewer.jl")
```

## Dependencies

- **Makie.jl**: Core plotting library
- **Bonito.jl**: Web UI framework
- **DimensionalData.jl**: Labeled array support
- **YAXArrays.jl**: NetCDF/Zarr data loading
- **Tyler.jl**: Geographic tile maps

## License

MIT License - see LICENSE file for details.
