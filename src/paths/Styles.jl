function deepcopy_internal(x::Style, stackdict::ObjectIdDict)
    if haskey(stackdict, x)
        return stackdict[x]
    end
    y = copy(x)
    stackdict[x] = y
    return y
end
"""
```
type Trace{T} <: Style{T}
    width::Function
    divs::Int
end
```

Simple, single trace.

- `width::Function`: trace width.
- `divs::Int`: number of segments to render. Increase if you see artifacts.
"""
type Trace{T} <: Style{T}
    width::Function
    divs::Int
end
Trace(width::Function) = Trace{typeof(width(0.0))}(width, 100)
Trace(width::Coordinate) = Trace{typeof(float(width))}(x->float(width), 1)
copy{T}(x::Trace{T}) = Trace{T}(x.width, x.divs)
divs(s::Trace) = linspace(0.0, 1.0, s.divs+1)

# # experimental
# import Roots:fzeros
# function divs(f::Function, FType, dens)
#     # find zeros of f′ to locate extrema
#     D = ForwardDiff.derivative
#     extr = fzeros(x->D(f,x), 0.0, 1.0)
#     mi,ma = extrema(f.(extr))
#     normcurv = x->D(x->D(x->(f(x)-mi)/ma,x), x)
#     divs = Float64[]
#     !(extr[1] ≈ 0.0) && unshift!(extr, 0.0)
#     !(extr[end] ≈ 1.0) && push!(extr, 1.0)
#
#     for (i, start) in enumerate(extr[1:(end-1)])
#         push!(divs, start)
#         stop = extr[i+1]
#         where = start
#         while where < stop
#             push!(divs, where += dens/normcurv(where))
#         end
#         start = stop
#     end
#     push!(divs, extr[end])
#     # mm = D2nd.(zeros)
#     # minima = zeros[mm .> 0]
#     # maxima = zeros[mm .< 0]
#
# end

distance{T}(::Trace{T}, t) = zero(T)
extent(s::Trace, t) = s.width(t)/2
paths(::Trace, t...) = 1
width(s::Trace, t) = s.width(t)

"""
```
type CPW{T} <: Style{T}
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
type CPW{T} <: Style{T}
    trace::Function
    gap::Function
    divs::Int
end
function CPW(trace::Coordinate, gap::Coordinate)
    dimension(trace) != dimension(gap) && throw(DimensionError())
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

"""
```
type CompoundStyle <: Style
    styles::Array{Style,1}
    divs::Array{Float64,1}
    f::Function
end
```

Combines styles together, typically for use with a [`CompoundSegment`](@ref).

- `styles`: Array of styles making up the object. This is shallow-copied
by the outer constructor.
- `divs`: An array of `t` values needed for rendering the parameteric path.
- `f`: returns tuple of style index and the `t` to use for that
style's parametric function.
"""
type CompoundStyle <: Style
    styles::Array{Style,1}
    divs::Array{Float64,1}
    f::Function
end
CompoundStyle{S<:Segment,T<:Style}(seg::AbstractArray{S,1},
        sty::AbstractArray{T,1}) =
    CompoundStyle(deepcopy(Array(sty)), makedivs(seg, sty), cstylef(seg))

divs(s::CompoundStyle) = s.divs

"""
`makedivs{T<:Real}(segments::CompoundStyle{T}, styles::CompoundStyle)`

Returns a collection with the values of `t` to use for
rendering a `CompoundSegment` with a `CompoundStyle`.
"""
function makedivs{T<:Number}(segments::AbstractArray{Segment{T},1}, styles)
    isempty(segments) && error("Cannot use divs with zero segments.")
    length(segments) != length(styles) &&
        error("Must have same number of segments and styles.")

    L = pathlength(segments)
    l0 = zero(T)
    ts = Float64[]
    for i in 1:length(segments)
        l1 = l0 + pathlength(segments[i])
        # Someone who enjoys thinking about IEEE floating points,
        # please make this less awful. It seems like the loop runs
        # approximately powers-of-2 times.

        # Start just past the boundary to pick the right style
        offset = l0/L + eps(l0/L)

        # Go almost to the next boundary
        scale = (l1/L-offset)
        while offset+scale*1.0 >= l1/L
            scale -= eps(scale)
        end

        append!(ts, divs(styles[i])*scale+offset)
        l0 = l1
    end
    sort!(unique(ts))
end

"""
`cstylef{T<:Real}(seg::AbstractArray{Segment{T},1})`

Returns the function needed for a `CompoundStyle`. The segments array is
shallow-copied for use in the function.
"""
function cstylef{T<:Real}(seg::AbstractArray{Segment{T},1})
    segments = deepcopy(Array(seg))
    isempty(segments) && error("Cannot parameterize with zero segments.")

    # Build up our piecewise parametric function
    f = Expr(:(->), :t, Expr(:block))
    push!(f.args[2].args, quote
        L = pathlength($segments)
        l0 = zero($T)
    end)

    for i in 1:length(segments)
        push!(f.args[2].args, quote
            l1 = l0 + pathlength(($segments)[$i])
            (l0/L <= t) &&
                ($(i == length(segments) ? :(<=) : :(<))(t, l1/L)) &&
                    return $i, (t*L-l0)/(l1-l0)
            l0 = l1
        end)
    end

    # Return our parametric function
    return eval(f)
end

for x in (:distance, :extent, :paths, :width)
    @eval function ($x)(s::CompoundStyle, t)
        idx, teff = s.f(t)
        ($x)(s.styles[idx], teff)
    end
end

"""
```
type DecoratedStyle <: Style
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
type DecoratedStyle <: Style
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
