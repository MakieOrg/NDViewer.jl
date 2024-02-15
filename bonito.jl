
using WGLMakie, Bonito

function PlayButton(slider, range, session)
    button = Bonito.Button("▶"; style=Styles("min-width" => "1rem", "height" => "2rem", "margin" => "0px"))
    not_yet_open = true
    playing = Threads.Atomic{Bool}(false)
    time_per_frame = Threads.Atomic{Float64}(1/24)
    last_elapsed = Float64[]
    Base.errormonitor(@async let i = first(range)
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
            end
            elapsed = time() - t
            if length(last_elapsed) == 100
                circshift!(last_elapsed, -1)
                last_elapsed[end] = elapsed
            else
                push!(last_elapsed, elapsed)
            end
            time_per_frame[] = maximum(last_elapsed)
            sleep(max(0.001, time_per_frame[] - elapsed))
        end
        println("done: ", not_yet_open, ", ", isopen(session))
    end)
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

struct PlaySlider
    name::String
    range
    value::Observable
end

PlaySlider(name::String, range) = PlaySlider(name, range, Observable(first(range)))

function Bonito.jsrender(session::Session, ps::PlaySlider)
    slider = Bonito.StylableSlider(ps.range)
    button = PlayButton(slider, ps.range, session)
    on(session, slider.value) do v
        ps.value[] = v
    end
    label = Centered(Bonito.Label(ps.name))
    widget_row = Bonito.Row(
        label, button, slider, Bonito.Label(slider.value);
        columns="4rem 4rem 1fr 4rem", align_items=:center)
    return Bonito.jsrender(session, Card(widget_row))
end

function test()
    App() do session
        data = rand(Float32, 1024, 1024, 100)
        f = Figure()
        slice = Observable(view(data, :, :, 1))
        play = PlaySlider("time", 1:100)
        Makie.on_latest(i -> (slice[] = view(data, :, :, i)), session, play.value)
        image(f[1,1], slice)
        Col(play, f)
    end
end
