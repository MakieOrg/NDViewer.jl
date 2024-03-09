using Bonito, WGLMakie, NDViewer

app1 = NDViewer.create_app_from_yaml(joinpath(@__DIR__, "speedyweather.yaml")); app1

app2 = NDViewer.create_app_from_yaml(joinpath(@__DIR__, "speedyweather-tyler.yaml")); app2
app3 = NDViewer.create_app_from_yaml(joinpath(@__DIR__, "tas-gn-64gb.yaml")); app3

yaml = """
data:
  name: "data"
  path: "./dev/NDViewer/examples/speedyweather.nc"
layers:
  - figure:
      size: [1000, 1000]
  - type: Axis
    position: [1, 1]
    attributes:
      aspect: DataAspect
    plots:
      - type: mesh
        attributes:
          colormap: viridis
          color: {slice: [1, 2], data: "data"}
        args: [UnitSphere]
"""
app3 = NDViewer.create_app_from_yaml_str(yaml)
