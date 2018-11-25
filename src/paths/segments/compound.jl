
"""
    struct CompoundSegment{T} <: ContinuousSegment{T}
Consider an array of segments as one contiguous segment.
Useful e.g. for applying styles, uninterrupted over segment changes.
The array of segments given to the constructor is copied and retained
by the compound segment.

Note that [`Corner`](@ref)s introduce a discontinuity in the derivative of the
path function, and are not allowed in a `CompoundSegment`.
"""
struct CompoundSegment{T} <: ContinuousSegment{T}
    segments::Vector{Segment{T}}

    function CompoundSegment{T}(segments) where {T}
        if any(x->isa(x,Corner), segments)
            error("cannot have corners in a `CompoundSegment`. You may have ",
                "tried to simplify a path containing `Corner` objects.")
        else
            new{T}(deepcopy(Array(segments)))
        end
    end
end

# Parametric function over the domain [zero(T),pathlength(c)] that represents the
# compound segments.
function (s::CompoundSegment{T})(t) where {T}
    c = s.segments
    R = promote_type(typeof(t), T)
    isempty(c) && error("cannot parameterize with zero segments.")

    L = pathlength(c)
    l0 = zero(L)

    for i in 1:length(c)
        seg = c[i]
        l1 = l0 + pathlength(seg)
        if l0 <= t < l1
            x = (seg)(t-l0)
            return x::Point{R}
        end
        l0 = l1
    end

    g = c[1]
    h = c[end]
    g′ = ForwardDiff.derivative(g, zero(L))::Point{Float64}
    h′ = ForwardDiff.derivative(h, pathlength(h))::Point{Float64}
    D0x, D0y = getx(g′), gety(g′)
    D1x, D1y = getx(h′), gety(h′)
    a0,a = p0(c[1]), p1(c[end])
    if t >= L
        x = a + Point(D1x * (t-L), D1y * (t-L))
        return x::Point{R}
    else
        x = a0 + Point(D0x * t, D0y * t)
        return x::Point{R}
    end
end

function _split(seg::CompoundSegment{T}, x) where {T}
    @assert zero(x) < x < pathlength(seg)
    c = seg.segments
    isempty(c) && error("cannot split a CompoundSegment based on zero segments.")

    L = pathlength(seg)
    l0 = zero(L)

    for i in firstindex(c):lastindex(c)
        seg = c[i]
        l1 = l0 + pathlength(seg)
        if l0 <= x < l1
            if x == l0 # can't happen on the firstindex because we have an assertion earlier
                # This is a clean split between segments
                seg1 = CompoundSegment{T}(c[firstindex(c):(i-1)])
                seg2 = CompoundSegment{T}(c[i:lastindex(c)])
                return seg1, seg2
            else
                s1, s2 = split(seg, x - l0)
                seg1 = CompoundSegment{T}(push!(c[firstindex(c):(i-1)], s1))
                seg2 = CompoundSegment{T}(pushfirst!(c[(i+1):lastindex(c)], s2))
                return seg1, seg2
            end
        end
        l0 = l1
    end
end

CompoundSegment(nodes::AbstractVector{Node{T}}) where {T} =
    CompoundSegment{T}(map(segment, nodes))

summary(s::CompoundSegment) = string(length(s.segments), " segments")
copy(s::CompoundSegment) = (typeof(s))(s.segments)
pathlength(s::CompoundSegment) = sum(pathlength, s.segments)

function setα0p0!(s::CompoundSegment, angle, p::Point)
    setα0p0!(s.segments[1], angle, p)
    for i in 2:length(s.segments)
        setα0p0!(s.segments[i], α1(s.segments[i-1]), p1(s.segments[i-1]))
    end
end
