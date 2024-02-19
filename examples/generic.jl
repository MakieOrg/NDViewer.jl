using Bonito, WGLMakie, NDViewer
using NetCDF, YAXArrays
using DimensionalData
using Random

data_cube = Cube(joinpath(@__DIR__, "speedyweather.nc"))
layers = [
    Dict(
        "type" => heatmap,
        # "attributes" => Dict("colorrange" => colorrange),
        "args" => [[1, 2]],
    ),
    Dict(
        "type" => lines,
        "args" => [[1]],
        "attributes" => Dict("color" => "black")
    )
]


dd = data_cube = DimensionalData.modify(data_cube) do arr
    return convert(Array{Float32}, arr)
end

NDViewer.wgl_create_plot(dd, layers)


layers = [
    Dict(
        "type" => linesegments,
        "args" => [[1, 2, 5 => 5], [1, 2, 5 => 3]],
        "attributes" => Dict("color" => "black")
    )
]

linesegments(data_cube[:, :, 5, 10, 5], data_cube[:, :, 5, 10, 3])
NDViewer.wgl_create_plot(data_cube, layers)

using Zarr, DiskArrays
path = "gs://cmip6/CMIP6/ScenarioMIP/DKRZ/MPI-ESM1-2-HR/ssp585/r1i1p1f1/3hr/tas/gn/v20190710"
g = open_dataset(zopen(path; consolidated=true))

data_cube = DimensionalData.modify(g.tas) do arr
    return DiskArrays.CachedDiskArray(arr)
end
data = (data=data_cube,
    names=map(x -> name(x.dim), collect(axes(data_cube))));

layers = [Dict("type" => heatmap,
    "data" => [1, 2])]

# vec(view(data_cube, :, :, 1)) # fails on Makie#master because of this!

NDViewer.wgl_create_plot(data, layers)
