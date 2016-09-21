"""
```
type CompoundStyle{T} <: ContinuousStyle{T}
    styles::Vector{Style{T}}
    divs::Vector{Float64}
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
type CompoundStyle{T} <: ContinuousStyle{T}
    styles::Vector{Style{T}}
    divs::Vector{Float64}
    f::Function
end
CompoundStyle{S<:Segment,T<:Style}(seg::AbstractVector{S}, sty::AbstractVector{T}) =
    CompoundStyle{T.parameters[1]}(deepcopy(Array(sty)), makedivs(seg, sty), cstylef(seg))

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
```
cstylef{T<:Coordinate}(seg::AbstractArray{Segment{T},1})
```

Returns the function needed for a `CompoundStyle`. The segments array is
shallow-copied for use in the function.
"""
function cstylef{T<:Coordinate}(seg::AbstractArray{Segment{T},1})
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
