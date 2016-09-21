
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
CompoundSegment{T}(nodes::AbstractArray{Node{T},1}) =
    CompoundSegment{T}(map(segment, nodes))

copy{T}(s::CompoundSegment{T}) = CompoundSegment{T}(s.segments)

function setα0p0!(s::CompoundSegment, angle, p::Point)
    setα0p0!(s.segments[1], angle, p)
    for i in 2:length(s.segments)
        setα0p0!(s.segments[i], α1(s.segments[i-1]), p1(s.segments[i-1]))
    end
end

"""
```
param{T<:Coordinate}(c::AbstractVector{Segment{T}})
```

Return a parametric function over the domain [0,1] that represents the
compound segments.
"""
function param{T<:Coordinate}(c::AbstractVector{Segment{T}})
    isempty(c) && error("Cannot parameterize with zero segments.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength(($c))
        l0 = zero($T)
    end)

    for i in 1:length(c)
        push!(f.args[2].args, quote
            fn = (($c))[$i].f
            l1 = l0 + pathlength((($c))[$i])
            (l0/L <= t < l1/L) && return (fn)((t*L-l0)/(l1-l0))
            l0 = l1
        end)
    end

    # For continuity of the derivative
    push!(f.args[2].args, quote
        g = (($c))[1].f
        h = (($c))[end].f
        g′ = ForwardDiff.derivative(g,0.0)
        h′ = ForwardDiff.derivative(h,1.0)
        D0x, D0y = getx(g′), gety(g′)
        D1x, D1y = getx(h′), gety(h′)
        a0,a = p0((($c))[1]),p1((($c))[end])
        l0,l1 = pathlength((($c))[1]), pathlength((($c))[end])
        (t >= 1.0) &&
            return a + Point(D1x*(t-1)*(L/l1), D1y*(t-1)*(L/l1))
        (t < 0.0) &&
            return a0 + Point(D0x*t*(L/l0), D0y*t*(L/l0))
    end)

    # Return our parametric function
    return eval(f)
end
