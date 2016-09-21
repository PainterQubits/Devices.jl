"""
```
type Trace{T} <: ContinuousStyle{T}
    width::Function
    divs::Int
end
```

Simple, single trace.

- `width::Function`: trace width.
- `divs::Int`: number of segments to render. Increase if you see artifacts.
"""
type Trace{T} <: ContinuousStyle{T}
    width::Function
    divs::Int
end
Trace(width::Function) = Trace{typeof(width(0.0))}(width, 100)
Trace(width::Coordinate) = Trace{typeof(float(width))}(x->float(width), 1)
copy{T}(x::Trace{T}) = Trace{T}(x.width, x.divs)
divs(s::Trace) = linspace(0.0, 1.0, s.divs+1)

distance{T}(::Trace{T}, t) = zero(T)
extent(s::Trace, t) = s.width(t)/2
paths(::Trace, t...) = 1
width(s::Trace, t) = s.width(t)
