module NDViewer

using Makie, DimensionalData, LinearAlgebra, Bonito

include("array-interface.jl")
include("makie-converts.jl")
include("widgets.jl")
include("bonito-widgets.jl")
include("makie-widgets.jl")
include("layers.jl")
include("yaml-app.jl")

end
