# NDViewer

[![Build Status](https://github.com/SimonDanisch/NDViewer.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/SimonDanisch/NDViewer.jl/actions/workflows/CI.yml?query=branch%3Amain)

* Usage for large simulation or any other use case that generates lots of 2d-4d data (satelites, neuro imaging, etc)
& Drag & Drop HDF5 or NetCDF files (or any other multi dimensional array format that we can read in Julia) and get simple UI to select columns and visual styles
* Offer UI for simple usage, but expose all functionality programmatically as well
* be able to add any other makie plot to viewer programmatically
* All functionality is exposed via very simple plugins, which anyone can extent (e.g. offering surface plot of the data in the viewer is a plugin, slicing dims with a slider is one as well. E.g. a user could add a Tyler.jl plugin, to be able to plot maps on top of data).
* Have sliders to select slice or step through time
* Work with large time series of 2d/3d data (terabytes if streaming)
* One click export of movies animating selected time/slice
* Executable that runs on windows/linux/osx, or stream data to WGLMakie in browser
