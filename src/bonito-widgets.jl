using Bonito

function PlayButton(slider, range, session)
    button = Bonito.Button("▶"; style=Styles("min-width" => "1rem", "height" => "2rem", "margin" => "0px"))
    not_yet_open = true
    playing = Threads.Atomic{Bool}(false)
    time_per_frame = Threads.Atomic{Float64}(1 / 30)
    task = @async let i = first(range)
        while true
            yield()
            if isopen(session)
                not_yet_open = false
            end
            if !isopen(session) && !not_yet_open
                break
            end
            t = time()
            if playing[]
                i = mod1(i + 1, last(range))
                slider[] = i
                # leave time for actuall rendering etc, before sleeping
                yield()
            end
            elapsed = time() - t
            sleep(max(0.001, time_per_frame[] - elapsed))
        end
        println("done: ", not_yet_open, ", ", isopen(session))
    end
    Base.errormonitor(task)
    on(session, button.value) do _
        if playing[]
            playing[] = false
            button.content[] = "▶"
        else
            playing[] = true
            button.content[] = "❚❚"
        end
    end
    return button
end

format_value(v) = string(v)
format_value(v::AbstractFloat) = round(v; digits=3)

function Bonito.jsrender(session::Session, ps::PlaySlider)
    slider = Bonito.StylableSlider(ps.range)
    button = PlayButton(slider, ps.range, session)
    on(session, slider.value) do v
        ps.value[] = v
        return
    end
    value_obs = if ps.lookup !== nothing
        map(x-> format_value(ps.lookup[x]), slider.value)
    else
        slider.value
    end

    label = Centered(Bonito.Label(ps.name))
    widget_row = Bonito.Row(label, button, slider, Bonito.Label(value_obs);
                            columns="4rem 4rem 1fr 10rem", align_items=:center)
    return Bonito.jsrender(session, Card(widget_row))
end

function Bonito.jsrender(session::Session, so::SelectOptions)
    dropdown = Bonito.Dropdown(so.options)
    on(session, dropdown.value) do v
        so.option[] = v
        return
    end
    label = Centered(Bonito.Label(so.name))
    widget_row = Bonito.Row(label, dropdown;
        columns="4rem 1fr", align_items=:center)
    return Bonito.jsrender(session, Card(widget_row))
end
