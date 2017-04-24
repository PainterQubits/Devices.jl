"""
```
render!(c::Cell, segment::Paths.Segment, s::Paths.DecoratedStyle; kwargs...)
```

Render a `segment` with decorated style `s` to cell `c`.
Cell references held by the decorated style will have their fields modified
by this method, which is why they are shallow copied in the
[`Paths.attach!`](@ref) function.

This method draws the decorations before the path itself is drawn.
"""
function render!(c::Cell, segment::Paths.Segment, s::Paths.DecoratedStyle; kwargs...)
    for (t, dir, cref) in zip(s.ts, s.dirs, s.refs)
        (dir < -1 || dir > 1) && error("Invalid direction in $s.")

        ref = copy(cref)

        rot = direction(segment, t)
        if dir == 0
            ref.origin = Point(Rotation(rot)(ref.origin))
            ref.origin += segment(t)
            ref.rot += rot
        else
            if dir == -1
                rot2 = rot + π/2
            else
                rot2 = rot - π/2
            end

            offset = Paths.extent(s.s, t)
            newx = offset * cos(rot2)
            newy = offset * sin(rot2)
            ref.origin = Point(Rotation(rot)(ref.origin))
            ref.origin += (Point(newx,newy) + segment(t))
            ref.rot += rot
        end
        push!(c.refs, ref)
    end
    render!(c, segment, undecorated(s); kwargs...)
end
