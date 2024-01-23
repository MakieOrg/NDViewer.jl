using HDF5, GLMakie
using LinearAlgebra


hydrodynamics = h5open("Hydrodynamic.hdf5", "r")
water_properties = h5open("WaterProperties.hdf5", "r")


wp_results = water_properties["Results"]

arr = map(["temperature_0000$i" for i in 1:9]) do name
    wp_results["temperature"][name][]
end
arr[1]
with_time = cat(arr...; dims=4)
x = with_time[1]
filtered = map(y -> x ≈ y ? NaN : y, with_time)
filtered0 = map(y -> x ≈ y ? 0f0 : y, tmp1)
create_plot(filtered)

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


data = Vec3f.(velocity_u_1[], velocity_v_1[], velocity_w_1[])[1:5:end, 1:5:end, 1:5:end]
points = Point3f.(Tuple.(CartesianIndices(data)))
arrows(vec(points), vec(data), arrowsize=0.5, color=norm.(vec(data)))

vec(points)
vec(points)[1:5:end]

f = Figure()
s = Slider(f[1, 1], range=range(mini, maxi, length=100))
volume(f[2, 1], data, algorithm=:iso, isovalue=s.value)

img = map(x-> RGBf.(x...), data)
volume(img, colormap=nothing, color=nothing)
heatmap(norm.(data[:, :, 5]))
begin
    f = Figure()
    uv = Vec2f.(velocity_u_1[], velocity_v_1[])
    s = Slider(f[2, 1], range=1:size(uv, 3))
    swidth = Slider(f[3, 1], range=1:10)
    uv_mat = map(s.value, swidth.value) do idx, w
        vec(uv[1:w:end, 1:w:end, idx])
    end
    uv_vec = map(vec, uv_mat)
    color = map(x-> norm.(x), uv_vec)
    points = map(uv_mat) do uv
        x = LinRange(1, 100, size(uv, 1)); y = LinRange(1, 100, size(uv, 2))
        vec(Point2f.(x, y'))
    end
    arrows(f[1, 1], points, uv_vec, color=color)
    f
end

begin
    f = Figure()
    uv = Vec3f.(velocity_u_1[], velocity_v_1[], velocity_w_1[])
    s = Slider(f[2, 1], range=1:size(uv, 3))
    swidth = Slider(f[3, 1], range=1:10)
    uv_mat = map(s.value, swidth.value) do idx, w
        vec(uv[1:w:end, 1:w:end, idx])
    end
    uv_vec = map(vec, uv_mat)
    color = map(x -> norm.(x), uv_vec)
    points = map(uv_mat) do uv
        x = LinRange(1, 100, size(uv, 1))
        y = LinRange(1, 100, size(uv, 2))
        z = LinRange(1, 100, size(uv, 3))
        vec(uv)
    end
    arrows(f[1, 1], points, uv_vec, color=color)
    f
end
