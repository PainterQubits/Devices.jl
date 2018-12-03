"""
    struct CompoundStyle{T<:FloatCoordinate} <: ContinuousStyle{false}
        styles::Vector{Style}
        grid::Vector{T}
    end
Combines styles together, typically for use with a [`CompoundSegment`](@ref).

- `styles`: Array of styles making up the object. This is deep-copied by the outer
  constructor.
- `grid`: An array of `t` values needed for rendering the parameteric path.
"""
struct CompoundStyle{T<:FloatCoordinate} <: ContinuousStyle{false}
    styles::Vector{Style}
    grid::Vector{T}
    tag::Symbol
end
function (s::CompoundStyle)(t)
    l0 = s.grid[1]
    t < l0 && return s.styles[1], t - l0
    for i in 2:(length(s.grid) - 1)
        l1 = s.grid[i]
        (l0 <= t) && (t < l1) && return s.styles[i-1], t - l0
        l0 = s.grid[i]
    end
    return s.styles[length(s.grid) - 1], t - l0
end
copy(s::CompoundStyle, tag=gensym()) = (typeof(s))(deepcopy(s.styles), copy(s.grid), tag)
CompoundStyle(seg::AbstractVector{Segment{T}}, sty::AbstractVector, tag=gensym()) where {T} =
    CompoundStyle(deepcopy(Vector{Style}(sty)), makegrid(seg, sty), tag)

"""
    makegrid(segments::AbstractVector{T}, styles) where {T<:Segment}
Returns a collection with the values of `t` to use for
rendering a `CompoundSegment` with a `CompoundStyle`.
"""
function makegrid(segments::AbstractVector{T}, styles) where {T<:Segment}
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
        sty, teff = s(t)
        ($x)(sty, teff)
    end
end

summary(::CompoundStyle) = "Compound style"

function translate(s::CompoundStyle, x, tag=gensym())
    s′ = copy(s, tag)
    s′.grid .-= x
    return s′
end

function pin(s::CompoundStyle; start=nothing, stop=nothing, tag=gensym())
    if start !== nothing
        return translate(s, start, tag)
    end
    return copy(s, tag)
end
