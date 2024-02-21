using Bonito, WGLMakie, NDViewer
# ] dev ../
# ] add Bonito#sd/widget-improvements MakieCore#sd/small-fixes Makie#sd/small-fixes WGLMakie#sd/small-fixes YAXArrays#master NetCDF DimensionalData#main
# ] add Tyler#master

function create_app_from_yaml(file)
    yaml_str = read(file, String)
    viewer = NDViewer.load_from_yaml(yaml_str)
    app = App() do
        editor = CodeEditor("yaml"; initial_source=yaml_str, width=300, height=600, foldStyle="manual")
        css = DOM.style("""
        .ace_scrollbar-v,
        .ace_scrollbar-h {
            display: none !important;
        }
        """)
        set_editor = js"""
            const editor = ace.edit($(editor.element))
            editor.setReadOnly(true);
        """
        yaml_display = DOM.div(css, Card(editor; width="fit-content"), set_editor)
        style = Styles("word-wrap" => "break-word")
        app_dom = Grid(
            yaml_display, viewer;
            justify_content="center",
            # align_items="center",
            style=Styles("grid-auto-flow" => "column")
        )
        return Centered(app_dom; style=Styles("width" => "100%"))
    end
    return app, viewer
end

app1, viewer = create_app_from_yaml(joinpath(@__DIR__, "speedyweather.yaml")); app1

# NDViewer.add_slice_view(viewer, 1, 1, 1, :black)

# NDViewer.add_slice_view(viewer, 1, 1, 2, :blue)

# app2, viewer = create_app_from_yaml(joinpath(@__DIR__, "speedyweather-tyler.yaml")); app2

# app3, viewer = create_app_from_yaml(joinpath(@__DIR__, "tas-gn-64gb.yaml")); app3
