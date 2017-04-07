"""
```
type DecoratedStyle <: ContinuousStyle
    s::Style
    ts::Array{Float64,1}
    dirs::Array{Int,1}
    refs::Array{CellReference,1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.refs = CellReference[]
        a
    end
    DecoratedStyle(s,t,d,r) = new(s,t,d,r)
end
```

Style with decorations, like structures periodically repeated along the path, etc.
"""
type DecoratedStyle <: ContinuousStyle
    s::Style
    ts::Array{Float64,1}
    dirs::Array{Int,1}
    refs::Array{CellReference,1}
    DecoratedStyle(s) = begin
        a = new(s)
        a.ts = Float64[]
        a.dirs = Int[]
        a.refs = CellReference[]
        a
    end
    DecoratedStyle(s,t,d,r) = new(s,t,d,r)
end
DecoratedStyle(x::Style) = DecoratedStyle(x)

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


"""
```
attach!(p::Path, c::CellReference, t::Real; i::Integer=length(p), where::Integer=0)
```

Attach `c` along a path.

By default, the attachment occurs at `t ∈ [0,1]` along the most recent path
segment, but a different path segment index can be specified using `i`. The
reference is oriented with zero rotation if the path is pointing at 0°,
otherwise it is rotated with the path.

The origin of the cell reference tells the method where to place the cell *with
respect to a coordinate system that rotates with the path*. Suppose the path is
a straight line with angle 0°. Then an origin of `Point(0.,10.)` will put the
cell at 10 above the path, or 10 to the left of the path if it turns left by
90°.

The `where` option is for convenience. If `where == 0`, nothing special happens.
If `where == -1`, then the point of attachment for the reference is on the
leftmost edge of the waveguide (the rendered polygons; the path itself has no
width). Likewise if `where == 1`, the point of attachment is on the rightmost
edge. This option does not automatically rotate the cell reference, apart from
what is already done as described in the first paragraph. You can think of this
option as setting a special origin for the coordinate system that rotates with
the path. For instance, an origin for the cell reference of `Point(0.,10.)`
together with `where == -1` will put the cell at 10 above the edge of a
rendered (finite width) path with angle 0°.
"""
function attach!(p::Path, c::CellReference, t::Real;
        i::Integer=length(p), where::Integer=0)
    if i==0
        sty0 = style0(p)
        sty = decorate(sty0,c,t,where)
        p.style0 = sty
    else
        node = p[i]
        seg0,sty0 = segment(node), style(node)
        sty = decorate(sty0,c,t,where)
        p[i] = Node(seg0,sty)
    end
end

# undocumented private methods for attach!
function decorate(sty0::Style, c, t, where)
    sty = DecoratedStyle(sty0)
    decorate(sty,c,t,where)
end

# undocumented private methods for attach!
function decorate(sty::DecoratedStyle, c, t, where)
    push!(sty.ts, t)
    push!(sty.dirs, where)
    push!(sty.refs, c)
    sty
end
