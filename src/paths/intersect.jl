using LinearAlgebra
import DataStructures: OrderedDict

"""
    intersectingpairs!(path1::Path, path2::Path)
Returns two vectors that can index into `path1` and `path2` respectively to return the
intersecting path nodes; also returns the intersection points.
"""
function intersectingpairs!(path1::Path, path2::Path)
    T = promote_type(eltype(path1), eltype(path2))

    # Approximate the paths by line segments and identify the intersecting line segments.
    # If there are no intersections, we can return early.
    inds1, segs1 = segmentize(path1)
    local inds2, segs2, I, J
    if path1 == path2
        # Want to ignore neighboring segments that intersect at their endpoints,
        # so we'll use the one argument method of `intersectingpairs`.
        inds2, segs2 = inds1, segs1
        I, J = intersectingpairs(segs1)
    else
        inds2, segs2 = segmentize(path2)
        I, J = intersectingpairs(segs1, segs2)
    end
    # if `J` is empty, so is `I`, and there are no intersections.
    isempty(J) && return inds1[I], inds2[J], Vector{Point{T}}()

    # `I`, `J` are indices into both `segs` and `inds` (respectively the
    # `Polygons.LineSegment`s approximating the paths, and the indices of the
    # `Paths.Segment`s they came from). Indices in `J` appear in ascending order and
    # `I[j] < J[j]` for all valid `j`.

    i = 1
    intersections = Vector{Point{T}}(undef, length(J))
    for (s1, s2) in zip(segs1[I], segs2[J])
        # solve for the intersection of two lines.
        l1, l2 = Polygons.Line(s1), Polygons.Line(s2)
        intersections[i] = Polygons.intersection(l1, l2, false)[2]
        i += 1
    end

    return inds1[I], inds2[J], intersections
end

"""
    segmentize(path::Paths.Path)
Turns a [`Paths.Path`](@ref) into an array of [`Polygons.LineSegment`](@ref) approximating
the path. Returns indices to mark which `LineSegment`s came from which [`Paths.Segment`](@ref).
"""
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

"""
    segmentize(seg::Paths.Straight)
Returns a vector with a [`Polygons.LineSegment`](@ref) object corresponding to `seg`.
"""
function segmentize(seg::Paths.Straight)
    return [Polygons.LineSegment(p0(seg), p1(seg))]
end

function segmentize(seg::Paths.Corner{T}) where T
    return Polygons.LineSegment{T}[]
end

"""
    segmentize(seg::Paths.Segment)
Generic fallback, approximating a [`Paths.Segment`](@ref) using many
[`Polygons.LineSegment`](@ref) objects. Returns a vector of `LineSegment`s.
"""
function segmentize(seg::Paths.Segment)
    len = pathlength(seg)
    bnds = (zero(len), len)
    return segmentize(seg.(Devices.adapted_grid(t->Paths.direction(seg, t), bnds)), false)
end

"""
    intersectingpairs(segs1::Vector{<:Polygons.LineSegment})
Returns two arrays `I`, `J` that index into `segs1` to return pairs of intersecting line
segments. It is guaranteed that `I[i] < J[i]` for all valid `i`, and that `J` is sorted
ascending. If any segments intersect at more than one point, an error is thrown.
"""
function intersectingpairs(segs1::Vector{<:Polygons.LineSegment})
    inds1 = Int[]
    inds2 = Int[]

    s1 = collect(enumerate(segs1))
    for x in eachindex(s1)
        (i,seg1) = s1[x]
        for (j,seg2) in s1[(x+1):end]
            intersects, atapoint, atendpoints = Polygons.intersects_at_endpoint(seg1, seg2)
            intersects && !atapoint && error("degenerate segments: $seg1 and $seg2.")
            if intersects && !atendpoints
                # TODO: conceivable that we might want to handle atendpoints if the
                # LineSegments came from non-adjacent Paths.Segments...
                push!(inds1, i)
                push!(inds2, j)
            end
        end
    end
    sortedinds = sortperm(inds2)
    return inds1[sortedinds], inds2[sortedinds]
end

"""
    intersectingpairs(segs1::Vector{<:Polygons.LineSegment},
                      segs2::Vector{<:Polygons.LineSegment})
Returns two arrays `I`, `J` that index into `segs1` and `segs2` respectively to return
pairs of intersecting line segments. If any segments intersect at more than one point, an
error is thrown. It is guaranteed that `J` is sorted ascending.
"""
function intersectingpairs(segs1::Vector{<:Polygons.LineSegment},
                           segs2::Vector{<:Polygons.LineSegment})
    inds1 = Int[]
    inds2 = Int[]

    s1 = collect(enumerate(segs1))
    s2 = collect(enumerate(segs2))
    for (i,seg1) in s1
        for (j,seg2) in s2
            intersects, atapoint = Polygons.intersects(seg1, seg2)
            intersects && !atapoint && error("degenerate segments: $seg1 and $seg2.")
            if intersects
                push!(inds1, i)
                push!(inds2, j)
            end
        end
    end
    sortedinds = sortperm(inds2)
    return inds1[sortedinds], inds2[sortedinds]
end

"""
    IntersectStyle{N}
Abstract type specifying "N-body interactions" for path intersection; `N::Int` typically 2.
"""
abstract type IntersectStyle{N} end

