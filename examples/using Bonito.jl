using Bonito
using DelimitedFiles
volcano = readdlm(Makie.assetpath("volcano.csv"), ',', Float64)
App() do
    f = contourf(volcano, levels=10; axis=(; title="normal"))
    f2 = contourf(volcano, levels=10; axis=(; title="resize_to=:parent"))
    r = WGLMakie.WithConfig(f2; resize_to=:parent)
    DOM.div(Grid(f, r; columns="50% 50%"); style=Styles("height" => "700px"))

end

using GeoMakie, GLMakie
fig = Figure()
ga = GeoAxis(
    fig[1, 1]; # any cell of the figure's layout
    dest="+proj=wintri", # the CRS in which you want to plot
)
lines!(ga, GeoMakie.coastlines()) # plot coastlines from Natural Earth as a reference
# You can plot your data the same way you would in Makie
scatter!(ga, -120:15:120, -60:7.5:60; color=-60:7.5:60, strokecolor=(:black, 0.2))
fig
