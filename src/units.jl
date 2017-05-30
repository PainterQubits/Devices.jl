using Unitful
import Unitful: °,rad
export °,rad

module PreferNanometers
    import Unitful
    syms = (:fm, :pm, :nm, :μm, :mm, :cm, :dm, :m)
    for s in syms
        eval(PreferNanometers, :(const $s = Unitful.ContextUnits(Unitful.$s, Unitful.nm)))
        eval(PreferNanometers, Expr(:export, s))
    end

    # nums = (1, 1.0)
    # for s in syms, t in syms, n1 in nums, n2 in nums
    #     @eval precompile(+, (typeof($n1*($s)), typeof($n2*($t))))
    #     @eval precompile(-, (typeof($n1*($s)), typeof($n2*($t))))
    #     @eval precompile(+, (typeof($n1*($s)), typeof($n2*(Unitful.$t))))
    #     @eval precompile(-, (typeof($n1*($s)), typeof($n2*(Unitful.$t))))
    # end
end

module PreferMicrons
    import Unitful
    syms = (:fm, :pm, :nm, :μm, :mm, :cm, :dm, :m)
    for s in syms
        eval(PreferMicrons, :(const $s = Unitful.ContextUnits(Unitful.$s, Unitful.μm)))
        eval(PreferMicrons, Expr(:export, s))
    end

    # nums = (1, 1.0)
    # for s in syms, t in syms, n1 in nums, n2 in nums
    #     @eval precompile(+, (typeof($n1*($s)), typeof($n2*($t))))
    #     @eval precompile(-, (typeof($n1*($s)), typeof($n2*($t))))
    #     @eval precompile(+, (typeof($n1*($s)), typeof($n2*(Unitful.$t))))
    #     @eval precompile(-, (typeof($n1*($s)), typeof($n2*(Unitful.$t))))
    # end
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
