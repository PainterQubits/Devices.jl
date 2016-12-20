"""
```
type NoRender{T} <: ContinuousStyle{T} end
```
"""
type NoRender{T} <: ContinuousStyle{T} end
NoRender() = NoRender{Float64}()
