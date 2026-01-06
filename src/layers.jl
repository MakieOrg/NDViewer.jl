
function match_dims(m, target)
    # same
    m == target && return -1000
    na = length(m)
    nb = length(target)
    # permutation
    na == nb && all(x -> x in m, target) && return -900
    # ready to slice
    nb == na - 1 && m[1:nb] == target && return -800
    if all(x -> x in m, target)
        i = 0
        for (x, y) in zip(m, target)
            if x == y
                i -= 1
            else
                i += 1
            end
        end
        return (i + length(m)) # penalize by length
    else
        return 9000
    end
    # no match
end

# TODO, fix the stackoverflow
function get_dims!(arrays::Dict, widgets, target_dims::Vector{Int}, names::Vector{String})
    available = collect(keys(arrays))
    if target_dims in available
        return
    end
    sort!(available; by=x -> match_dims(x, target_dims))
    closest = first(available)
    input_data = arrays[closest]
    if any(x -> x > maximum(closest), target_dims)
        throw(ArgumentError("target_dims must be a subset of the dimensions of data. Found: $(target_dims) in $(closest)"))
    elseif length(closest) == length(target_dims)
        data = map(x -> permutedims(x, (target_dims...,)), input_data)
        arrays[target_dims] = data
        return
    elseif length(closest) == length(target_dims) + 1
        # if closest is one dimension larger than target_dims, we can slice
        dim_to_slice = only(setdiff(closest, target_dims))
        real_dim_to_slice = findfirst(isequal(dim_to_slice), closest)
        name = names[dim_to_slice]
        data, widget = slice_dim(input_data, real_dim_to_slice, name)
        widgets[name] = widget
        new_dims = filter(x -> x != dim_to_slice, target_dims)
        arrays[new_dims] = data
        return
    else
        missing_dims = sort(setdiff(closest, target_dims))
        new_target_dims = filter(x -> x != missing_dims[end], closest)
        get_dims!(arrays, widgets, convert(Vector{Int}, new_target_dims), names)
        return get_dims!(arrays, widgets, target_dims, names)
    end
end

function plot_data(data, layers; figure=(;))
    f, slices, widgets, axes = create_plot(data, layers; figure=figure)
    sub = f[end + 1, :]
    for (i, w) in enumerate(values(widgets))
        widget(sub[i, :], w)
    end
    return f
end


accessor2dim(x::Dict) = Int(first(x)[1])
accessor2dim(x::Pair{Int,T}) where {T} = Int(x[1])
accessor2dim(x::Integer) = Int(x)

dim2accessor(x::Dict) = Int(first(x)[2])
dim2accessor(x::Pair{Int,T}) where {T} = x[2]
dim2accessor(::Integer) = (:)

function get_colorrange(used_data)
    last_min, last_max = Inf, -Inf
    colorrange = lift(used_data...) do args...
        extremata = map(Makie.extrema_nan, [args...])
        mini = reduce((a, x) -> Base.min(a, x[1]), extremata; init=Inf)
        maxi = reduce((a, x) -> Base.max(a, x[2]), extremata; init=-Inf)
        if mini .- maxi ≈ 0
            mini = mini .- 0.5
            maxi = maxi .+ 0.5
        end
        mini = min(last_min, mini)
        maxi = max(last_max, maxi)
        last_min = mini
        last_max = maxi
        return Vec2f(mini, maxi)
    end
    return colorrange
end


function create_slices(layers, data::AbstractArray)
    input_data = convert(Observable, data)

    names = get_dim_names(input_data[])
    dims = collect(1:ndims(input_data[]))

    sliced_arrays = Dict{Vector{Any},Observable}(dims => input_data)
    widgets = Dict{String,Any}()

    slices = []
    for axlayer in layers
        for layer in axlayer["plots"]
            for arg in layer["args"]
                push!(slices, Int[accessor2dim(a) for a in arg])
            end
        end
    end
    sort!(slices; by=length, rev=true)
    for slice in slices
        get_dims!(sliced_arrays, widgets, slice, names)
    end

    return sliced_arrays, widgets
end

