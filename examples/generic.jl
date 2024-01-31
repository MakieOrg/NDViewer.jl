using YAXArrays, GLMakie, NDViewer, LinearAlgebra
using YAXArrays, NetCDF
using DimensionalData
data_cube = Cube(joinpath(@__DIR__, "speedyweather.nc"))
vars = collect(data_cube.Variable)
x = convert(Array{Float32}, data_cube.data)
data_cube
temperature = convert(Array{Float32}, data_cube[Variable=At("temp")].data)
cubef32 = convert(Array{Float32}, data_cube.data);
u = data_cube[:, :, :, :, 3][:, :, :, end]
v = data_cube[:, :, :, :, 5][:, :, :, end]

ps = [Point3f(lat, lon, lev) for lat in u.lat, lon in u.lon, lev in u.lev]
dirs = vec(Point2f.(u, v))

function to_segments(ps::AbstractArray{T}, dirs) where T
    result = T[]
    for (p, d) in zip(ps, dirs)
        push!(result, p)
        push!(result, p .+ to_ndim(T, d, 0))
    end
    return result
end

linesegments(to_segments(ps, dirs./10), color=norm.(vec(Point2f.(u, v))), linewidth=0.5; axis=(;type=Axis3,))

data = (
    data=cubef32,
    names=map(x -> name(x.dim), collect(axes(data_cube))),
);

layers = [
    Dict(
        "type" => volume,
        "data" => ([1, 2, 3],),
    ),
    Dict(
        "type" => heatmap,
        "data" => ([1, 2],),
    )
    Dict(
        "type" => arrows,
        "data" => ((5 => 3) => [1, 2, 5 => 3], (5 => 5) => [1, 2],),
    )
]

NDViewer.plot_data(data, layers)


("temperature" => ([1]))

using Dates
axlist = (
    Dim{:tempo}(Date("2022-01-01"):Day(1):Date("2022-01-30")),
    Dim{:lon}(range(1, 10, length=10)),
    Dim{:lat}(range(1, 5, length=15)),
    Dim{:level}(range(1, 7, length=7)),
    Dim{:variable}(["var1", "var2"])
)

data = rand(30, 10, 15, 7, 2)
ds = YAXArray(axlist, data)
