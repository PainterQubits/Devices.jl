"""
    struct CompoundStyle <: ContinuousStyle
        styles::Vector{Style}
        grid::Vector{Float64}
    end
Combines styles together, typically for use with a [`CompoundSegment`](@ref).

- `styles`: Array of styles making up the object. This is shallow-copied
by the outer constructor.
- `grid`: An array of `t` values needed for rendering the parameteric path.
"""
struct CompoundStyle{T<:FloatCoordinate} <: ContinuousStyle{false}
    styles::Vector{Style}
    grid::Vector{T}
end
function (s::CompoundStyle)(t)
    l0 = s.grid[1]
    t < l0 && return 1, t - l0
    for i in 2:(length(s.grid) - 1)
        l1 = s.grid[i]
        (l0 <= t) && (t < l1) && return (i-1), t-l0
        l0 = s.grid[i]
    end
    return length(s.grid) - 1, t - l0
end

CompoundStyle(seg::AbstractVector, sty::AbstractVector) =
    CompoundStyle(deepcopy(Vector{Style}(sty)), makegrid(seg, sty))

"""
    makegrid{T<:Segment}(segments::AbstractVector{T}, styles)
Returns a collection with the values of `t` to use for
rendering a `CompoundSegment` with a `CompoundStyle`.
"""
function makegrid(segments::AbstractVector{T}, styles) where T<:Segment
    isempty(segments) && error("Cannot use makegrid with zero segments.")
    length(segments) != length(styles) &&
        error("Must have same number of segments and styles.")

    grid = Vector{eltype(T)}(undef, length(segments)+1)
    grid[1] = zero(eltype(T))
    v = view(grid, 2:length(grid))
    v .= pathlength.(segments)
    cumsum!(grid,grid)
end

for x in (:extent, :width)
    @eval function ($x)(s::CompoundStyle, t)
        idx, teff = s(t)
        ($x)(s.styles[idx], teff)
    end
end

summary(::CompoundStyle) = "Compound style"
