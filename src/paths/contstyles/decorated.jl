"""
    mutable struct DecoratedStyle{T<:FloatCoordinate} <: ContinuousStyle{false}
        s::Style
        ts::Array{Float64,1}
        dirs::Array{Int,1}
        refs::Array{CellReference,1}
    end
Style with decorations, like structures periodically repeated along the path, etc.
"""
mutable struct DecoratedStyle{T<:FloatCoordinate} <: ContinuousStyle{false}
    s::Style
    ts::Array{T,1}
    dirs::Array{Int,1}
    refs::Array{CellReference,1}
end
summary(s::DecoratedStyle) = string(summary(s.s), " with ", length(s.refs), " decorations")

"""
    undecorated(s::DecoratedStyle)
    undecorated(s::Style)
Returns the underlying, undecorated style if decorated; otherwise just return the style.
"""
undecorated(s::Style) = s
undecorated(s::DecoratedStyle) = s.s

extent(s::DecoratedStyle, t...) = extent(undecorated(s), t...)

"""
    attach!(p::Path, c::CellReference, t::Coordinate;
        i::Integer=length(p), location::Integer=0)
    attach!(p::Path, c::CellReference, t;
        i::Integer=length(p), location=zeros(Int, length(t)))
Attach `c` along a path. The second method permits ranges or arrays of `t` and `location`
to be specified (if the lengths do not match, `location` is cycled).

By default, the attachment(s) occur at `t ∈ [zero(pathlength(s)),pathlength(s)]` along the
most recent path segment `s`, but a different path segment index can be specified using `i`.
The reference is oriented with zero rotation if the path is pointing at 0°, otherwise it is
rotated with the path.

The origin of the cell reference tells the method where to place the cell *with
respect to a coordinate system that rotates with the path*. Suppose the path is
a straight line with angle 0°. Then an origin of `Point(0.,10.)` will put the
cell at 10 above the path, or 10 to the left of the path if it turns left by
90°.

The `location` option is for convenience. If `location == 0`, nothing special happens.
If `location == -1`, then the point of attachment for the reference is on the
leftmost edge of the waveguide (the rendered polygons; the path itself has no
width). Likewise if `location == 1`, the point of attachment is on the rightmost
edge. This option does not automatically rotate the cell reference, apart from
what is already done as described in the first paragraph. You can think of this
option as setting a special origin for the coordinate system that rotates with
the path. For instance, an origin for the cell reference of `Point(0.,10.)`
together with `location == -1` will put the cell at 10 above the edge of a
rendered (finite width) path with angle 0°.
"""
function attach!(p::Path, c::CellReference, t::Coordinate;
        i::Int=length(p), location::Int=0)
    i==0 && error("cannot attach to an empty path.")
    node = p[i]
    seg0,sty0 = segment(node), style(node)
    sty = decorate(sty0, eltype(p), t, location, c)
    p[i] = Node(seg0, sty)
    sty
end

function attach!(p::Path, c::CellReference, t;
        i::Int=length(p), location=zeros(Int, length(t)))
    for (ti, li) in zip(t, Iterators.cycle(location))
        attach!(p, c, ti; i=i, location=li)
    end
end

# undocumented private methods for attach!
function decorate(sty0::Style, T, t, location, c)
    @assert -1 <= location <= 1
    DecoratedStyle{T}(sty0, T[t], Int[location], CellReference[c])
end

function decorate(sty::DecoratedStyle, T, t, location, c)
    @assert -1 <= location <= 1
    push!(sty.ts, t)
    push!(sty.dirs, location)
    push!(sty.refs, c)
    sty
end
