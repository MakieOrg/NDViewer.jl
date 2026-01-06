using Bonito
using Bonito: Styles, CSS, DOM

# NDViewer widget styles - modern, compact design compatible with BonitoBook
const NDVIEWER_STYLES = Styles(
    # Play button - minimal, modern
    CSS(
        ".ndviewer-play-btn",
        "width" => "24px",
        "height" => "24px",
        "padding" => "0",
        "margin" => "0",
        "border" => "none",
        "border-radius" => "4px",
        "background" => "var(--hover-bg, #f0f0f0)",
        "color" => "var(--text-primary, #333)",
        "cursor" => "pointer",
        "display" => "inline-flex",
        "align-items" => "center",
        "justify-content" => "center",
        "font-size" => "10px",
        "line-height" => "1",
        "transition" => "background 0.15s ease",
        "flex-shrink" => "0",
    ),
    CSS(
        ".ndviewer-play-btn:hover",
        "background" => "var(--accent-blue, #0366d6)",
        "color" => "#fff",
    ),
    CSS(
        ".ndviewer-play-btn:active",
        "transform" => "scale(0.95)",
    ),
    # Label styling
    CSS(
        ".ndviewer-lbl",
        "font-size" => "13px",
        "font-weight" => "500",
        "color" => "var(--text-secondary, #666)",
        "white-space" => "nowrap",
    ),
    # Slider container - grows to fill available space, with min width
    CSS(
        ".ndviewer-slider-wrap",
        "flex" => "1 1 120px",
        "min-width" => "120px",
    ),
    # Value display - width set dynamically per slider based on value length
    CSS(
        ".ndviewer-val",
        "display" => "inline-block",
        "font-size" => "12px",
        "color" => "var(--text-primary, #333)",
        "font-family" => "var(--mono-font, 'SF Mono', Consolas, monospace)",
        "flex-shrink" => "0",
        "white-space" => "nowrap",
        "overflow" => "hidden",
        "text-overflow" => "ellipsis",
        "text-align" => "right",
    ),
    # Container for all widgets - flexbox wrap layout
    CSS(
        ".ndviewer-widgets",
        "display" => "flex",
        "flex-wrap" => "wrap",
        "align-items" => "center",
        "gap" => "2px 12px",
        "background" => "var(--bg-primary, #fff)",
        "border-radius" => "6px",
        "padding" => "4px 10px",
        "box-shadow" => "0 1px 2px rgba(0,0,0,0.06)",
        "border" => "1px solid var(--border-primary, rgba(0,0,0,0.08))",
    ),
    # Widget item - flex item that grows to share available space
    CSS(
        ".ndviewer-widget-item",
        "display" => "flex",
        "align-items" => "center",
        "gap" => "5px",
        "padding" => "2px 0",
        "flex" => "1 1 auto",
    ),
    # Separator between items (vertical line)
    CSS(
        ".ndviewer-widget-item:not(:last-child)::after",
        "content" => "''",
        "width" => "1px",
        "height" => "20px",
        "background" => "var(--border-primary, rgba(0,0,0,0.1))",
        "margin-left" => "10px",
    ),
)

function PlayButton(slider, range, session)
    content = Observable("▶")
    button_dom = DOM.button(
        content;
        class="ndviewer-play-btn",
    )
    playing = Threads.Atomic{Bool}(false)
    time_per_frame = Threads.Atomic{Float64}(1 / 30)
    task = @async begin
        while true
            if Bonito.isclosed(session)
                break
            end
            try
                yield()
                t = time()
                if playing[]
                    current = slider[]
                    next = mod1(current + 1, last(range))
                    slider[] = next
                    yield()
                end
                elapsed = time() - t
                sleep(max(0.01, time_per_frame[] - elapsed))
            catch e
                if Bonito.isclosed(session)
                    break
                end
                @warn "PlayButton loop error" exception=(e, catch_backtrace())
                sleep(0.1)
            end
        end
    end
    Base.errormonitor(task)

    click_handler = js"""
        const btn = $(button_dom);
        const content_obs = $(content);
        let playing = false;
        btn.addEventListener('click', () => {
            playing = !playing;
            content_obs.notify(playing ? '❚❚' : '▶');
        });
    """

    on(session, content) do c
        playing[] = (c == "❚❚")
    end

    return DOM.span(button_dom, click_handler)
end

format_value(v) = string(v)
format_value(v::AbstractFloat) = string(round(v; digits=3))

function Bonito.jsrender(session::Session, ps::PlaySlider)
    slider = Bonito.StylableSlider(ps.range; slider_height=16)
    button = PlayButton(slider.index, ps.range, session)
    on(session, slider.value) do v
        ps.value[] = v
        return
    end
    value_obs = if ps.lookup !== nothing
        map(x -> format_value(ps.lookup[x]), slider.value)
    else
        map(format_value, slider.value)
    end

    # Calculate value display width based on longest string (first/last values)
    first_str = ps.lookup !== nothing ? format_value(ps.lookup[first(ps.range)]) : format_value(first(ps.range))
    last_str = ps.lookup !== nothing ? format_value(ps.lookup[last(ps.range)]) : format_value(last(ps.range))
    max_chars = max(length(first_str), length(last_str))
    # Approximate width: ~7.2px per char for monospace font at 12px size
    val_width = ceil(Int, max_chars * 7.2)

    label = DOM.span(ps.name; class="ndviewer-lbl")
    slider_wrap = DOM.div(slider; class="ndviewer-slider-wrap", style="padding-left: 8px;")
    value_display = DOM.span(value_obs; class="ndviewer-val", title=value_obs, style="width: $(val_width)px;")

    # Flat structure: label, button, slider, value all in one flex item
    widget_item = DOM.div(label, button, slider_wrap, value_display; class="ndviewer-widget-item")

    return Bonito.jsrender(session, DOM.div(NDVIEWER_STYLES, widget_item))
end

function Bonito.jsrender(session::Session, so::SelectOptions)
    dropdown = Bonito.Dropdown(so.options)
    on(session, dropdown.value) do v
        so.option[] = v
        return
    end
    label = DOM.span(so.name; class="ndviewer-lbl")

    # Flat structure: label and dropdown in one flex item
    widget_item = DOM.div(label, dropdown; class="ndviewer-widget-item")

    return Bonito.jsrender(session, DOM.div(NDVIEWER_STYLES, widget_item))
end
