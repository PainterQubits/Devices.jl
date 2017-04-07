"""
```
type NoRender <: ContinuousStyle end
```
"""
type NoRender <: ContinuousStyle end
copy(x::NoRender) = NoRender()

distance(s::NoRender, t) = zero(T)
extent(s::NoRender, t) = zero(T)
paths(::NoRender, t...) = 0
width(s::NoRender, t) = zero(T)
divs(s::NoRender) = [0.0, 1.0]
