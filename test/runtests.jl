using NDViewer
using Test
using Observables
using Bonito: Styles

@testset "NDViewer.jl" begin

    @testset "Theme Module" begin
        @testset "Color constants" begin
            @test NDViewer.Theme.PRIMARY == "#4a90d9"
            @test NDViewer.Theme.SURFACE == "#ffffff"
            @test NDViewer.Theme.TEXT_PRIMARY == "#212529"
        end

        @testset "Style helper functions" begin
            @test NDViewer.widget_card_style() isa Styles
            @test NDViewer.dropdown_style() isa Styles
            @test NDViewer.app_container_style() isa Styles
            @test NDViewer.viewer_card_style() isa Styles
            @test NDViewer.widget_panel_style() isa Styles

            # Test slider_theme returns named tuple with correct fields
            st = NDViewer.slider_theme()
            @test st isa NamedTuple
            @test haskey(st, :slider_height)
            @test haskey(st, :track_color)
            @test haskey(st, :thumb_style)
            @test st.slider_height == 20
            @test st.thumb_style isa Styles
        end

        @testset "Button style variants" begin
            primary = NDViewer.button_style(variant=:primary)
            secondary = NDViewer.button_style(variant=:secondary)
            icon = NDViewer.button_style(variant=:icon)

            @test primary isa Styles
            @test secondary isa Styles
            @test icon isa Styles
        end

        @testset "Label style variants" begin
            default = NDViewer.label_style(variant=:default)
            heading = NDViewer.label_style(variant=:heading)
            muted = NDViewer.label_style(variant=:muted)

            @test default isa Styles
            @test heading isa Styles
            @test muted isa Styles
        end
    end

    @testset "Array Interface" begin
        @testset "get_dim_names for regular arrays" begin
            arr2d = rand(5, 10)
            arr3d = rand(5, 10, 20)
            arr4d = rand(2, 3, 4, 5)

            @test NDViewer.get_dim_names(arr2d) == ["1", "2"]
            @test NDViewer.get_dim_names(arr3d) == ["1", "2", "3"]
            @test NDViewer.get_dim_names(arr4d) == ["1", "2", "3", "4"]
        end

        @testset "get_axis for regular arrays" begin
            arr = rand(5, 10, 20)

            @test NDViewer.get_axis(arr, 1) == collect(1:5)
            @test NDViewer.get_axis(arr, 2) == collect(1:10)
            @test NDViewer.get_axis(arr, 3) == collect(1:20)
        end
    end

    @testset "Widgets" begin
        @testset "PlaySlider" begin
            ps = NDViewer.PlaySlider("time", collect(1:100))

            @test ps.name == "time"
            @test ps.range == collect(1:100)
            @test ps.value[] == 1
            @test ps.lookup === nothing

            # Test with lookup
            lookup = Dict(1 => "Jan", 2 => "Feb", 3 => "Mar")
            ps_lookup = NDViewer.PlaySlider("month", [1, 2, 3], lookup)

            @test ps_lookup.lookup == lookup
        end

        @testset "SelectOptions" begin
            pairs = ["temperature" => 1, "pressure" => 2, "humidity" => 3]
            so = NDViewer.SelectOptions("variable", pairs)

            @test so.name == "variable"
            @test so.options == ["temperature", "pressure", "humidity"]
            @test so.option[] == "temperature"
            @test so.value[] == 1

            # Change selection
            so.option[] = "pressure"
            @test so.value[] == 2
        end

        @testset "select_dim_widget" begin
            # Numeric range
            widget1 = NDViewer.select_dim_widget("x", collect(1:10))
            @test widget1 isa NDViewer.PlaySlider

            # String-indexed pairs
            widget2 = NDViewer.select_dim_widget("var", ["a" => 1, "b" => 2])
            @test widget2 isa NDViewer.SelectOptions

            # Other pairs (creates PlaySlider with lookup)
            widget3 = NDViewer.select_dim_widget("time", [1.0 => 1, 2.0 => 2, 3.0 => 3])
            @test widget3 isa NDViewer.PlaySlider
            @test widget3.lookup !== nothing
        end
    end

    @testset "Dimension Matching" begin
        @testset "match_dims" begin
            # Same dimensions
            @test NDViewer.match_dims([1, 2, 3], [1, 2, 3]) == -1000

            # Permutation
            @test NDViewer.match_dims([1, 2, 3], [2, 1, 3]) == -900
            @test NDViewer.match_dims([1, 2, 3], [3, 2, 1]) == -900

            # Ready to slice (one dimension less)
            @test NDViewer.match_dims([1, 2, 3], [1, 2]) == -800

            # Partial match
            @test NDViewer.match_dims([1, 2, 3, 4], [1, 2]) > -800

            # No match
            @test NDViewer.match_dims([1, 2], [3, 4]) == 9000
        end
    end

    @testset "Slicing" begin
        @testset "slice_dim" begin
            test_data = rand(5, 10, 20)

            # Slice along dimension 3
            sliced, widget = NDViewer.slice_dim(test_data, 3, "time")

            @test sliced isa Observable
            @test widget isa NDViewer.PlaySlider
            @test widget.name == "time"
            @test size(sliced[]) == (5, 10)

            # Changing the widget value should update the slice
            widget.value[] = 5
            @test size(sliced[]) == (5, 10)  # Size stays the same

            # Slice along dimension 1
            sliced2, widget2 = NDViewer.slice_dim(test_data, 1, "x")
            @test size(sliced2[]) == (10, 20)
        end

        @testset "accessor functions" begin
            @test NDViewer.accessor2dim(1) == 1
            @test NDViewer.accessor2dim(2 => 5) == 2
            @test NDViewer.accessor2dim(Dict(3 => 10)) == 3

            @test NDViewer.dim2accessor(1) == (:)
            @test NDViewer.dim2accessor(2 => 5) == 5
            @test NDViewer.dim2accessor(Dict(3 => 10)) == 10
        end
    end

    @testset "Value Formatting" begin
        @test NDViewer.format_value(42) == "42"
        @test NDViewer.format_value("hello") == "hello"
        @test NDViewer.format_value(3.14159) == "3.142"
        @test NDViewer.format_value(1.0) == "1.0"
        @test NDViewer.format_value(0.001) == "0.001"
    end

    @testset "DataViewerApp struct" begin
        # Test that the struct exists and has correct fields
        @test hasfield(NDViewer.DataViewerApp, :layers)
        @test hasfield(NDViewer.DataViewerApp, :data)
        @test hasfield(NDViewer.DataViewerApp, :figure)
        @test hasfield(NDViewer.DataViewerApp, :slices)
        @test hasfield(NDViewer.DataViewerApp, :widgets)
        @test hasfield(NDViewer.DataViewerApp, :axes)
    end

end
