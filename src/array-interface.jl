function get_dim_names(data::AbstractArray)
    return map(string, 1:ndims(data))
end

function get_dim_names(data::AbstractDimArray)
    return map(x -> string(name(x.dim)), collect(axes(data)))
end

function get_axis(array::AbstractArray, nd)
    collect(axes(array, nd))
end

function get_axis(array::AbstractDimArray, nd)
    names = collect(dims(array, nd))
    indices = collect(axes(array, nd))
    return Pair.(names, indices)
end
