
function match_dims(m, target)
    # same
    m == target && return -1000
    na = length(m)
    nb = length(target)
    # permutation
    na == nb && all(x -> x in m, target) && return -900
    # ready to slice
    nb == na - 1 && m[1:nb] == target && return -800
    i = 0
    for (x, y) in zip(m, target)
        if x == y
            i -= 1
        else
            i += 1
        end
    end
    return (i + length(m)) # penalize by length
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
        throw(ArgumentError("target_dims must be a subset of the dimensions of data. Found: $(target_dims)"))
    elseif length(closest) == length(target_dims)
        data = map(x -> permutedims(x, (target_dims...,)), input_data)
        arrays[target_dims] = data
        return
    elseif length(closest) == length(target_dims) + 1
        # if closest is one dimension larger than target_dims, we can slice
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
        get_dims!(arrays, widgets, convert(Vector{Int}, new_target_dims), names)
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


accessor2dim(x::Pair{Int,T}) where T = Int(x[1])
accessor2dim(x::Integer) = Int(x)

dim2accessor(x::Pair{Int,T}) where T = x[2]
dim2accessor(::Integer) = (:)

function create_slices(layers, data::AbstractArray)
    input_data = convert(Observable, data)

    names = get_dim_names(input_data[])
    dims = collect(1:ndims(input_data[]))

    sliced_arrays = Dict{Vector{Any},Observable}(dims => input_data)
    widgets = Dict{String,Any}()

    slices = []
    for layer in layers
        for arg in layer["args"]
            push!(slices, Int[accessor2dim(a) for a in arg])
        end
    end
    sort!(slices; by=length, rev=true)
    for slice in slices
        get_dims!(sliced_arrays, widgets, slice, names)
    end

    used_data = map(slice -> sliced_arrays[slice], slices)
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
    return sliced_arrays, widgets, colorrange
end

function access2slice(sliced_arrays, arg::Vector)
    # unwrap something like [1, 2=>3] to [1, 2]
    flat = map(accessor2dim, arg)
    # get the array slice for the flat dims
    # Should be guaranteed to exist, as long as create_slices was called on the same args before
    array_slice_obs = sliced_arrays[flat]
    # Now, apply the `=>` parts (if any existed) and cache it in sliced_arrays
    return get!(sliced_arrays, arg) do
        map(arr -> collect(view(arr, map(dim2accessor, arg)...)), array_slice_obs)
    end
end

function replace_slices(sliced_arrays, args::Vector{<:Vector})
    return map(args) do arg
        access2slice(sliced_arrays, arg)
    end
end

function replace_slices(sliced_arrays, attributes::Dict)
    return Dict(map(collect(attributes)) do (k, value)
        if value isa Dict && haskey(value, "slice")
            value = access2slice(sliced_arrays, value["slice"])
        end
        return Symbol(k) => value
    end)
end



function create_plot(data, layers; figure=(;))
    size = get(figure, :size, (1000, 700))
    f = Figure(; figure..., size=size)
    fplots = f[1, 1]
    fcbar = f[2, 1]
    fcolor = f[3, 1]

    sliced_arrays, widgets, colorrange = create_slices(layers, data)
    colormaps = colormap_widget(fcolor, colorrange)

    for (i, layer) in enumerate(layers)
        plotfunc = layer["type"]
        args = replace_slices(sliced_arrays, layer["args"])
        attr = get(layer, "attributes", Dict())
        attributes = replace_slices(sliced_arrays, attr)
        if plotfunc == volume
            ax = Axis3(fplots[1, i];)
            volume!(ax, args...; attributes...)
        else
            plotfunc(fplots[1, i], args...; attributes...)
        end
    end
    cmaps = Base.structdiff(colormaps, (; nan_color=0, alpha=0))
    Colorbar(fcbar[1, 1]; vertical=false, tellheight=true, tellwidth=true, cmaps...)
    return f, sliced_arrays, widgets
end

function wgl_create_plot(data, layers; figure=(;))
    return App() do
        f, slices, widgets = create_plot(data, layers; figure=figure)
        app = Col(Bonito.Col(values(widgets)...), Card(f); style=Styles("width" => "1000px"))
        return Centered(app; style=Styles("width" => "100%"))
    end
end
