# NDViewer

## Current Prototype

* Supports loading any YAXArray.jl
* Simple YAML syntax for slices and plots, which can be targeted from A UI to create viewer for a dataset
* Makie plots and axes as plug-ins with attributes and arguments
* Simple Tyler.jl plug-in prototype 
* Rudementary UI and layout for viewing slices with Colorbar 

## Goals 

* Usage for large simulation or any other use case that generates lots of 2d-4d data (satellites, neuro imaging, etc.)
* Drag & Drop HDF5 or NetCDF files (or any other multi dimensional array format that we can read in Julia) and get simple UI to select columns and visual styles
* Offer UI for simple usage, but expose all functionality programmatically as well
* Be able to add any other Makie plot to viewer programmatically
* All functionality is exposed via very simple plugins, which anyone can extent (e.g. offering surface plot of the data in the viewer is a plugin, slicing dims with a slider is one as well. E.g. a user could add a Tyler.jl plugin, to be able to plot maps on top of data).
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
