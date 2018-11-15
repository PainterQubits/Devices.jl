using LinearAlgebra

function intersectingpairs(path1::Path, path2::Path)
    inds1, segs1 = segmentize(path1)
    if path1 == path2
        I, J = intersectingpairs(segs1)
        return inds1[I], inds1[J]
    else
        inds2, segs2 = segmentize(path2)
        I, J = intersectingpairs(segs1, segs2)
        return inds1[I], inds2[J]
    end
end

function segmentize(path::Paths.Path{T}) where T
    segs0 = Polygons.LineSegment{T}[]
    inds0 = Int[]
    for (i,n) in enumerate(Paths.nodes(path))
        segs = segmentize(segment(n))
        inds = repeat([i], length(segs))
        append!(segs0, segs)
        append!(inds0, inds)
    end
    return inds0, segs0
end

function segmentize(str::Paths.Straight)
    return [Polygons.LineSegment(p0(str), p1(str))]
end

function segmentize(seg::Paths.Segment)
    len = pathlength(seg)
    bnds = (zero(len), len)
    return segmentize(seg.(Devices.adapted_grid(t->Paths.direction(seg, t), bnds)), false)
end

function intersectingpairs(segs1::Vector{<:Polygons.LineSegment})
    inds1 = Int[]
    inds2 = Int[]

    s1 = [(i,s) for (i,s) in enumerate(segs1)]
    sort!(s1, by=x->x[2].p0.x)

    for x in eachindex(s1)
        (i,seg1) = s1[x]
        for (j,seg2) in s1[(x+1):end]
            if Polygons.intersects_onsegment(seg1, seg2)
                push!(inds1, i)
                push!(inds2, j)
            end
        end
    end
    return inds1, inds2
end

function intersectingpairs(segs1::Vector{<:Polygons.LineSegment},
        segs2::Vector{<:Polygons.LineSegment})
    inds1 = Int[]
    inds2 = Int[]

    s1 = [(i,s) for (i,s) in enumerate(segs1)]
    s2 = [(i,s) for (i,s) in enumerate(segs2)]
    sort!(s1, by=x->x[2].p0.x)
    sort!(s2, by=x->x[2].p0.x)

    for (i,seg1) in s1
        for (j,seg2) in s2
            if Polygons.intersects(seg1, seg2)
                push!(inds1, i)
                push!(inds2, j)
            end
        end
    end
    return inds1, inds2
end

"""
    IntersectStyle{N}
Abstract type specifying "N-body interactions" for path intersection; `N::Int` typically 2.
"""
abstract type IntersectStyle{N} end

"""
    Bridges(; gap, footlength, bridgemetas,
        bridgeprefix="bridgeover", bridgeunit=[nm or NoUnits])
Style for automatically leaping one path over another with air bridges.

The only required parameters to provide are:

- `gap`: how much buffer to leave between the intersecting paths
- `footlength`: how long in the direction of the path is the bridge landing pad
- `bridgemetas`: a vector of `Meta` objects. The first element is for the bridge foot,
  subsequent elements are for increasingly higher steps of the discretized bridge. The
  length of this array therefore sets the vertical resolution.

For each intersection, a bridge is rendered into a new cell. The cell has database units
`bridgeunit` which is `nm` by default (if `gap` has length units, otherwise no units).
Each cell is named uniquely with a prefix given by `bridgeprefix`.
"""
struct Bridges{S<:Meta, T<:Coordinate, U<:CoordinateUnits} <: IntersectStyle{2}
    bridgemetas::Vector{S}
    gap::T
    footlength::T
    bridgeprefix::String
    bridgeunit::U
    function BridgeOver(; gap::Coordinate, footlength::Coordinate,
            bridgemetas::AbstractVector{<:Meta},
            bridgeprefix::AbstractString = "bridgeover",
            bridgeunit::CoordinateUnits = (gap isa Length ? Unitful.nm : NoUnits))
        (dimension(gap) != dimension(footlength)) &&
            throw(DimensionError(gap, footlength))
        (dimension(gap) != dimension(bridgeunit)) &&
            throw(DimensionError(unit(gap), bridgeunit))

        g, f = promote(gap, footlength)
        S = eltype(bridgemetas)
        T = eltype(g)
        U = typeof(bridgeunit)
        return new{S,T,U}(bridgemetas, g, f, bridgeprefix, bridgeunit)
    end
