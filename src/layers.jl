
function match_dims(a, b)
    # same
    a == b && return -1000
    na = length(a); nb = length(b)
    # permutation
    na == nb && all(x-> x in a, b) && return -900
    # ready to slice
    nb == na-1 && a[1:nb] == b && return -800
    if all(x-> (x in a), b)
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
function get_dims!(fig, target_dims, names, gridpos, result::Dict)
    available = collect(keys(result))
    if target_dims in available
        return gridpos
    end
    sort!(available, by=x->match_dims(x, target_dims))
    closest = first(available)
    input_data = result[closest]
    if any(x -> x > ndims(input_data[]), target_dims)
        throw(ArgumentError("target_dims must be a subset of the dimensions of data"))
    elseif length(closest) == length(target_dims)
        data = map(x -> permutedims(x, (target_dims...,)), input_data)
        result[target_dims] = data
        return gridpos
    elseif length(closest) == length(target_dims) + 1
        dim_to_slice = only(setdiff(closest, target_dims))
        data = slice_dim(fig[gridpos, 1], input_data, dim_to_slice, names[dim_to_slice])
        new_dims = filter(x-> x != dim_to_slice, target_dims)
        result[new_dims] = data
        return gridpos + 1
    else
        missing_dims = sort(setdiff(closest, target_dims))
        new_target_dims = filter(x -> x != missing_dims[end], closest)
        get_dims!(fig, new_target_dims, names, gridpos, result)
        return get_dims!(fig, target_dims, names, gridpos + 1, result)
    end
end



function plot_data(data, layers; figure=(;))
    size = get(figure, :size, (1200, 800))
    f = Figure(; figure..., size=size)
    fcolor = f[1, 1]
    fslider = f[2, 1]
    fplots = f[3, 1]
    fcbar = f[4, 1]

    slices = sort!(map(layers) do layer
            layer["data"]
        end; by=length, rev=true)

    input_data = convert(Observable, data.data)
    dims = collect(1:ndims(input_data[]))

    result = Dict{Vector{Int},Observable}(
        dims => input_data
    )
    gridpos = 1
    for slice in slices
        gridpos = get_dims!(fslider, slice, data.names, gridpos, result)
    end
    colormaps = colormap_widget(fcolor, input_data[])
    for (i, layer) in enumerate(layers)
        plotfunc = layer["type"]
        if plotfunc == volume
            ax = Axis3(fplots[1, i];)
            volume!(ax, result[layer["data"]]; shading=NoShading, levels=10, algorithm=:absorption, colormaps...)
        else
            plotfunc(fplots[1, i], result[layer["data"]]; colormaps...)
        end
    end
    cmaps = Base.structdiff(colormaps, (; nan_color=0, alpha=0))
    Colorbar(fcbar[1, 1]; vertical=false, tellheight=true, tellwidth=true, cmaps...)
    f
end
