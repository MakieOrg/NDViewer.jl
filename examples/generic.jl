using Bonito, WGLMakie, NDViewer, GeometryBasics
using NDViewer: yaml_viewer
yaml_path(name) = joinpath(@__DIR__, name)

app1 = yaml_viewer(yaml_path("speedyweather.yaml"))
app2 = yaml_viewer(yaml_path("speedy-volume.yaml"))
app3 = yaml_viewer(yaml_path("speedyweather-tyler.yaml"))
app4 = yaml_viewer(yaml_path("tas-gn-64gb.yaml"))
app5 = yaml_viewer(yaml_path("earth-sphere.yaml"))
