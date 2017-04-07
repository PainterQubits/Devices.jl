"""
```
type Trace <: ContinuousStyle
    width::Function
    divs::Int
end
```

Simple, single trace.

- `width::Function`: trace width.
- `divs::Int`: number of segments to render. Increase if you see artifacts.
"""
type Trace <: ContinuousStyle
    width::Function
    divs::Int
end
Trace(width::Function) = Trace(width, 100)
Trace(width::Coordinate) = Trace(x->float(width), 1)
copy(x::Trace) = Trace(x.width, x.divs)
divs(s::Trace) = linspace(0.0, 1.0, s.divs+1)

distance(trace::Trace, t) = zero(trace.f(0))
extent(s::Trace, t) = s.width(t)/2
paths(::Trace, t...) = 1
width(s::Trace, t) = s.width(t)
