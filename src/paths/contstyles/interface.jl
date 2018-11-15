"""
    extent(s::Style, t)
For a style `s`, returns a distance tangential to the path specifying the lateral extent
of the polygons rendered. The extent is measured from the center of the path to the edge
of the polygon (half the total width along the path). The extent is evaluated at path length
`t` from the start of the associated segment.
"""
function extent end

"""
    width(s::Style, t)
For a style `s` and parameteric argument `t`, returns the width of paths rendered.
"""
function width end

"""
    translate(s::ContinuousStyle, x)
Creates a style `s′` such that all properties `f(s′, t) == f(s, t+x)`. Basically, advance
the style forward by path length `x`.
"""
function translate end
