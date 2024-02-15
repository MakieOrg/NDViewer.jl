struct PlaySlider
    name::String
    range::Any
    value::Observable
end

PlaySlider(name, range) = PlaySlider(name, range, Observable(first(range)))

function slice_dim(arr, dim::Int, dim_name::String)
    arr_obs = convert(Observable, arr)
    ps = PlaySlider(dim_name, collect(axes(arr_obs[], dim)))
    data = map(arr_obs, ps.value) do arr, idx
        return view(arr, ntuple(i -> i == dim ? idx : (:), ndims(arr))...)
    end
    return data, ps
end