function access2slice(sliced_arrays, arg::Vector)
    # unwrap something like [1, 2=>3] to [1, 2]
    flat = map(accessor2dim, arg)
    # get the array slice for the flat dims
    # Should be guaranteed to exist, as long as create_slices was called on the same args before
    array_slice_obs = sliced_arrays[flat]
    # Now, apply the `=>` parts (if any existed) and cache it in sliced_arrays
    return get!(sliced_arrays, arg) do
        map(arr -> view(arr, map(dim2accessor, arg)...), array_slice_obs)
    end
end

function replace_slices(sliced_arrays, args::Vector{<:Vector})
    return map(args) do arg
        access2slice(sliced_arrays, arg)
    end
end

function replace_slices(sliced_arrays, attributes::Dict)
    return Dict{Symbol, Any}(map(collect(attributes)) do (k, value)
        if value isa Dict && haskey(value, "slice")
            value = access2slice(sliced_arrays, value["slice"])
        end
        return Symbol(k) => value
    end)
end

function layer_to_plot!(ax::Makie.AbstractAxis, sliced_arrays, dict, fcolor, cmaps)
    plotfunc = resolve_symbol(dict["type"])
    args = map(replace_slices(sliced_arrays, dict["args"])) do vals
        if vals isa Observable && to_value(vals) isa AbstractArray
            return lift(Array, vals)
        else
            return vals
        end
    end
    attr = get(dict, "attributes", Dict())
    attributes = replace_slices(sliced_arrays, attr)
    if (plotfunc in (heatmap, image, surface, volume)) || dict["type"] == "sphereplot"
        crange = get(attributes, :colorrange, nothing)
        if crange === nothing
            cmap_slice = last(dict["args"])
            colormaps = get!(cmaps, cmap_slice) do
                idx = length(cmaps)
                crange = map(Makie.extrema_nan, last(args))
                colormap_widget(fcolor[idx+1, 1], crange)
            end
            for (k, v) in pairs(colormaps)
                attributes[k] = v
            end
        end
    end
    Makie._create_plot!(plotfunc, attributes, ax, args...)
end

using Tyler, MapTiles

function project(p)
    p = p .- Point2f(180, 0)
    Point2f(MapTiles.project(p, MapTiles.wgs84, MapTiles.web_mercator))
end
resolve_symbol(s) = s
function resolve_symbol(s::String)
    name = Symbol(s)
    if name == :DataAspect
        return DataAspect()
    end
    if hasproperty(Makie, name)
        return getfield(Makie, name)
    elseif hasproperty(NDViewer, name)
        return getfield(NDViewer, name)
    else
        return s
    end
end

"""
    create_autolimits_toggle!(figpos, ax, data_observables; initial=true)

Create a small toggle button overlaid on the axis that controls autolimits behavior.
When enabled (default), calls `autolimits!(ax)` whenever any data observable updates.
The button appears in the top-right corner of the axis.
"""
function create_autolimits_toggle!(figpos, ax, data_observables; initial::Bool=true)
    autolimits_enabled = Observable(initial)

    # Button styling - clear visual difference between on/off states
    # ON: blue background, white text
    # OFF: light gray background, dark gray text
    buttoncolor = lift(autolimits_enabled) do enabled
        enabled ? RGBAf(0.2, 0.55, 0.85, 1.0) : RGBAf(0.85, 0.85, 0.85, 1.0)
    end
    labelcolor = lift(autolimits_enabled) do enabled
        enabled ? RGBAf(1, 1, 1, 1) : RGBAf(0.4, 0.4, 0.4, 1.0)
    end

    # Create button in a Box overlay at top-right with margin using alignmode
    btn = Makie.Button(figpos;
        label="Auto",
        buttoncolor=buttoncolor,
        buttoncolor_hover=lift(e -> e ? RGBAf(0.3, 0.65, 0.95, 1.0) : RGBAf(0.75, 0.75, 0.75, 1.0), autolimits_enabled),
        buttoncolor_active=lift(e -> e ? RGBAf(0.15, 0.45, 0.75, 1.0) : RGBAf(0.65, 0.65, 0.65, 1.0), autolimits_enabled),
        labelcolor=labelcolor,
        fontsize=10,
        cornerradius=3,
        padding=(4, 4, 2, 2),
        halign=:right,
        valign=:top,
        tellwidth=false,
        tellheight=false,
        alignmode=Mixed(right=5, top=5),
    )

    # Toggle on click
    on(btn.clicks) do _
        autolimits_enabled[] = !autolimits_enabled[]
        if autolimits_enabled[]
            autolimits!(ax)
        end
    end

    # Call autolimits when data changes (if enabled)
    for obs in data_observables
        on(obs) do _
            if autolimits_enabled[]
                autolimits!(ax)
            end
        end
    end

    return autolimits_enabled, btn