"""
    Bridges(; gap, footlength, bridgemetas,
        bridgeprefix="bridges", bridgeunit=[nm or NoUnits])
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
    function Bridges(; gap::Coordinate, footlength::Coordinate,
            bridgemetas::AbstractVector{<:Meta},
            bridgeprefix::AbstractString = "bridges",
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
        interactions::AbstractMatrix{Bool}=[default], reconcile=true)
Automatically modify paths to handle cases where they intersect.

`interactions` is a keyword argument that specifies a pair-wise interaction matrix. If an
entry `(i,j)` is `true`, then `intersect_pairwise!(sty, paths[i], paths[j])` will be called.
By default the matrix is an upper-triangular matrix filled with `true`. This is typically
what you want: self-intersections of each path are handled, and the intersection of two
given paths is only handled once.

Paths later in the argument list cross over paths earlier in the argument list. For
self-intersection (path with itself), segments later in a path will cross over segments
earlier in the same path (perhaps later this will be configurable by an option).
"""
function intersect!(sty::IntersectStyle{2}, paths::Path...;
        interactions::AbstractMatrix{Bool} =
            UpperTriangular(fill(true, (length(paths), length(paths)))), reconcile=true)
    for I in findall(interactions)
        intersect_pairwise!(sty, paths[I[1]], paths[I[2]]; reconcile=reconcile)
    end
end

"""
    intersect_pairwise!(sty::Bridges, pa1::Path, pa2::Path; reconcile=true)
Automatically modify `pa2` to cross over `pa1` using air bridges. `pa1 === pa2` is acceptable.
The crossing-over segments must be `Paths.Straight`.
"""
function intersect_pairwise!(sty::Bridges{S}, pa1::Path, pa2::Path; reconcile=true) where S
    # if `pa1 === pa2`, we don't want to disturb the indexing of `pa1` when we start
    # splicing new segments into `pa2`...
    _pa1 = (pa1 === pa2) ? copy(nodes(pa1)) : nodes(pa1)

    I, J, intersections = Paths.intersectingpairs!(pa1, pa2)
    uJ = unique(J)

    # Bail immediately if any of the crossing-over segments are not straight
    any(x->!(segment(x) isa Paths.Straight), view(pa2, uJ)) &&
        error("can only handle crossing of Straight paths.")

    # Compute the distances from the start of each segment identified in `J` to the
    # corresponding intersection point(s).
    dist2 = [norm(p - segment(pa2[j]).p0) for (j, p) in zip(J, intersections)]

    adj = 0
    for j in uJ     # note that `uJ` is ascending because `J` was ascending.
        # Each `j` in `uJ` is an index into `pa2` of a segment that needs to hop over another.
        # The plan is to construct a new path consisting of only Paths.Straight and bridges
        # and splice it into `pa2` at index `j`. To construct this new path, we need to
        # start at the beginning of the existing straight segment at index `j` and
        # identify which intersection points come first. We'll need the associated
        # crossed-over segment indices too.
        inds = findall(x->x==j, J)
        increasing_order = sortperm(dist2[inds])
        Iinc, interinc = I[inds][increasing_order], intersections[inds][increasing_order]

        # We may have already spliced into the path, which will shift the indices from what
        # they originally were. We keep track of this using `adj`.
        j += adj

        # Get the old segment and style, and prepare a new path.
        s2, st2 = segment(pa2[j]), style(pa2[j])
        pa = Path(p0(s2), α0=α0(s2))
        for (i, p, d) in zip(Iinc, interinc, dist2[inds][increasing_order])
            s1, st1 = segment(_pa1[i]), style(_pa1[i])

            # Get the lateral extent of `pa1` at the intersection point in question.
            # We should go straight up to the intersection point, less that extent, less
            # the gap specified in `sty`.
            howfar1 = norm(p - s1.p0)
            extents = Paths.extent(st1, howfar1)
            _howfar2 = d - extents - sty.gap

            # actually, we need to go a little bit less if we have a CPW, because we need
            # to terminate the CPW...
            termlA = Paths.terminationlength(st2, _howfar2)
            howfar2 = _howfar2 - termlA
            # TODO check that the straight section will be long enough to do this.

            # prepare a bridge of the correct size.
            brc = Cell(uniquename(sty.bridgeprefix), sty.bridgeunit)
            bridge!(brc, length(sty.bridgemetas) - 1, sty.footlength,
                Paths.trace(st2, howfar2), 2*(sty.gap + extents + termlA), sty.bridgemetas)

            # now start going...
            straight!(pa, howfar2 - pathlength(pa), st2)
            (termlA > zero(termlA)) &&
                straight!(pa, termlA, Paths.terminationstyle(st2, _howfar2))
            nr = Paths.NoRender(2*Paths.extent(style1(pa), termlA))
            straight!(pa, sty.gap, nr)
            straight!(pa, 2*extents, nr)
            attach!(pa, CellReference(brc), extents)
            straight!(pa, sty.gap, nr)
            termlB = Paths.terminationlength(st2, pathlength(pa))
            (termlB > zero(termlB)) &&
                straight!(pa, termlB, Paths.terminationstyle(st2, pathlength(pa)))
        end
        # Finally, go the remaining length of the original segment.
        straight!(pa, s2.l - pathlength(pa), st2)

        # Splice this path into `pa2`. Bam, automatic bridges.
        splice!(pa2, j, pa; reconcile=false)

        # We've added this many segments to `pa2`, so adjust indices in the next pass...
        adj += length(pa) - 1
    end

    # Finally, reconcile the path
    # (adjust internal details for consistency beginning with the first spliced node).
    reconcile && isempty(J) || reconcile!(pa2, first(J))
end
