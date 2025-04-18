using YAML, YAXArrays, NetCDF, HDF5, Zarr, DiskArrays

const GLOBAL_DATA = Dict{String, Any}()

function load_data(data_path::String)
    get!(GLOBAL_DATA, data_path) do
        if endswith(data_path, ".nc")
            cube = Cube(data_path)
            return DimensionalData.modify(cube) do arr
                return convert(Array{Float32}, arr)
            end
        elseif startswith(data_path, "gs://cmip6/CMIP6")
            # We defenitely shouldnt hardcode this for a demo :D
            g = YAXArrays.open_dataset(zopen(data_path; consolidated=true))
            data_cube = DimensionalData.modify(g.tas) do arr
                return DiskArrays.CachedDiskArray(arr)
            end
            return data_cube
        elseif endswith(data_path, ".hdf5")
            h5open(data_path, "r")
        else
            error("Path not recognized: $(data_path)")
        end
    end
end

function load_from_yaml(yaml_str)
    data = YAML.load(yaml_str)
    if !haskey(data, "data")
        error("YAML needs to have a \"data\" key")
    end
    if !haskey(data, "layers")
        error("YAML needs to have a \"layers\" key")
    end

    data_path = data["data"]["path"]
    data_cube = load_data(data_path)
    layers = data["layers"]
    wgl_create_plot(data_cube, layers)
end


function yaml_viewer(file)
    yaml_str = read(file, String)
    create_app_from_yaml(yaml_str)
end

function create_app_from_yaml(yaml_str)
    return App() do
        viewer = NDViewer.load_from_yaml(yaml_str)
        editor = CodeEditor("yaml"; initial_source=yaml_str, width=300, height=600, readOnly=true, foldStyle="manual")
        css = DOM.style("""
        .ace_scrollbar-v,
        .ace_scrollbar-h {
            display: none !important;
        }
        """)

        yaml_display = DOM.div(css, Card(editor; width="fit-content"))
        app_dom = Grid(
            yaml_display, viewer;
            justify_content="center",
            # align_items="center",
            style=Styles("grid-auto-flow" => "column")
        )
        return Centered(app_dom; style=Styles("width" => "100%"))
    end
end
