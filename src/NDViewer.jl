module NDViewer

using Makie, DimensionalData, LinearAlgebra, Bonito
using Bonito: Styles, CSS, RGBA, DOM

include("array-interface.jl")
include("theme.jl")
include("makie-converts.jl")
include("widgets.jl")
include("bonito-widgets.jl")
include("makie-widgets.jl")
include("layers.jl")
include("yaml-viewer.jl")

end
