immutable NoRender <: Style end
immutable NoRenderDiscrete{T} <: DiscreteStyle{T} end
immutable NoRenderContinuous{T} <: ContinuousStyle{T} end

# The idea here is that the user should be able to specify NoRender() for either continuous
# or discrete styles, or NoRender(width) for SimpleNoRender.
convert{T}(::Type{DiscreteStyle{T}}, x::NoRender) = NoRenderDiscrete{T}()
convert{T}(::Type{ContinuousStyle{T}}, x::NoRender) = NoRenderContinuous{T}()
convert{T,U}(::Type{ContinuousStyle{T}}, x::SimpleNoRender{U}) = SimpleNoRender{U,T}(x.width)
NoRender(width::Coordinate) = SimpleNoRender(float(width))

"""
    immutable SimpleNoRender{S,T} <: ContinuousStyle{T}
        width::S
    end
A style that inhibits path rendering, but pretends to have a finite width for
[`Paths.attach!`](@ref).
"""
immutable SimpleNoRender{S,T} <: ContinuousStyle{T}
    width::S
end
SimpleNoRender{S<:Coordinate}(x::S) = SimpleNoRender{S,GDSMeta}(x)

copy(x::NoRender) = NoRender()
copy{T<:NoRenderDiscrete}(x::T) = T()
copy{T<:NoRenderContinuous}(x::T) = T()
copy(x::SimpleNoRender) = SimpleNoRender(x.width)

@inline extent(s::NoRender, t) = zero(t)
@inline extent(s::SimpleNoRender, t...) = s.width/2
# @inline extent(s::GeneralNoRender, t...) = s.extent(t)