end

function layer_to_axis!(fig, sliced_arrays, dict, fcolor, cmaps)
    AxType = resolve_symbol(dict["type"])
    ax_attr = [Symbol(k) => resolve_symbol(v) for (k, v) in get(dict, "attributes", [])]
    pos = get(dict, "position", [1, 1])
    # Get autolimits config from YAML, default to true
    autolimits_initial = get(dict, "autolimits", true)

    if AxType == "Tyler"
        ax = Axis(fig[pos...])
        hidedecorations!(ax)
        pfig = Makie.get_figure(fig)
        ax_attr = map(ax_attr) do (k, v)
            if k == :provider
                return :provider => getfield(Tyler.TileProviders, Symbol(v))()
            end
            return k => v
        end
        tmap = Tyler.Map(Rect2f(-175, -50, 350, 100); axis=ax, figure=pfig, ax_attr...)
        trans = Transformation(Makie.PointTrans{2}(project))
        plots = map(dict["plots"]) do plot
            attr = get!(plot, "attributes", Dict())
            attr["transformation"] = trans
            layer_to_plot!(ax, sliced_arrays, plot, fcolor, cmaps)
        end
        # Tyler maps handle their own limits, no autolimits toggle
        return (ax, plots, nothing)
    else
        # For regular Axis with autolimits, use :max_auto tick spacing to prevent jitter
        if AxType == Axis && autolimits_initial
            ax = AxType(fig[pos...]; xticklabelspace=:max_auto, yticklabelspace=:max_auto, ax_attr...)
        else
            ax = AxType(fig[pos...]; ax_attr...)
        end
        plots = map(dict["plots"]) do plot
            layer_to_plot!(ax, sliced_arrays, plot, fcolor, cmaps)
        end

        # Collect data observables from sliced_arrays that this axis uses
        data_obs = collect_data_observables(sliced_arrays, dict)

        # Create autolimits toggle button overlaid on axis
        autolimits_toggle = nothing
        if ax isa Axis && !isempty(data_obs)
            autolimits_toggle, _ = create_autolimits_toggle!(fig[pos...], ax, data_obs; initial=autolimits_initial)
        end

        return (ax, plots, autolimits_toggle)
    end
end

"""
Collect Observable data arrays used by the plots in this axis definition.
The sliced_arrays dict has keys like [1, 2] (dimension indices) mapping to Observables.
Plot args in the YAML reference these as [[1, 2]] etc.
"""
function collect_data_observables(sliced_arrays, axis_dict)
    observables = Observable[]
    for plot in get(axis_dict, "plots", [])
        for arg in get(plot, "args", [])
            # arg is like [1, 2] which is used as a key in sliced_arrays
            if arg isa Vector && haskey(sliced_arrays, arg)
                obs = sliced_arrays[arg]
                if obs isa Observable
                    push!(observables, obs)
                end
            end
        end
    end
    return unique(observables)
end

function remove_dicts!(f, dicts)
    result = []
    filter!(dicts) do dict
        if dict isa Dict
            if f(dict)
                push!(result, dict)
                return false
            end
        end
        return true
    end
    return result
end

