"""
```
type CPW{T} <: ContinuousStyle{T}
    trace::Function
    gap::Function
    divs::Int
end
```

Two adjacent traces can form a coplanar waveguide.

- `trace::Function`: center conductor width.
- `gap::Function`: distance between center conductor edges and ground plane
- `divs::Int`: number of segments to render. Increase if you see artifacts.

May need to be inverted with respect to a ground plane,
depending on how the pattern is written.
"""
type CPW{T} <: ContinuousStyle{T}
    trace::Function
    gap::Function
    divs::Int
end
function CPW(trace::Coordinate, gap::Coordinate)
    dimension(trace) != dimension(gap) && throw(DimensionError(trace,gap))
    t,g = promote(float(trace), float(gap))
    CPW{typeof(t)}(x->t, x->g, 1)
end
function CPW(trace::Function, gap::Function)
    T = promote_type(typeof(trace(0)), typeof(gap(0)))
    CPW{T}(x->T(trace(x)), x->T(gap(x)), 100)
end
function CPW(trace::Function, gap::Coordinate, divs::Integer=100)
    T = promote_type(typeof(trace(0)), typeof(float(gap)))
    CPW{T}(x->T(trace(x)), x->T(float(gap)), divs)
end
function CPW(trace::Coordinate, gap::Function, divs::Integer=100)
    T = promote_type(typeof(float(trace)), typeof(gap(0)))
    CPW{T}(x->T(float(trace)), x->T(gap(x)), divs)
end
copy{T}(x::CPW{T}) = CPW{T}(x.trace, x.gap, x.divs)

distance(s::CPW, t) = s.gap(t)+s.trace(t)
extent(s::CPW, t) = s.trace(t)/2 + s.gap(t)
paths(::CPW, t...) = 2
width(s::CPW, t) = s.gap(t)
divs(s::CPW) = linspace(0.0, 1.0, s.divs+1)
