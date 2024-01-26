using YAXArrays, GLMakie, NDViewer
using YAXArrays, NetCDF
using DimensionalData
data_cube = Cube(joinpath(@__DIR__, "speedyweather.nc"))
vars = collect(data_cube.Variable)

temperature = convert(Array{Float32}, data_cube[Variable=At("temp")].data)

data = (
    data=temperature,
    names=["x", "y", "z", "time"],
);

layers = [
    Dict(
        "type" => volume,
        "data" => [1, 2, 3],
    ),
    Dict(
        "type" => heatmap,
        "data" => [1, 2],
    )
]

NDViewer.plot_data(data, layers)
