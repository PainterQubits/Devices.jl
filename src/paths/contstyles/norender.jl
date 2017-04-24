"""
```
immutable NoRender <: ContinuousStyle end
```
"""
immutable NoRender <: ContinuousStyle end
copy(x::NoRender) = NoRender()
