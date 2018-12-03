struct NoRender <: Style end
struct NoRenderDiscrete <: DiscreteStyle end
struct NoRenderContinuous <: ContinuousStyle{false} end

"""
    struct SimpleNoRender{T} <: ContinuousStyle{false}
        width::T
    end
A style that inhibits path rendering, but pretends to have a finite width for
[`Paths.attach!`](@ref).
"""
struct SimpleNoRender{T} <: ContinuousStyle{false}
    width::T
end
SimpleNoRender(x::T) where {T <: Coordinate} = SimpleNoRender{T}(x)

copy(x::NoRender) = NoRender()
copy(x::T) where {T <: NoRenderDiscrete} = T()
copy(x::T) where {T <: NoRenderContinuous} = T()
copy(x::SimpleNoRender) = SimpleNoRender(x.width)

@inline extent(s::NoRender, t) = zero(t)
@inline extent(s::SimpleNoRender, t...) = s.width/2
# @inline extent(s::GeneralNoRender, t...) = s.extent(t)

# The idea here is that the user should be able to specify NoRender() for either continuous
# or discrete styles, or NoRender(width) for SimpleNoRender.
convert(::Type{DiscreteStyle}, x::NoRender) = NoRenderDiscrete()
convert(::Type{ContinuousStyle}, x::NoRender) = NoRenderContinuous()
NoRender(width::Coordinate) = SimpleNoRender(float(width))

translate(s::SimpleNoRender, t) = copy(s)
translate(s::NoRenderContinuous, t) = copy(s)
