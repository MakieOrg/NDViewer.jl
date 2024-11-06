using HDF5, GLMakie, NDViewer
using LinearAlgebra


hydrodynamics = h5open(joinpath(@__DIR__, "Hydrodynamic.hdf5"), "r")
water_properties = h5open(joinpath(@__DIR__, "WaterProperties.hdf5"), "r")


wp_results = water_properties["Results"]

arr = map(["temperature_0000$i" for i in 1:9]) do name
    wp_results["temperature"][name][]
end
arr[1]
with_time = cat(arr...; dims=4)
x = with_time[1]
filtered = map(y -> x ≈ y ? NaN : y, with_time)

layout = [
    Dict(
        "type" => "Axis3",
        "position" => [1, 1],
        "plots" => [
            Dict(
                "type" => "volume",
                "args" => [[1, 2, 3]]
            )
        ]
    )
]

f = NDViewer.plot_data(filtered, layout)

grid = hydrodynamics["Grid"]
bathymetry = grid["Bathymetry"]
bathymetry["Maximum"][]
results = hydrodynamics["Results"]
velocity_u = results["velocity U"]
velocity_v = results["velocity V"]
velocity_w = results["velocity W"]
velocity_u_1 = velocity_u["velocity U_00001"]
velocity_v_1 = velocity_v["velocity V_00001"]
velocity_w_1 = velocity_w["velocity W_00001"]


u, v = velocity_u_1[][:, :, end], velocity_v_1[][:, :, end]

arrows(0..10, 0..10, velocity_u_1[][:, :, end], velocity_v_1[][:, :, end], arrowsize=0)

data = Vec3f.(velocity_u_1[], velocity_v_1[], velocity_w_1[])[1:5:end, 1:5:end, 1:5:end]
points = Point3f.(Tuple.(CartesianIndices(data)))
arrows(vec(points), vec(data), arrowsize=0.5, color=norm.(vec(data)))


layout = [
    Dict(
        "type" => "Axis",
        "position" => [1, 1],
        "plots" => [
            Dict(
                "type" => "linesegments",
                "args" => [[1, 2, 4 => 1], [1, 2, 4 => 2]]
            )
        ]
    )
]

u = velocity_u_1[]
v = velocity_v_1[]
data = [arr[i, j, t] for i in 1:size(u, 1), j in 1:size(u, 2), t in 1:size(u, 3), arr in (u, v)]

f = NDViewer.plot_data(data, layout)
