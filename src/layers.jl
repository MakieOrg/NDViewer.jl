
function match_dims(a, b)
    # same
    a == b && return -1000
    na = length(a)
    nb = length(b)
    # permutation
    na == nb && all(x -> x in a, b) && return -900
    # ready to slice
    nb == na - 1 && a[1:nb] == b && return -800
    if all(x -> (x in a), b)
        i = 0
        for (x, y) in zip(a, b)
            if x == y
                i -= 1
            else
                i += 1
            end
        end
        return i
    end
    # no match
    return 1000
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
    if any(x -> x > ndims(input_data[]), target_dims)
        throw(ArgumentError("target_dims must be a subset of the dimensions of data"))
    elseif length(closest) == length(target_dims)
        data = map(x -> permutedims(x, (target_dims...,)), input_data)
        arrays[target_dims] = data
        return
    elseif length(closest) == length(target_dims) + 1
        dim_to_slice = only(setdiff(closest, target_dims))
        name = names[dim_to_slice]
        data, widget = slice_dim(input_data, dim_to_slice, name)
        widgets[name] = widget
        new_dims = filter(x -> x != dim_to_slice, target_dims)
        arrays[new_dims] = data
        return
    else
        missing_dims = sort(setdiff(closest, target_dims))
        new_target_dims = filter(x -> x != missing_dims[end], closest)
        get_dims!(arrays, widgets, new_target_dims, names)
        return get_dims!(arrays, widgets, target_dims, names)
    end
end

function plot_data(data, layers; figure=(;))
    size = get(figure, :size, (1200, 800))
    f = Figure(; figure..., size=size)
    fcolor = f[1, 1]
    fslider = f[2, 1]
    fplots = f[3, 1]
    slices, widgets, colorrange = create_slices(layers, data)
    colormaps = colormap_widget(fcolor, colorrange)
    slices, widgets = create_plot(fplots, slices, colormaps)
    return
end

function create_slices(layers, data)
    slices = map(layer -> layer["data"], layers)
    sort!(slices; by=length, rev=true)

    input_data = convert(Observable, data.data)
    dims = collect(1:ndims(input_data[]))

    result = Dict{Vector{Int},Observable}(dims => input_data)
    widgets = Dict{String,Any}()
    names = map(string, data.names)

    for slice in slices
        get_dims!(result, widgets, slice, names)
    end

    used_data = map(slice -> result[slice], slices)
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
    return result, widgets, colorrange
end

function create_plot(data, layers; figure=(;))
    size = get(figure, :size, (1000, 700))
    f = Figure(; figure..., size=size)
    fplots = f[1, 1]
    fcbar = f[2, 1]
    fcolor = f[3, 1]

    slices, widgets, colorrange = create_slices(layers, data)
    colormaps = colormap_widget(fcolor, colorrange)

    for (i, layer) in enumerate(layers)
        plotfunc = layer["type"]
        if plotfunc == volume
            ax = Axis3(fplots[1, i];)
            volume!(ax, slices[layer["data"]]; shading=NoShading, levels=10, algorithm=:absorption,
                    colormaps...)
        else
            plotfunc(fplots[1, i], map(x-> convert(Array{Float32}, x), slices[layer["data"]]); colormaps...)
        end
    end
    cmaps = Base.structdiff(colormaps, (; nan_color=0, alpha=0))
    Colorbar(fcbar[1, 1]; vertical=false, tellheight=true, tellwidth=true, cmaps...)
    return f, slices, widgets
end

function wgl_create_plot(data, layers; figure=(;))
    return App() do
        f, slices, widgets = create_plot(data, layers; figure=figure)
        app = Col(Bonito.Row(values(widgets)...), Card(f); style=Styles("width" => "1000px"))
        return Centered(app; style=Styles("width" => "100%"))
    end
end
