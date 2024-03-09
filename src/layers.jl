
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
    size = get(figure, :size, (1200, 800))
    f = Figure(; figure..., size=size)
    fcolor = f[1, 1]
    fplots = f[2, 1]
    slices, widgets, colorrange = create_slices(layers, data)
    colormaps = colormap_widget(fcolor, colorrange)
    slices, widgets = create_plot(fplots, slices, colormaps)
    return
end

resolve_symbol(s) = s
function resolve_symbol(s::String)
    name = Symbol(s)
    if name == :DataAspect
        return DataAspect()
    end
    if hasproperty(Makie, name)
        return getfield(Makie, name)
    else
        return s
    end
end


accessor2dim(x::Dict) = Int(first(x)[1])
accessor2dim(x::Pair) where {T} = Int(x[1])
accessor2dim(x::Integer) = Int(x)

dim2accessor(x::Dict) = Int(first(x)[2])
dim2accessor(x::Pair) where {T} = x[2]
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
            for args in layer["args"]
                for arg in args
                    result = accessor2dim(arg)
                    if !isnothing(result)
                        push!(slices, result)
                    end
                end
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

        if value isa Dict
            if haskey(value, "slice")
                value = access2slice(sliced_arrays, value["slice"])
            end
            if haskey(value, "julia_type")
                value = eval(Meta.parse(value["julia_type"]))
            end
        end
        return Symbol(k) => value
    end)
end

function layer_to_plot!(ax::Makie.AbstractAxis, sliced_arrays, dict, fcolor, cmaps)
    plotfunc = resolve_symbol(dict["type"])
    args = replace_slices(sliced_arrays, dict["args"])
    attr = get(dict, "attributes", Dict())
    attributes = replace_slices(sliced_arrays, attr)
    if plotfunc in (heatmap, image, surface)
        crange = get(attributes, :colorrange, nothing)
        if crange === nothing
            crange = map(Makie.extrema_nan, last(args))
            idx = length(cmaps)
            colormaps = colormap_widget(fcolor[idx+1, 1], crange)
            push!(cmaps, colormaps)
            for (k, v) in pairs(colormaps)
                attributes[k] = v
            end
        end
    end
    Makie.MakieCore._create_plot!(plotfunc, attributes, ax, args...)
end

using Tyler, MapTiles

function project(p)
    p = p .- Point2f(180, 0)
    Point2f(MapTiles.project(p, MapTiles.wgs84, MapTiles.web_mercator))
end

function layer_to_axis!(fig, sliced_arrays, dict, fcolor, cmaps)
    AxType = resolve_symbol(dict["type"])
    ax_attr = [Symbol(k) => resolve_symbol(v) for (k, v) in get(dict, "attributes", [])]
    pos = get(dict, "position", [1, 1])

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
    else
        ax = AxType(fig[pos...]; ax_attr...)
        plots = map(dict["plots"]) do plot
            layer_to_plot!(ax, sliced_arrays, plot, fcolor, cmaps)
        end
        return (ax, plots)
    end
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

function create_plot(data, layers;)
    layers = copy(layers)
    figure_kw = remove_dicts!(x -> haskey(x, "figure"), layers)
    if length(figure_kw) == 1
        figure_kw = first(figure_kw)
        f_kw = map(collect(figure_kw["figure"])) do (k, v)
            k == "size" && return :size => (v...,)
            return Symbol(k) => v
        end
    else
        f_kw = Dict()
    end
    f = Figure(; f_kw...)
    fplots = f[1, 1]
    fcbar = f[2, 1]
    fcolor = f[3, 1]
    layouts = remove_dicts!(x-> haskey(x, "layout"), layers)
    sliced_arrays, widgets = create_slices(layers, data)
    cmaps = []
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
    for (i, colormaps) in enumerate(cmaps)
        cmaps = Base.structdiff(colormaps, (; nan_color=0, alpha=0))
        Colorbar(fcbar[i, 1]; vertical=false, tellheight=true, tellwidth=true, cmaps...)
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

function Bonito.jsrender(session::Session, viewer::DataViewerApp)
    f = viewer.figure
    data = viewer.data
    widgets = viewer.widgets
    names = get_dim_names(to_value(data))
    dom = Col(Bonito.Col([widgets[n] for n in names if haskey(widgets, n)]...), Card(f); style=Styles("width" => "1000px"))
    return Bonito.jsrender(session, Centered(dom; style=Styles("width" => "100%")))
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
