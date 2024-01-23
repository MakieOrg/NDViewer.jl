
function arrows_layer!(ax::Makie.AbstractAxis, positions, directions, colormap)

end

function heatmap_layer!(ax::Makie.AbstractAxis, x, y, image, colormap)

end

function surface_layer!(ax::Makie.AbstractAxis, x, y, image, colormap)

end

function volume_layer!(ax::Makie.AbstractAxis, x, y, z, volume, colormap)

end

function create_plot(tempdata)
    f = Figure()
    fcolor = f[1, 1]
    fslider = f[2, 1]
    fplots = f[3, 1]
    fcbar = f[4, 1]
    time_slice = slice_dim(fslider[1, 1], tempdata, 4, "time")
    slice_2d = slice_dim(fslider[2, 1], time_slice, 3, "height")
    colormaps = colormap_widget(fcolor, tempdata)
    grid = SliderGrid(fslider[3, 1],
        (label="absorption", range=LinRange(0, 100, 100), startvalue=50),
    )
    absorption = grid.sliders[1]

    ax, hp = heatmap(fplots[1, 1], slice_2d; axis=(; aspect=DataAspect()), colormaps...)
    ax, cp = volume(fplots[1, 2], time_slice; axis=(; type=Axis3),
        shading=NoShading, levels=10, algorithm=:absorption, absorption=map(Float32, absorption.value),
        colormaps...
    )
    cmaps = Base.structdiff(colormaps, (; nan_color=0, alpha=0))
    Colorbar(fcbar[1, 1]; vertical=false, tellheight=true, tellwidth=true, cmaps...)

    f
end


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

function get_dims!(fig, target_dims, names, gridpos, result::Dict)
    available = collect(keys(result))
    if target_dims in available
        return result[target_dims]
    end
    sort!(available, by=x->match_dims(x, target_dims))
    closest = first(available)
    input_data = result[closest]
    if any(x -> x > ndims(input_data[]), target_dims)
        throw(ArgumentError("target_dims must be a subset of the dimensions of data"))
    elseif length(closest) == length(target_dims)
        data = map(x -> permutedims(x, (target_dims...,)), input_data)
        result[target_dims] = data
        return result
    elseif length(closest) == length(target_dims) + 1
        dim_to_slice = only(setdiff(closest, target_dims))
        data = slice_dim(fig[gridpos, 1], input_data, dim_to_slice, names[dim_to_slice])
        new_dims = filter(x-> x != dim_to_slice, target_dims)
        result[new_dims] = data
        return result
    else
        missing_dims = setdiff(closest, target_dims)
        new_target_dims = filter(x-> x != missing_dims[1], target_dims)
        get_dims!(fig, new_target_dims, names, gridpos, result)
        return get_dims!(fig, target_dims, names, gridpos + 1, result)
    end
end
