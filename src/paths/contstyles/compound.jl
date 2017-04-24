"""
    type CompoundStyle <: ContinuousStyle
        styles::Vector{Style}
        grid::Vector{Float64}
        f::Function
    end
Combines styles together, typically for use with a [`CompoundSegment`](@ref).

- `styles`: Array of styles making up the object. This is shallow-copied
by the outer constructor.
- `grid`: An array of `t` values needed for rendering the parameteric path.
- `f`: returns tuple of style index and the `t` to use for that
style's parametric function.
"""
type CompoundStyle{T<:FloatCoordinate} <: ContinuousStyle
    styles::Vector{Style}
    grid::Vector{T}
    f::Function
end
CompoundStyle(seg::AbstractVector, sty::AbstractVector) =
    CompoundStyle(deepcopy(Vector{Style}(sty)), makegrid(seg, sty), cstylef(seg))

grid(s::CompoundStyle) = s.grid

"""
    makegrid{T<:Segment}(segments::AbstractVector{T}, styles)
Returns a collection with the values of `t` to use for
rendering a `CompoundSegment` with a `CompoundStyle`.
"""
function makegrid{T<:Segment}(segments::AbstractVector{T}, styles)
    isempty(segments) && error("Cannot use makegrid with zero segments.")
    length(segments) != length(styles) &&
        error("Must have same number of segments and styles.")

    grid = Vector{eltype(T)}(length(segments)+1)
    grid[1] = zero(eltype(T))
    v = view(grid, 2:length(grid))
    v .= pathlength.(segments)
    cumsum!(grid,grid)
end

"""
    cstylef{T<:Coordinate}(seg::AbstractArray{Segment{T},1})
Returns the function needed for a `CompoundStyle`. The segments array is
deep-copied for use in the function.
"""
function cstylef{T<:Coordinate}(seg::AbstractArray{Segment{T},1})
    segments = deepcopy(Array(seg))
    isempty(segments) && error("Cannot parameterize with zero segments.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength($segments)
        l0 = zero($T)
    end)

    for i in 1:length(segments)
        push!(f.args[2].args, quote
            l1 = l0 + pathlength(($segments)[$i])
            (l0 <= t) &&
                ($(i == length(segments) ? :(<=) : :(<))(t, l1)) &&
                    return $i, t-l0
            l0 = l1
        end)
    end

    # Return our parametric function
    return eval(f)
end

for x in (:extent, :width)
    @eval function ($x)(s::CompoundStyle, t)
        idx, teff = s.f(t)
        ($x)(s.styles[idx], teff)
    end
end
