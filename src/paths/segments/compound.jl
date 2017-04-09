
"""
```
type CompoundSegment{T} <: ContinuousSegment{T}
    segments::Vector{Segment{T}}
    f::Function

    CompoundSegment(segments) = begin
        if any(x->isa(x,Corner), segments)
            error("cannot have corners in a `CompoundSegment`. You may have ",
                "tried to simplify a path containing `Corner` objects.")
        else
            s = new(deepcopy(Array(segments)))
            s.f = param(s.segments)
            s
        end
    end
end
```

Consider an array of segments as one contiguous segment.
Useful e.g. for applying styles, uninterrupted over segment changes.
The array of segments given to the constructor is copied and retained
by the compound segment.

Note that [`Corner`](@ref)s introduce a discontinuity in the derivative of the
path function, and are not allowed in a `CompoundSegment`.
"""
type CompoundSegment{T} <: ContinuousSegment{T}
    segments::Vector{Segment{T}}
    f::Function

    CompoundSegment(segments) = begin
        if any(x->isa(x,Corner), segments)
            error("cannot have corners in a `CompoundSegment`. You may have ",
                "tried to simplify a path containing `Corner` objects.")
        else
            s = new(deepcopy(Array(segments)))
            s.f = param(s.segments)
            s
        end
    end
end
(s::CompoundSegment)(args...) = (s.f)(args...)
CompoundSegment{T}(nodes::AbstractArray{Node{T},1}) =
    CompoundSegment{T}(map(segment, nodes))

copy{T}(s::CompoundSegment{T}) = CompoundSegment{T}(s.segments)
pathlength(s::CompoundSegment) = sum(pathlength, s.segments)

function setα0p0!(s::CompoundSegment, angle, p::Point)
    setα0p0!(s.segments[1], angle, p)
    for i in 2:length(s.segments)
        setα0p0!(s.segments[i], α1(s.segments[i-1]), p1(s.segments[i-1]))
    end
end

# Return a parametric function over the domain [zero(T),pathlength(c)] that represents the
# compound segments.
function param(c::AbstractVector)
    isempty(c) && error("Cannot parameterize with zero segments.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength($c)
        l0 = zero(L)
    end)

    for i in 1:length(c)
        push!(f.args[2].args, quote
            seg = ($c)[$i]
            l1 = l0 + pathlength(seg)
            (l0 <= t < l1) && return (seg)(t-l0)
            l0 = l1
        end)
    end

    # For continuity of the derivative
    push!(f.args[2].args, quote
        g = ($c)[1]
        h = ($c)[end]
        g′ = ForwardDiff.derivative(g, zero(L))
        h′ = ForwardDiff.derivative(h, L)
        D0x, D0y = getx(g′), gety(g′)
        D1x, D1y = getx(h′), gety(h′)
        a0,a = p0(($c)[1]), p1(($c)[end])
        (t >= L) &&
            return a + Point(D1x * (t-L), D1y * (t-L))
        (t < zero(L)) &&
            return a0 + Point(D0x * t, D0y * t)
    end)

    # Return our parametric function
    return eval(f)
end
