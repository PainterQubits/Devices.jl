"""
```
type NoRender{T} <: ContinuousStyle{T} end
```
"""
type NoRender{T} <: ContinuousStyle{T} end
NoRender() = NoRender{Float64}()
copy(x::NoRender) = NoRender()

distance{T}(s::NoRender{T}, t) = zero(T)
extent{T}(s::NoRender{T}, t) = zero(T)
paths(::NoRender, t...) = 0
width{T}(s::NoRender{T}, t) = zero(T)
divs(s::NoRender) = [0.0, 1.0]