function create_plot(data, layers; figure=(;))
    layers = copy(layers)
    figure_kw = remove_dicts!(x -> haskey(x, "figure"), layers)
    if length(figure_kw) == 1
        figure_kw = first(figure_kw)
        f_kw = map(collect(figure_kw["figure"])) do (k, v)
            k == "size" && return :size => (v...,)
            return Symbol(k) => v
        end
    else
        f_kw = figure
    end
    # Use smaller figure padding and no row gaps to reduce whitespace
    f = Figure(; figure_padding=(5, 5, 5, 5), rowgap=0, f_kw...)
    fplots = f[1, 1]
    fcbar = f[2, 1]
    fcolor = f[3, 1]
    layouts = remove_dicts!(x-> haskey(x, "layout"), layers)
    sliced_arrays, widgets = create_slices(layers, data)
    cmaps = Dict()
    axes = map(layers) do axlayer
        layer_to_axis!(fplots, sliced_arrays, axlayer, fcolor, cmaps)
    end
    gridlayout = fplots.layout.content[1].content
    for layout in layouts
        layout = layout["layout"]
        if haskey(layout, "rowsize")
            for (i, row) in enumerate(layout["rowsize"])
                rowsize!(gridlayout, i, Auto(row))
            end
        elseif haskey(layout, "colsize")
            for (i, row) in enumerate(layout["colsize"])
                colsize!(gridlayout, i, Auto(row))
            end
        end
    end
    for (i, colormaps) in enumerate(values(cmaps))
        cmap_attr = Base.structdiff(colormaps, (; nan_color=0, alpha=0))
        Colorbar(fcbar[i, 1]; vertical=false, tellheight=true, tellwidth=true, cmap_attr...)
    end
    return f, sliced_arrays, widgets, axes
end


struct DataViewerApp
    layers
    data
    figure
    slices
    widgets
    axes
end

using WGLMakie

function Bonito.jsrender(session::Session, viewer::DataViewerApp)
    f = viewer.figure
    data = viewer.data
    widgets = viewer.widgets
    names = get_dim_names(to_value(data))

    # Collect widgets in order
    widget_list = [widgets[n] for n in names if haskey(widgets, n)]

    # Wrap widgets in a styled container, centered
    widgets_container = DOM.div(
        widget_list...;
        class="ndviewer-widgets"
    )

    # Wrap figure with resize_to=:parent for responsive sizing
    figure_with_resize = WGLMakie.WithConfig(f; resize_to=:parent, use_html_widgets=false)

    # Figure container - fills remaining space after widgets
    figure_container = DOM.div(
        figure_with_resize;
        style=Styles(
            "flex" => "1",
            "min-height" => "0",
            "width" => "100%",
        )
    )

    # Main layout: widgets on top, figure fills rest
    dom = DOM.div(
        NDVIEWER_STYLES,
        DOM.div(
            widgets_container;
            style=Styles(
                "display" => "flex",
                "justify-content" => "center",
                "padding" => "4px 0",
            )
        ),
        figure_container;
        style=Styles(
            "display" => "flex",
            "flex-direction" => "column",
            "width" => "100%",
            "height" => "100vh",
            "overflow" => "hidden",
        )
    )
    return Bonito.jsrender(session, dom)
end

function wgl_create_plot(data, layers)
    f, slices, widgets, axes = create_plot(data, layers)
    return DataViewerApp(layers, data, f, slices, widgets, axes)
end

function Base.display(viewer::DataViewerApp)
    app = App(viewer; title="DataViewer")
    display(app)
end

function add_index_slice(axis::Makie.AbstractAxis, plot, index_obs, dim, color)
    dim_data = dim == 2 ? plot.y : plot.x
    dim_slice = map(getindex, dim_data, index_obs)
    plot = if dim == 1
        vlines!(axis, dim_slice; color=(color, 0.5), linewidth=2)
    else
        hlines!(axis, dim_slice; color=(color, 0.5), linewidth=2)
    end
    pix_points = map(dim_slice) do num
        p = Makie.project(axis.scene, dim == 2 ? Point2f(0, num) : Point2f(num, 0))
        mini = minimum(axis.scene.viewport[])
        maxi = maximum(axis.scene.viewport[])
        return [dim == 2 ? Point2f(maxi[1], mini[2] + p[2]) : Point2f(mini[1] + p[1], maxi[2])]
    end
    scatter!(axis.blockscene, pix_points; color=color, space=:pixel, markersize=20, marker=:circle, strokecolor=:black, strokewidth=2)
    return plot
end

function add_slice_view(viewer, axis, plot, dim, color)
    name = NDViewer.get_dim_names(viewer.data)[dim]
    ax, plots = viewer.axes[axis]
    widget = viewer.widgets[name]
    add_index_slice(ax, plots[plot], widget.value, dim, color)
end
