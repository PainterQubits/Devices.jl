
"""
    struct CompoundSegment{T} <: ContinuousSegment{T}
        segments::Vector{Segment{T}}

        CompoundSegment(segments) = begin
            if any(x->isa(x,Corner), segments)
                error("cannot have corners in a `CompoundSegment`. You may have ",
                    "tried to simplify a path containing `Corner` objects.")
            else
                new(deepcopy(Array(segments)))
            end
        end
    end
Consider an array of segments as one contiguous segment.
Useful e.g. for applying styles, uninterrupted over segment changes.
The array of segments given to the constructor is copied and retained
by the compound segment.

Note that [`Corner`](@ref)s introduce a discontinuity in the derivative of the
path function, and are not allowed in a `CompoundSegment`.
"""
struct CompoundSegment{T} <: ContinuousSegment{T}
    segments::Vector{Segment{T}}

    CompoundSegment{T}(segments) where {T} = begin
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

CompoundSegment(nodes::AbstractArray{Node{T},1}) where {T} =
    CompoundSegment{T}(map(segment, nodes))

summary(s::CompoundSegment) = string(length(s.segments), " segments")
copy(s::CompoundSegment{T}) where {T} = CompoundSegment{T}(s.segments)
pathlength(s::CompoundSegment{T}) where {T} = sum(pathlength, s.segments)

function setα0p0!(s::CompoundSegment, angle, p::Point)
    setα0p0!(s.segments[1], angle, p)
    for i in 2:length(s.segments)
        setα0p0!(s.segments[i], α1(s.segments[i-1]), p1(s.segments[i-1]))
    end
end
