
function Makie.convert_arguments(::Type{<:Arrows}, u_matrix::AbstractMatrix{<:Real}, v_matrix::AbstractMatrix{<:Real}, w_matrix::AbstractMatrix{<:Real})
    data = Vec3f.(u_matrix, v_matrix, w_matrix)
    points = Point3f.(Tuple.(CartesianIndices(data)))
    return PlotSpec(:Arrows, vec(points), vec(data), color=norm.(vec(data)))
end

function Makie.convert_arguments(::Type{<:Arrows}, u_matrix::AbstractMatrix{<:Real}, v_matrix::AbstractMatrix{<:Real})
    return convert_arguments(Arrows, 1:size(u_matrix, 1), 1:size(u_matrix, 2), u_matrix, v_matrix)
end

function Makie.convert_arguments(::Type{<:Arrows}, xrange::Makie.AbstractVector{<:Real}, yrange::AbstractVector{<:Real}, u_matrix::AbstractMatrix{<:Real}, v_matrix::AbstractMatrix{<:Real})
    xvec = Makie.to_vector(xrange, size(u_matrix, 1), Float32)
    yvec = Makie.to_vector(yrange, size(u_matrix, 2), Float32)
    data = Vec2f.(u_matrix, v_matrix)
    points = Point2f.(xvec, yvec')
    return PlotSpec(:Arrows, vec(points), vec(data), color=norm.(vec(data)))
end

function Makie.convert_arguments(::Type{<:Arrows}, xrange::Makie.RangeLike, yrange::Makie.RangeLike, u_matrix::AbstractMatrix{<:Real}, v_matrix::AbstractMatrix{<:Real})
    xvec = Makie.to_vector(xrange, size(u_matrix, 1), Float32)
    yvec = Makie.to_vector(yrange, size(u_matrix, 2), Float32)
    data = Vec2f.(u_matrix, v_matrix)
    points = Point2f.(xvec, yvec')
    return PlotSpec(:Arrows, vec(points), vec(data), color=norm.(vec(data)))
end

function Makie.convert_arguments(::Type{<:LineSegments}, u_matrix::AbstractMatrix{<:Real}, v_matrix::AbstractMatrix{<:Real})
    xvec = 1:size(u_matrix, 1)
    yvec = 1:size(u_matrix, 2)
    directions = Point2f.(u_matrix, v_matrix)
    positions = Point2f.(xvec, yvec')
    points = map(positions, directions) do pos, dir
        return pos => (pos .+ dir)
    end
    norms = norm.(vec(directions))
    return PlotSpec(:LineSegments, convert_arguments(LineSegments, vec(points))..., cycle=[], color=norms)
end

function Makie.convert_arguments(::Type{<:LineSegments}, u_matrix::AbstractDimArray{<:Real}, v_matrix::AbstractDimArray{<:Real})
    xvec = collect(dims(u_matrix, 1))
    yvec = collect(dims(u_matrix, 2))
    directions = Point2f.(convert(Matrix{Float32}, u_matrix), convert(Matrix{Float32}, v_matrix))
    positions = Point2f.(xvec, yvec')
    points = map(positions, directions) do pos, dir
        return pos => (pos .+ (dir ./5))
    end
    radiance = map(vec(directions)) do p
        atan(p...)
    end
    return PlotSpec(:LineSegments, convert_arguments(LineSegments, vec(points))..., cycle=[], color=radiance)
end

@recipe(SpherePlot, image) do scene
    attr = Attributes()
    Makie.colormap_attributes!(attr, :viridis)
    attr
end

function Makie.plot!(p::SpherePlot)
    GB = Makie.GeometryBasics
    sm = GB.uv_normal_mesh(GB.Tesselation(Sphere(Point3f(0), 1.0f0), 100))
    mesh!(p, sm, color=map(x -> x', p[3]); Makie.colormap_attributes(p)...)
end
