"""
```
type DecoratedStyle{T} <: ContinuousStyle{T}
    s::Style{T}
    ts::Array{Float64,1}
    dirs::Array{Int,1}
    refs::Array{CellReference{T},1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.refs = CellReference{T}[]
        a
    end
    DecoratedStyle(s,t,d,r) = new(s,t,d,r)
end
```

Style with decorations, like structures periodically repeated along the path, etc.
"""
type DecoratedStyle{T} <: ContinuousStyle{T}
    s::Style{T}
    ts::Array{Float64,1}
    dirs::Array{Int,1}
    refs::Array{CellReference{T},1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.refs = CellReference{T}[]
        a
    end
    DecoratedStyle(s,t,d,r) = new(s,t,d,r)
end
DecoratedStyle{T}(x::Style{T}) = DecoratedStyle{T}(x)

"""
```
undecorated(s::Style)
```

Returns `s`.
"""
undecorated(s::Style) = s

"""
```
undecorated(s::DecoratedStyle)
```

Returns the underlying, undecorated style.
"""
undecorated(s::DecoratedStyle) = s.s

divs(s::DecoratedStyle) = divs(undecorated(s))
extent(s::DecoratedStyle, t) = extent(undecorated(s), t)
