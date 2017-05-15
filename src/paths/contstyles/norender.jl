"""
    immutable NoRender <: ContinuousStyle end
A style that inhibits path rendering.
"""
immutable NoRender <: ContinuousStyle end

"""
    immutable SimpleNoRender{T} <: ContinuousStyle
        width::T
    end
A style that inhibits path rendering, but pretends to have a finite width for
[`Paths.attach!`](@ref).
"""
immutable SimpleNoRender{T} <: ContinuousStyle
    width::T
end

NoRender(width::Coordinate) = SimpleNoRender(float(width))

copy(x::NoRender) = NoRender()
copy(x::SimpleNoRender) = SimpleNoRender(x.width)

@inline extent(s::NoRender, t) = zero(t)
@inline extent(s::SimpleNoRender, t...) = s.width/2
# @inline extent(s::GeneralNoRender, t...) = s.extent(t)