end

"""
    intersect!(sty::IntersectStyle{2}, paths::Path...;
        interactions::AbstractMatrix{Bool}=[default])
Automatically modify paths to handle cases where they intersect.

`interactions` is a keyword argument that specifies a pair-wise interaction matrix. If an
entry `(i,j)` is `true`, then `intersect_pairwise!(sty, paths[i], paths[j])` will be called.
By default the matrix is an upper-triangular matrix filled with `true`. This is typically
what you want: self-intersections of each path are handled, and the intersection of two
given paths is only handled once.

If ambiguous for a given style, segments later in a path should cross over segments earlier
in the same path. Paths later in the argument list cross over paths earlier in the argument
list.
"""
function intersect!(sty::IntersectStyle{2}, paths::Path...;
        interactions::AbstractMatrix{Bool} =
            UpperTriangular(fill(true, (length(paths), length(paths)))), adjust=true)
    for I in findall(interactions)
        intersect_pairwise!(sty, paths[I[1]], paths[I[2]]; adjust=adjust)
    end
end

"""
    intersect_pairwise!(sty::Bridges, pa1::Path, pa2::Path; adjust=true)
Automatically modify `pa2` to cross over `pa1` using air bridges.
"""
function intersect_pairwise!(sty::Bridges{S}, pa1::Path, pa2::Path; adjust=true) where S
    paths = Path[]

    # pa2 jumps over pa1.
    I,J = Paths.intersectingpairs(pa1, pa2)
    for (i,j) in zip(I,J)
        s1, s2 = segment(pa1[i]), segment(pa2[j])
        st1, st2 = style(pa1[i]), style(pa2[j])

        # only handle straight × straight for now.
        (s1 isa Paths.Straight) && (s2 isa Paths.Straight) ||
            error("BridgeOver: cannot handle crossing $(typeof(s1)) and $(typeof(s2)).")

        # bail if we have degenerate lines
        l1, l2 = promote(Polygons.Line(p0(s1), p1(s1)), Polygons.Line(p0(s2), p1(s2)))
        Polygons.isparallel(l1, l2) && error("BridgeOver: $s1 and $s2 are parallel.")

        p = Polygons.intersection(l1, l2, false)[2]
        howfar1 = norm(p - s1.p0)
        extents = Paths.extent(st1, howfar1)
        _howfar2 = norm(p - s2.p0) - extents - sty.gap

        # In general this isn't quite right. This assumes that the termination length
        # at _howfar2 is the same as at _howfar2 - terml. You could solve this iteratively.
        termlA = Paths.terminationlength(st2, _howfar2)
        howfar2 = _howfar2 - termlA

        # TODO check that the straight section was long enough to do this.

        pa = Path(p0(s2), α0=α0(s2))
        brc = Cell(uniquename(sty.bridgeprefix), sty.bridgeunit)
        bridge!(brc, length(sty.bridgemetas) - 1, sty.footlength,
            Paths.trace(st2, howfar2), 2*(sty.gap + extents + termlA), sty.bridgemetas)
        straight!(pa, howfar2, st1)
        straight!(pa, termlA, Paths.terminationstyle(st2, _howfar2))
        straight!(pa, sty.gap, Paths.NoRender())
        straight!(pa, 2*extents, Paths.NoRender())
        attach!(pa, CellReference(brc), extents)
        straight!(pa, sty.gap, Paths.NoRender())
        termlB = Paths.terminationlength(st2, pathlength(pa))
        straight!(pa, termlB, Paths.terminationstyle(st2, pathlength(pa)))
        # how to continue with existing style?
        straight!(pa, s2.l - pathlength(pa), st2)
        push!(paths, pa)
    end

    # Fix up pa2 by splicing in the paths where needed
    adj = 0
    i = 1
    for j in J
        splice!(pa2, j+adj, paths[i]; adjust=false)
        adj += (length(paths[i]) - 1)
        i += 1
    end
    adjust && isempty(J) || adjust!(pa2, first(J))
end
