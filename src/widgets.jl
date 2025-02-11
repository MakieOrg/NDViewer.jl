struct PlaySlider
    name::String
    range::Vector{Int}
    lookup::Union{Nothing,Dict{Int, Any}}
    value::Observable{Int}
end

PlaySlider(name, range, lookup=nothing) = PlaySlider(name, range, lookup, Observable(first(range)))

struct SelectOptions
    name::String
    options::Any
    option::Observable
    value::Observable
end

function SelectOptions(name, pairs)
    options = first.(pairs)
    lookup = Dict(pairs)
    option = Observable(first(options))
    value = map(option) do v
        return lookup[v]
    end
    return SelectOptions(name, options, option, value)
end

select_dim_widget(name, axes::AbstractVector{<:Real}) = PlaySlider(name, axes)
select_dim_widget(name, axes::AbstractVector{<:Pair{<:AbstractString,<:Integer}}) = SelectOptions(name, axes)

function select_dim_widget(name, pairs::AbstractVector{<:Pair{<:Any,<:Integer}})
    indices = last.(pairs)
    lookup = Dict(reverse.(pairs))
    return PlaySlider(name, indices, lookup)
end

function slice_dim(arr, dim::Int, dim_name::String)
    arr_obs = convert(Observable, arr)
    axes = get_axis(arr_obs[], dim)
    widget = select_dim_widget(dim_name, axes)
    data = map(arr_obs, Makie.map_latest(identity, widget.value;)) do arr, idx
        return view(arr, ntuple(i -> i == dim ? idx : (:), ndims(arr))...)
    end
    return data, widget
end
