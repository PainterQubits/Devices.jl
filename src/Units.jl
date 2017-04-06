using Unitful
import Unitful: °

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
