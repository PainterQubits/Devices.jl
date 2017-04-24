type SkipDiscrete <: DiscreteStyle end
type SkipContinuous <: ContinuousStyle end

type SkipRendering <: Style end
convert(::Type{ContinuousStyle}, x::SkipRendering) = SkipContinuous()
convert(::Type{DiscreteStyle}, x::SkipRendering) = SkipDiscrete()
