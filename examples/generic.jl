using Bonito, WGLMakie, NDViewer
using NetCDF, YAXArrays
using DimensionalData

data_cube = Cube(joinpath(@__DIR__, "speedyweather.nc"))

layers = [
    Dict(
        "type" => heatmap,
        # "attributes" => Dict("colorrange" => colorrange),
        "data" => [1, 2]
    )
]
data = (data=data_cube,
    names=map(x -> name(x.dim), collect(axes(data_cube))));

NDViewer.wgl_create_plot(data, layers)


using Zarr, DiskArrays
path = "gs://cmip6/CMIP6/ScenarioMIP/DKRZ/MPI-ESM1-2-HR/ssp585/r1i1p1f1/3hr/tas/gn/v20190710"
g = open_dataset(zopen(path; consolidated=true))

data_cube = DimensionalData.modify(g.tas) do arr
    return DiskArrays.CachedDiskArray(arr)
end
vec(view(data_cube, :, :, 1))
data = (data=data_cube,
    names=map(x -> name(x.dim), collect(axes(data_cube))));

layers = [Dict("type" => heatmap,
    "data" => [1, 2])]

# vec(view(data_cube, :, :, 1)) # fails on Makie#master because of this!

NDViewer.wgl_create_plot(data, layers)
