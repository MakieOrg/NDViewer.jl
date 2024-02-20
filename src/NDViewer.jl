module NDViewer

using Makie, DimensionalData, LinearAlgebra

include("array-interface.jl")
include("makie-converts.jl")
include("loading.jl")
include("widgets.jl")
include("bonito-widgets.jl")
include("makie-widgets.jl")
include("layers.jl")

end
