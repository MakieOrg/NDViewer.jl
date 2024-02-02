using YAXArrays, GLMakie, NDViewer, LinearAlgebra
using YAXArrays, NetCDF
using DimensionalData, Zarr
using DiskArrays
data_cube = Cube("speedyweather.nc")
path = ("gs://cmip6/CMIP6/ScenarioMIP/DKRZ/MPI-ESM1-2-HR/ssp585/r1i1p1f1/3hr/tas/gn/v20190710")
g = open_dataset(zopen(path, consolidated=true))

data_cube = DimensionalData.modify(g.tas) do arr
    DiskArrays.CachedDiskArray(arr)
end
data = (
    data=data_cube,
    names=map(x -> name(x.dim), collect(axes(data_cube))),
);

layers = [
    Dict(
        "type" => heatmap,
        "data" => [1, 2],
    )
]

NDViewer.plot_data(data, layers)


args = (data_cube[:, :, 1],)
extremata = map(Makie.extrema_nan, [args...])
mini = reduce((a, x) -> Base.min(a, x[1]), extremata; init=Inf)
maxi = reduce((a, x) -> Base.max(a, x[2]), extremata; init=-Inf)
if mini .- maxi ≈ 0
    mini = mini .- 0.5
    maxi = maxi .+ 0.5
end
@show mini maxi
return Vec2f(mini, maxi)


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
