using YAXArrays, GLMakie, NDViewer
using YAXArrays, NetCDF
using DimensionalData
data_cube = Cube(joinpath(@__DIR__, "speedyweather.nc"))
vars = collect(data_cube.Variable)

temperature = convert(Array{Float32}, data_cube[Variable=At("temp")].data)

data = (data=temperature,
        names=["x", "y", "z", "time"]);

layers = [Dict("type" => volume,
               "data" => [1, 2, 3]),
          Dict("type" => heatmap,
               "data" => [1, 2])]

NDViewer.plot_data(data, layers)

using YAXArrays, WGLMakie, NDViewer
using Zarr, DiskArrays
using DimensionalData
path = "gs://cmip6/CMIP6/ScenarioMIP/DKRZ/MPI-ESM1-2-HR/ssp585/r1i1p1f1/3hr/tas/gn/v20190710"
g = open_dataset(zopen(path; consolidated=true))

data_cube = DimensionalData.modify(g.tas) do arr
    return DiskArrays.CachedDiskArray(arr)
end

data = (data=data_cube,
        names=map(x -> name(x.dim), collect(axes(data_cube))));

layers = [Dict("type" => heatmap,
               "data" => [1, 2])]

NDViewer.wgl_create_plot(data, layers)
