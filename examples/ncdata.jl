using YAXArrays, GLMakie, NDViewer
using YAXArrays, NetCDF
using DimensionalData

data = Cube(joinpath(@__DIR__, "speedyweather.nc"))
vars = collect(data.Variable)

temp = data[Variable=At("temp")]
tempdata = convert(Array{Float32}, temp.data)

NDViewer.create_plot(tempdata)
