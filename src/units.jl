using Unitful
import Unitful: °,rad
export °,rad

module PreferNanometers
    import Unitful
    syms = (:fm, :pm, :nm, :μm, :mm, :cm, :dm, :m)
    for s in syms
        eval(:(const $s = Unitful.ContextUnits(Unitful.$s, Unitful.nm)))
        eval(Expr(:export, s))
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
        eval(:(const $s = Unitful.ContextUnits(Unitful.$s, Unitful.μm)))
        eval(Expr(:export, s))
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
    T = typeof(ForwardDiff.Tag(nothing, typeof(ux)))
    r = f(Unitful.unit(x)*ForwardDiff.Dual{T}(ux,ox)) ./ oneunit(x)
    ForwardDiff.extract_derivative(T, r)
end

ForwardDiff.extract_derivative(::Type{T}, x::Quantity) where {T} =
    ForwardDiff.extract_derivative(T, Unitful.ustrip(x)) * Unitful.unit(x)
