immutable NoRender <: Style end
immutable NoRenderDiscrete <: DiscreteStyle end
immutable NoRenderContinuous <: ContinuousStyle end

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
SimpleNoRender{T<:Coordinate}(x::T) = SimpleNoRender{T}(x)

copy(x::NoRender) = NoRender()
copy{T<:NoRenderDiscrete}(x::T) = T()
copy{T<:NoRenderContinuous}(x::T) = T()
copy(x::SimpleNoRender) = SimpleNoRender(x.width)

@inline extent(s::NoRender, t) = zero(t)
@inline extent(s::SimpleNoRender, t...) = s.width/2
# @inline extent(s::GeneralNoRender, t...) = s.extent(t)

# The idea here is that the user should be able to specify NoRender() for either continuous
# or discrete styles, or NoRender(width) for SimpleNoRender.
convert(::Type{DiscreteStyle}, x::NoRender) = NoRenderDiscrete()
convert(::Type{ContinuousStyle}, x::NoRender) = NoRenderContinuous()
NoRender(width::Coordinate) = SimpleNoRender(float(width))
