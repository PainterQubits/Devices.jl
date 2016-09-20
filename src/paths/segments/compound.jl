
"""
```
type CompoundSegment{T} <: Segment{T}
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
type CompoundSegment{T} <: Segment{T}
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
