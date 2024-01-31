
function play_slider(figure, label, range)
    l = Label(figure[1, 1], string(label), halign=:left)
    button = Button(figure[1, 2]; label=">")
    slider = Slider(figure[1, 3]; range=range)
    vl = Label(figure[1, 4], map(string, slider.value), halign=:right)
    sgrid = figure[1, 5] = GridLayout()
    speed_button = [
        Button(sgrid[1, 1]; label="1") => 1,
        Button(sgrid[1, 2]; label="10") => 10,
        Button(sgrid[1, 3]; label="24") => 24,
        Button(sgrid[1, 4]; label="60") => 60,
    ]
    playing = Threads.Atomic{Bool}(false)
    fps = Threads.Atomic{Int}(24)

    for (b, s) in speed_button
        on(b.clicks) do _
            fps[] = s
        end
    end
    colgap!(sgrid, 2)
    rowgap!(sgrid, 2)
    scene = Makie.parent_scene(figure)
    was_opened = isopen(scene)
    Base.errormonitor(@async let i = first(range)
        while !was_opened || isopen(scene)
            was_opened = isopen(scene)
            t = time()
            if playing[]
                i = mod1(i + 1, last(range))
                Makie.set_close_to!(slider, i)
            end
            elapsed = time() - t
            sleep(max(0.001, (1 / fps[]) - elapsed))
        end
    end)
    on(button.clicks) do _
        if playing[]
            button.label[] = ">"
            playing[] = false
        else
            button.label[] = "||"
            playing[] = true
        end
    end
    return slider.value
end

function slice_dim(figure, arr, dim, dim_name)
    arr_obs = convert(Observable, arr)
    idx_obs = play_slider(figure, dim_name, collect(axes(arr_obs[], dim)))
    return map(arr_obs, idx_obs) do arr, idx
        return view(arr, ntuple(i -> i == dim ? idx : (:), ndims(arr))...)
    end
end

function colormap_widget(f, limits, colorrange, lowclip, highclip, nan_color, alpha, colormap, colormaps=COLORMAPS)
    current_crange = colorrange[]
    rs_h = IntervalSlider(f[1, 1],
        range=LinRange(limits..., 100),
        startvalues=(current_crange...,))
    labeltext1 = lift(rs_h.interval) do int
        string(round.(int, digits=2))
    end
    Label(f[1, 2], labeltext1)
    on(rs_h.interval) do v
        colorrange[] = v
    end
    cmap_menu = Menu(f[:, 3]; options=colormaps, default=string(colormap[]))
    on(cmap_menu.selection) do val
        colormap[] = val
    end
end

const COLORMAPS = [
    :viridis,
    :autumn1,
    :balance,
    :matter,
    :turbid,
    :bam50,
    :berlin25,
    :buda25,
    :lipari25
]

function colormap_widget(f, data, colormaps=COLORMAPS)
    limits = Makie.extrema_nan(data)
    kw = (
        colorrange=Observable(Vec2f(limits)),
        lowclip=Observable(:black),
        highclip=Observable(:red),
        nan_color=Observable(:transparent),
        alpha=Observable(1.0),
        colormap=Observable(:autumn1),
    )
    colormap_widget(f, limits, kw.colorrange, kw.lowclip, kw.highclip, kw.nan_color, kw.alpha, kw.colormap, colormaps)
    return kw
end
