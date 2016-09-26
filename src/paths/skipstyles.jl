type SkipDiscrete{T} <: DiscreteStyle{T} end
type SkipContinuous{T} <: ContinuousStyle{T} end

type SkipRendering <: Style end
convert{T}(::Type{ContinuousStyle{T}}, x::SkipRendering) = SkipContinuous{T}()
convert{T}(::Type{DiscreteStyle{T}}, x::SkipRendering) = SkipDiscrete{T}()
