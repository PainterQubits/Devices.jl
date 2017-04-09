using Unitful
import Unitful: °,rad
export °,rad

module PreferNanometers
    import Unitful
    for s in (:fm, :pm, :nm, :μm, :mm, :cm, :dm, :m)
        eval(PreferNanometers, :(const $s = Unitful.ContextUnits(Unitful.$s, Unitful.nm)))
        eval(PreferNanometers, Expr(:export, s))
    end
end

module PreferMicrons
    import Unitful
    for s in (:fm, :pm, :nm, :μm, :mm, :cm, :dm, :m)
        eval(PreferMicrons, :(const $s = Unitful.ContextUnits(Unitful.$s, Unitful.μm)))
        eval(PreferMicrons, Expr(:export, s))
    end
end

function ForwardDiff.derivative(f, x::Unitful.Length)
    ux = Unitful.ustrip(x)
    ox = one(ux)
    r = f(Unitful.unit(x)*ForwardDiff.Dual(ux,ox)) ./ (typeof(x)(one(x)))
    ForwardDiff.extract_derivative(r)
end

function ForwardDiff.extract_derivative(x::Quantity)
    ForwardDiff.extract_derivative(Unitful.ustrip(x))*Unitful.unit(x)
end
