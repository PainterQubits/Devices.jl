module Cells
using Dates
using LinearAlgebra

using Unitful
import Unitful: Length, nm

import StaticArrays
import CoordinateTransformations
import CoordinateTransformations: ∘, LinearMap, AffineMap, Translation
if isdefined(CoordinateTransformations, :transform) # is deprecated now, but...
    import CoordinateTransformations: transform
end

using ..Points
using ..Rectangles
using ..Polygons

import Devices: AbstractPolygon, Coordinate, GDSMeta, Meta
import Devices: bounds, center, lowerleft, upperright, points, layer, datatype
export Cell, CellArray, CellReference, CellPolygon
export dbscale, elements, flatten, flatten!, layers, meta, name, order!, polygon, transform,
    traverse!, uniquename

@inline unsafe_floor(x::Unitful.Quantity) = floor(Unitful.ustrip(x))*Unitful.unit(x)
@inline unsafe_floor(x::Number) = floor(x)
@inline unsafe_ceil(x::Unitful.Quantity)  = ceil(Unitful.ustrip(x))*Unitful.unit(x)
@inline unsafe_ceil(x::Number) = ceil(x)

struct CellPolygon{S,T<:Meta}
    polygon::Polygon{S}
    meta::T
end
CellPolygon(p::AbstractPolygon{S}, m::T) where {S <: Coordinate,T <: Meta} = CellPolygon{S,T}(p,m)
Base.copy(r::CellPolygon) = CellPolygon(r.polygon, r.meta)
Base.convert(::Type{CellPolygon{S,T}}, p::CellPolygon) where {S <: Coordinate,T <: Meta} =
    CellPolygon{S,T}(p.polygon, p.meta)
Base.:*(r::CellPolygon, a::Number) = CellPolygon(r.polygon * a, r.meta)
Base.:*(a::Number, r::CellPolygon) = CellPolygon(a * r.polygon, r.meta)
Base.:/(r::CellPolygon, a::Number) = CellPolygon(r.polygon / a, r.meta)
Base.:(==)(p1::CellPolygon, p2::CellPolygon) =
    p1.polygon == p2.polygon && p1.meta == p2.meta
for op in (:(Base.:+), :(Base.:-))
    @eval function ($op)(r::CellPolygon, p::Point)
        CellPolygon(($op)(r.polygon, p), r.meta)
    end
    @eval function ($op)(r::CellPolygon, p::StaticArrays.Scalar{<:Point})
        CellPolygon(($op)(r.polygon, p), r.meta)
    end
    @eval function ($op)(p::Point, r::CellPolygon)
        CellPolygon(($op)(p, r.polygon), r.meta)
    end
    @eval function ($op)(p::StaticArrays.Scalar{<:Point}, r::CellPolygon)
        CellPolygon(($op)(p, r.polygon), r.meta)
    end
end
for op in (:bounds, :lowerleft, :orientation, :points, :upperright)
    @eval ($op)(r::CellPolygon) = ($op)(r.polygon)
end
Base.isapprox(c1::CellPolygon, c2::CellPolygon) =
    c1.meta == c2.meta && isapprox(c1.polygon, c2.polygon)
for T in (:LinearMap, :AffineMap, :Translation)
    @eval (f::$T)(x::CellPolygon) = CellPolygon(f(x.polygon), x.meta)
end
@inline polygon(x::CellPolygon) = x.polygon
@inline meta(x::CellPolygon) = x.meta
@inline layer(x::CellPolygon) = layer(x.meta)
@inline datatype(x::CellPolygon) = datatype(x.meta)

"""
    uniquename(str)
Given string input `str`, generate a unique name that bears some resemblance
to `str`. Useful if programmatically making Cells and all of them will
eventually be saved into a GDS-II file. The uniqueness is expected on a per-Julia
session basis, so if you load an existing GDS-II file and try to save unique
cells on top of that you may get an unlucky clash.
"""
function uniquename(str)
    replace(str*string(gensym()), "##"=>"_")
end

abstract type CellRef{S<:Coordinate, T} end

"""
    mutable struct CellReference{S,T} <: CellRef{S,T}
        cell::T
        origin::Point{S}
        xrefl::Bool
        mag::Float64
        rot::Float64
    end
Reference to a `cell` positioned at `origin`, with optional x-reflection
`xrefl`, magnification factor `mag`, and rotation angle `rot`. If an angle
is given without units it is assumed to be in radians.

The type variable `T` is to avoid circular definitions with `Cell`.
"""
mutable struct CellReference{S,T} <: CellRef{S,T}
    cell::T
    origin::Point{S}
    xrefl::Bool
    mag::Float64
    rot::Float64
end
# problematic since the cell is copied...
# convert{S,T}(::Type{CellReference{S,T}}, x::CellReference) =
#     CellReference(convert(T, x.cell), convert(Point{S}, x.origin),
#         x.xrefl, x.mag, x.rot)
Base.convert(::Type{CellReference{S}}, x::CellReference) where {S} =
    CellReference(x.cell, convert(Point{S}, x.origin),
        x.xrefl, x.mag, x.rot)

"""
    mutable struct CellArray{S,T} <: CellRef{S,T}
        cell::T
        origin::Point{S}
        deltacol::Point{S}
        deltarow::Point{S}
        col::Int
        row::Int
        xrefl::Bool
        mag::Float64
        rot::Float64
    end
Array of `cell` starting at `origin` with `row` rows and `col` columns,
spanned by vectors `deltacol` and `deltarow`. Optional x-reflection
`xrefl`, magnification factor `mag`, and rotation angle `rot` for the array
as a whole. If an angle is given without units it is assumed to be in radians.

The type variable `T` is to avoid circular definitions with `Cell`.
"""
mutable struct CellArray{S,T} <: CellRef{S,T}
    cell::T
    origin::Point{S}
    deltacol::Point{S}
    deltarow::Point{S}
    col::Int
    row::Int
    xrefl::Bool
    mag::Float64
    rot::Float64
end
Base.convert(::Type{CellArray{S}}, x::CellArray) where {S} =
    CellArray(x.cell, convert(Point{S}, x.origin),
                      convert(Point{S}, x.deltacol),
                      convert(Point{S}, x.deltarow),
                      x.col, x.row, x.xrefl, x.mag, x.rot)

"""
    mutable struct Cell{S<:Coordinate, T<:Meta}
        name::String
        elements::Vector{CellPolygon{S,T}}
        refs::Vector{CellRef}
        create::DateTime
        Cell(x,y,z,t) = new(x, y, z, t)
        Cell(x,y,z) = new(x, y, z, now())
        Cell(x,y) = new(x, y, CellRef[], now())
        Cell(x) = new(x, Polygon{T}[], CellRef[], now())
        Cell() = begin
            c = new()
            c.elements = Polygon{T}[]
            c.refs = CellRef[]
            c.create = now()
            c
        end
    end
A cell has a name and contains polygons and references to `CellArray` or
`CellReference` objects. It also records the time of its own creation. As
currently implemented it mirrors the notion of cells in GDS-II files.

To add elements, use `render!`. To add references, push them to `refs` field.
"""
mutable struct Cell{S<:Coordinate, T<:Meta}
    name::String
    elements::Vector{CellPolygon{S,T}}
    refs::Vector{CellRef}
    create::DateTime
    Cell{S,T}(x,y,z,t) where {S,T} = new{S,T}(x, y, z, t)
    Cell{S,T}(x,y,z) where {S,T} = new{S,T}(x, y, z, now())
    Cell{S,T}(x,y) where {S,T} = new{S,T}(x, y, CellRef[], now())
    Cell{S,T}(x) where {S,T} = new{S,T}(x, CellPolygon{S,T}[], CellRef[], now())
    Cell{S,T}() where {S,T} = begin
        c = new{S,T}()
        c.elements = CellPolygon{S,T}[]
        c.refs = CellRef[]
        c.create = now()
        c
    end
end
Base.copy(c::Cell{S,T}) where {S,T} = Cell{S,T}(c.name, copy(c.elements), copy(c.refs), c.create)

# Do NOT define a convert method like this or otherwise cells will
# be copied when referenced by CellRefs!
# Base.convert{T}(::Type{Cell{T}}, x::Cell) =
#     Cell{T}(x.name, convert(Vector{Polygon{T}}, x.elements),
#                     convert(Vector{CellRef}, x.refs),
#                     x.create)

"""
    dbscale(c::Cell{T}) where {T}
Give the database scale for a cell. The database scale is the
smallest increment of length that will be represented in the output CAD file.

For `Cell{T<:Length}`, the database scale is `T(1)`. For floating-point lengths,
this means that anything after the decimal point will be rounded off. For
this reason, Cell{typeof(1.0nm)} is probably the most convenient type
to work with.

The database scale of a `Cell{T<:Real}` is assumed to be `1nm` (`1.0nm` if
`T <: AbstractFloat`) because insufficient information is provided to know
otherwise.
"""
dbscale(c::Cell{T}) where {T} = ifelse(T<:AbstractFloat, 1.0nm, ifelse(T<:Real, 1nm, T(1)))

"""
    dbscale(cell::Cell...)
Choose an appropriate database scale for a GDSII file given [`Cell`](@ref)s of
different types. The smallest database scale of all cells considered is returned.
"""
dbscale(c0::Cell, c1::Cell, c2::Cell...) =
    minimum([dbscale(c0); dbscale(c1); map(dbscale, collect(c2))])

"""
    CellReference(x::Cell{S}; kwargs...) where {S <: Coordinate}
    CellReference(x::Cell{S}, origin::Point{T}; kwargs...) where
        {S <: Coordinate, T <: Coordinate}
    CellReference(x, origin::Point{T}; kwargs...) where {T <: Coordinate}

Convenience constructor for `CellReference{float(T), typeof(x)}`.

Keyword arguments can specify x-reflection, magnification, or rotation.
Synonyms are accepted, in case you forget the "correct keyword"...

- X-reflection: `:xrefl`, `:xreflection`, `:refl`, `:reflect`, `:xreflect`,
  `:xmirror`, `:mirror`
- Magnification: `:mag`, `:magnification`, `:magnify`, `:zoom`, `:scale`
- Rotation: `:rot`, `:rotation`, `:rotate`, `:angle`
"""
CellReference(x::Cell{S}; kwargs...) where {S <: Coordinate} =
    CellReference(x, Point(float(zero(S)), float(zero(S))); kwargs...)

function CellReference(x::Cell{S}, origin::Point{T}; kwargs...) where
        {S <: Coordinate, T <: Coordinate}
    dimension(S) != dimension(T) && throw(Unitful.DimensionError(oneunit(S), oneunit(T)))
    cref(x, origin; kwargs...)
end

CellReference(x, origin::Point{T}; kwargs...) where {T <: Coordinate} =
    cref(x, origin; kwargs...)

function cref(x, origin::Point{T}; kwargs...) where {T <: Coordinate}
    argdict = Dict(k=>v for (k,v) in kwargs)
    xreflkeys = [:xrefl, :xreflection, :refl, :reflect,
                    :xreflect, :xmirror, :mirror]
    magkeys = [:mag, :magnification, :magnify, :zoom, :scale]
    rotkeys = [:rot, :rotation, :rotate, :angle]

    xrefl = false
    for k in xreflkeys
        if haskey(argdict, k)
            @inbounds xrefl = argdict[k]
            break
        end
    end

    mag = 1.0
    for k in magkeys
        if haskey(argdict, k)
            @inbounds mag = argdict[k]
            break
        end
    end

    rot = 0.0
    for k in rotkeys
        if haskey(argdict, k)
            @inbounds rot = argdict[k]
            break
        end
    end

    CellReference{float(T), typeof(x)}(x, float(origin), xrefl, mag, rot)
end

"""
    CellArray(x::Cell{S}; kwargs...) where {S <: Coordinate}
    CellArray(x::Cell{S}, origin::Point{T}; kwargs...) where
        {S <: Coordinate, T <: Coordinate}
    CellArray(x, origin::Point{T}; kwargs...) where {T <: Coordinate}

Construct a `CellArray{float(T),typeof(x)}` object.

Keyword arguments specify the column vector, row vector, number of columns,
number of rows, x-reflection, magnification factor, and rotation.

Synonyms are accepted for these keywords:
- Column vector `dc::Point{T}`: `:deltacol`, `:dcol`, `:dc`, `:vcol`, `:colv`, `:colvec`,
  `:colvector`, `:columnv`, `:columnvec`, `:columnvector`
- Row vector: `:deltarow`, `:drow`, `:dr`, `:vrow`, `:rv`, `:rowvec`,
  `:rowvector`
- Number of columns: `:nc`, `:numcols`, `:numcol`, `:ncols`, `:ncol`
- Number of rows: `:nr`, `:numrows`, `:numrow`, `:nrows`, `:nrow`
- X-reflection: `:xrefl`, `:xreflection`, `:refl`, `:reflect`, `:xreflect`,
  `:xmirror`, `:mirror`
- Magnification: `:mag`, `:magnification`, `:magnify`, `:zoom`, `:scale`
- Rotation: `:rot`, `:rotation`, `:rotate`, `:angle`
"""
CellArray(x::Cell{S}; kwargs...) where {S <: Coordinate} =
    CellArray(x, Point(float(zero(S)), float(zero(S))); kwargs...)

function CellArray(x::Cell{S}, origin::Point{T}; kwargs...) where
        {S <: Coordinate, T <: Coordinate}
    dimension(S) != dimension(T) && throw(Unitful.DimensionError(oneunit(S), oneunit(T)))
    carr(x, origin; kwargs...)
end

CellArray(x, origin::Point{T}; kwargs...) where {T <: Coordinate} =
    carr(x, origin; kwargs...)

function carr(x, origin::Point{T}; kwargs...) where {T <: Coordinate}
    argdict = Dict(k=>v for (k,v) in kwargs)

    dckeys = [:deltacol, :dcol, :dc, :vcol, :colv, :colvec,
              :colvector, :columnv, :columnvec, :columnvector]
    drkeys = [:deltarow, :drow, :dr, :vrow, :rv, :rowvec, :rowvector]
    ckeys = [:nc, :numcols, :numcol, :ncols, :ncol]
    rkeys = [:nr, :numrows, :numrow, :nrows, :nrow]
    xreflkeys = [:xrefl, :xreflection, :refl, :reflect,
                 :xreflect, :xmirror, :mirror]
    magkeys = [:mag, :magnification, :magnify, :zoom, :scale]
    rotkeys = [:rot, :rotation, :rotate, :angle]

    dc = Point(zero(T), zero(T))
    for k in dckeys
        if haskey(argdict, k)
            @inbounds dc = argdict[k]
            break
        end
    end

    dr = Point(zero(T), zero(T))
    for k in drkeys
        if haskey(argdict, k)
            @inbounds dr = argdict[k]
            break
        end
    end

    c = 1
    for k in ckeys
        if haskey(argdict, k)
            @inbounds c = argdict[k]
            break
        end
    end

    r = 1
    for k in rkeys
        if haskey(argdict, k)
            @inbounds r = argdict[k]
            break
        end
    end

    xrefl = false
    for k in xreflkeys
        if haskey(argdict, k)
            @inbounds xrefl = argdict[k]
            break
        end
    end

    mag = 1.0
    for k in magkeys
        if haskey(argdict, k)
            @inbounds mag = argdict[k]
            break
        end
    end

    rot = 0.0
    for k in rotkeys
        if haskey(argdict, k)
            @inbounds rot = argdict[k]
            break
        end
    end

    CellArray{float(T), typeof(x)}(x,float(origin),dc,dr,c,r,xrefl,mag,rot)
end

"""
    CellArray(x, c::Range, r::Range; kwargs...)
Construct a `CellArray` based on ranges (probably `LinSpace` or
`FloatRange`). `c` specifies column coordinates and `r` for the rows. Pairs from
`c` and `r` specify the origins of the repeated cells. The extrema of the ranges
therefore do not specify the extrema of the resulting `CellArray`'s bounding box;
some care is required.

Keyword arguments specify x-reflection, magnification factor, and rotation,
with synonyms allowed:

- X-reflection: `:xrefl`, `:xreflection`, `:refl`, `:reflect`, `:xreflect`,
  `:xmirror`, `:mirror`
- Magnification: `:mag`, `:magnification`, `:magnify`, `:zoom`, `:scale`
- Rotation: `:rot`, `:rotation`, `:rotate`, `:angle`

"""
function CellArray(x, c::AbstractRange, r::AbstractRange; kwargs...)
    argdict = Dict(k=>v for (k,v) in kwargs)
    xreflkeys = [:xrefl, :xreflection, :refl, :reflect,
                 :xreflect, :xmirror, :mirror]
    magkeys = [:mag, :magnification, :magnify, :zoom, :scale]
    rotkeys = [:rot, :rotation, :rotate, :angle]

    xrefl = false
    for k in xreflkeys
        if haskey(argdict, k)
            @inbounds xrefl = argdict[k]
            break
        end
    end

    mag = 1.0
    for k in magkeys
        if haskey(argdict, k)
            @inbounds mag = argdict[k]
            break
        end
    end

    rot = 0.0
    for k in rotkeys
        if haskey(argdict, k)
            @inbounds rot = argdict[k]
            break
        end
    end

    CellArray{promote_type(eltype(c),eltype(r)), typeof(x)}(x, Point(first(c), first(r)),
        Point(step(c), zero(step(c))), Point(zero(step(r)), step(r)),
        length(c), length(r), xrefl, mag, rot)
end



"""
    Cell(name::AbstractString)
Convenience constructor for `Cell{Float64}`.
"""
Cell(name::AbstractString) = Cell{Float64, GDSMeta}(name)

"""
    Cell(name::AbstractString, unit::Unitful.LengthUnit)
Convenience constructor for `Cell{typeof(1.0unit)}`.
"""
Cell(name::AbstractString, unit::Unitful.LengthUnits) =
    Cell{typeof(1.0unit), GDSMeta}(name)

Cell(name::AbstractString, elements::AbstractVector{CellPolygon{S,T}}) where {S,T} =
    Cell{S,T}(name, elements)
Cell(name::AbstractString, elements::AbstractVector{CellPolygon{S,T}}, refs) where {S,T} =
    Cell{S,T}(name, elements, refs)

# Don't print out everything in the cell, it is a mess that way.
Base.show(io::IO, c::Cell) = print(io,
    "Cell \"$(c.name)\" with $(length(c.elements)) els, $(length(c.refs)) refs")

"""
    copy(x::CellReference)
Creates a shallow copy of `x` (does not copy the referenced cell).
"""
Base.copy(x::CellReference) = CellReference(x.cell, x.origin, x.xrefl, x.mag, x.rot)

"""
    copy(x::CellArray)
Creates a shallow copy of `x` (does not copy the arrayed cell).
"""
Base.copy(x::CellArray) = CellArray(x.cell, x.origin, x.deltacol, x.deltarow,
    x.col, x.row, x.xrefl, x.mag, x.rot)

"""
    getindex(c::Cell, nom::AbstractString, index::Integer=1)
If `c` references a cell with name `nom`, this method will return the
corresponding `CellReference`. If there are several references to that cell,
then `index` specifies which one is returned (in the order they are found in
`c.refs`). e.g. to specify an index of 2: `mycell["myreferencedcell",2]`.
"""
function Base.getindex(c::Cell, nom::AbstractString, index::Integer=1)
    inds = findall(x->name(x)==nom, c.refs)
    c.refs[inds[index]]
end

"""
    getindex(c::CellRef, nom::AbstractString, index::Integer=1)
If the cell referenced by `c` references a cell with name `nom`, this method
will return the corresponding `CellReference`. If there are several references
to that cell, then `index` specifies which one is returned (in the order they
are found in `c.refs`).

This method is typically used so that we can type the first line instead of the
second line in the following:
```
mycell["myreferencedcell"]["onedeeper"]
mycell["myreferencedcell"].cell["onedeeper"]
```
"""
function Base.getindex(c::CellRef, nom::AbstractString, index::Integer=1)
    inds = findall(x->name(x)==nom, c.cell.refs)
    c.cell.refs[inds[index]]
end

"""
    bounds(cell::Cell{T}) where {T <: Coordinate}
    bounds(cell0::Cell, cell1::Cell, cell::Cell...)
Returns a `Rectangle` bounding box around all objects in a cell or cells.
Returns a rectangle with zero width and height if the cell or cells are empty.
"""
function bounds(cell::Cell{T}) where {T <: Coordinate}
    mi, ma = Point(typemax(T), typemax(T)), Point(typemin(T), typemin(T))
    bfl(::Type{S}, x) where {S <: Integer} = unsafe_floor(x)
    bfl(S,x) = x
    bce(::Type{S}, x) where {S <: Integer} = unsafe_ceil(x)
    bce(S,x) = x

    isempty(cell.elements) && isempty(cell.refs) &&
        return Rectangle(Point(zero(T), zero(T)), Point(zero(T), zero(T)))

    for el in cell.elements
        b = bounds(el)
        mi = Point(min(mi.x, lowerleft(b).x), min(mi.y, lowerleft(b).y))
        ma = Point(max(ma.x, upperright(b).x), max(ma.y, upperright(b).y))
    end

    for el in cell.refs
        # The referenced cells may not return the same Rectangle{T} type.
        # We should grow to accommodate if necessary.
        br = bounds(el)
        b = Rectangle{T}(bfl(T, br.ll), bce(T, br.ur))
        mi = Point(min(mi.x, lowerleft(b).x), min(mi.y, lowerleft(b).y))
        ma = Point(max(ma.x, upperright(b).x), max(ma.y, upperright(b).y))
    end

    Rectangle(mi, ma)
end

function bounds(cell0::Cell, cell1::Cell, cell::Cell...)
    r = bounds([bounds(cell0), bounds(cell1), bounds.(cell)...])
    Rectangle(r.ll, r.ur)
end

"""
    center(cell::Cell)
Convenience method, equivalent to `center(bounds(cell))`.
Returns the center of the bounding box of the cell.
"""
center(cell::Cell) = center(bounds(cell))

"""
    bounds(ref::CellArray)
Returns a `Rectangle` bounding box around all objects in `ref`. The bounding box respects
reflection, rotation, and magnification specified by `ref`.

Please do rewrite this method when feeling motivated... it is very inefficient.
"""
function bounds(ref::CellArray{T, Cell{S,U}}) where {S <: Coordinate,T <: Coordinate,U <: Meta}
    b = bounds(ref.cell)::Rectangle{S}
    !isproper(b) && return b

    # The following code block is very inefficient

    lls = [(b.ll + (i-1) * ref.deltarow + (j-1) * ref.deltacol)::Point{promote_type(S,T)}
            for i in 1:(ref.row), j in 1:(ref.col)]
    urs = lls .+ Point(width(b), height(b))
    mb = Rectangle(lowerleft(lls), upperright(urs))

    sgn = ref.xrefl ? -1 : 1
    a = Translation(ref.origin) ∘ CoordinateTransformations.LinearMap(
        StaticArrays.@SMatrix [sgn*ref.mag*cos(ref.rot) -ref.mag*sin(ref.rot);
                  sgn*ref.mag*sin(ref.rot) ref.mag*cos(ref.rot)])
    c = a(mb)
    bounds(c)
end

"""
    bounds(ref::CellReference)
Returns a `Rectangle` bounding box around all objects in `ref`. The bounding box respects
reflection, rotation, and magnification specified by `ref`.
"""
function bounds(ref::CellReference)
    b = bounds(ref.cell)
    !isproper(b) && return b
    sgn = ref.xrefl ? -1 : 1
    a = Translation(ref.origin) ∘ CoordinateTransformations.LinearMap(
        StaticArrays.@SMatrix [sgn*ref.mag*cos(ref.rot) -ref.mag*sin(ref.rot);
                    sgn*ref.mag*sin(ref.rot)  ref.mag*cos(ref.rot)])
    c = a(b)
    bounds(c)
end

"""
    elements(c::Cell)
Returns the `CellPolygon` objects in the cell, which are `Polygon`s with metadata such as
layer, datatype, etc.
"""
elements(c::Cell) = c.elements

for T in (:LinearMap, :AffineMap)
    @eval function (f::$T)(x::CellReference)
        mag = norm(f.linear[:,1])
        xrefl = f.linear[1,1] != f.linear[2,2]
        rot = acos(f.linear[1,1] / mag)
        return CellReference(x.cell, f(x.origin),
            xrefl ⊻ x.xrefl, mag * x.mag, rot + x.rot)
    end
    @eval function (f::$T)(x::CellArray)
        mag = norm(f.linear[:,1])
        xrefl = f.linear[1,1] != f.linear[2,2]
        rot = acos(f.linear[1,1] / mag)
        return CellArray(x.cell, f(x.origin), f(x.deltacol), f(x.deltarow), x.col, x.row,
            xrefl ⊻ x.xrefl, mag * x.mag, rot + x.rot)
    end
end

function (f::Translation)(x::CellReference)
    CellReference(x.cell, f(x.origin), x.xrefl, x.mag, x.rot)
end

function (f::Translation)(x::CellArray)
    CellArray(x.cell, f(x.origin), x.deltacol, x.deltarow,
        x.col, x.row, x.xrefl, x.mag, x.rot)
end

"""
    flatten!(c::Cell, depth::Integer=-1)
Cell references and arrays up to a hierarchical `depth` are recursively flattened into
polygons and added to cell `c`. The references and arrays that were flattened are then
discarded. Deeper cell references and arrays are brought upwards and are not discarded.
This function has no effect for `depth == 0`, and unlimited depth by default.
"""
function flatten!(c::Cell; depth::Integer=-1)
    depth == 0 && return c
    cflat = flatten(c; depth=depth)
    c.elements = cflat.elements
    c.refs = cflat.refs
    return c
end

"""
    flatten(c::Cell; depth::Integer=-1, name=uniquename("flatten"))
Cell references and arrays in `c` up to a hierarchical `depth` are recursively flattened into
polygons and added to a new `Cell` with name `name`. The references and arrays that were
flattened are then discarded. Deeper cell references and arrays are brought upwards and are
not discarded. This function has no effect for `depth == 0`, and unlimited depth by default.
The cell `c` remains unmodified.
"""
function flatten(c::Cell; depth::Integer=-1, name=uniquename("flatten"))
    depth == 0 && return copy(c)
    elements = copy(c.elements)
    refs = empty(c.refs)
    for r in c.refs
        rflat = flatten(r; depth=depth)
        append!(elements, rflat.elements)
        append!(refs, rflat.refs)
    end
    Cell(name, elements, refs)
end

"""
    flatten(c::CellReference; depth::Integer=-1, name=uniquename("flatten"))
Cell reference `c` is recursively flattened into polygons up to a hierarchical `depth` and
added to a new `Cell` with name `name`. The references and arrays that were flattened are
then discarded. Deeper cell references and arrays are brought upwards and are
not discarded. The cell reference `c` remains unmodified. The user should not pass `depth=0`
as that will flatten with unlimited depth.
"""
function flatten(c::CellReference; depth::Integer=-1, name=uniquename("flatten"))
    sgn = c.xrefl ? -1 : 1
    a = Translation(c.origin) ∘ CoordinateTransformations.LinearMap(
        StaticArrays.@SMatrix [c.mag*cos(c.rot) -c.mag*sgn*sin(c.rot);
                               c.mag*sin(c.rot)  c.mag*sgn*cos(c.rot)])
    cflat = flatten(c.cell; depth=depth-1)
    newelements = a.(cflat.elements)
    newrefs = a.(cflat.refs)
    Cell(name, newelements, newrefs)
end

"""
    flatten(c::CellArray; depth::Integer=-1, name=uniquename("flatten"))
Cell array `c` is recursively flattened into polygons up to a hierarchical `depth` and
added to a new `Cell` with name `name`. The references and arrays that were flattened are
then discarded. Deeper cell references and arrays are brought upwards and are
not discarded. The cell reference `c` remains unmodified. The user should not pass `depth=0`
as that will flatten with unlimited depth.
"""
function flatten(c::CellArray; depth::Integer=-1, name=uniquename("flatten"))
    sgn = c.xrefl ? -1 : 1
    a = Translation(c.origin) ∘ CoordinateTransformations.LinearMap(
        StaticArrays.@SMatrix [c.mag*cos(c.rot) -c.mag*sgn*sin(c.rot);
                               c.mag*sin(c.rot)  c.mag*sgn*cos(c.rot)])
    cflat = flatten(c.cell; depth=depth-1)
    pts = [(i-1) * c.deltarow + (j-1) * c.deltacol for i in 1:c.row for j in 1:c.col]
    pts2 = reshape(reinterpret(StaticArrays.Scalar{eltype(pts)}, vec(pts)), (1,length(pts)))
    newelements = a.(cflat.elements .+ pts2) # add each point in pts to each polygon
    newrefs = a.(cflat.refs .+ pts2)
    Cell(name, (@view newelements[:]), (@view newrefs[:]))
end

"""
    name(x::Cell)
Returns the name of the cell.
"""
name(x::Cell) = x.name

"""
    name(x::CellArray)
Returns the name of the arrayed cell.
"""
name(x::CellArray) = name(x.cell)

"""
    name(x::CellReference)
Returns the name of the referenced cell.
"""
name(x::CellReference) = name(x.cell)

"""
    layers(x::Cell)
Returns the layers of elements in cell `x` as a set. Does *not* return the layers
in referenced or arrayed cells.
"""
function layers(x::Cell)
    layers = Set{Int}()
    for el in x.elements
        push!(layers, layer(el))
    end
    layers
end

"""
    traverse!(a::AbstractArray, c::Cell, level=1)
Given a cell, recursively traverse its references for other cells and add
to array `a` some tuples: `(level, c)`. `level` corresponds to how deep the cell
was found, and `c` is the found cell.
"""
function traverse!(a::AbstractArray, c::Cell, level=1)
    push!(a, (level, c))
    for ref in c.refs
        traverse!(a, ref.cell, level+1)
    end
end

"""
    order!(a::AbstractArray)
Given an array of tuples like that coming out of [`traverse!`](@ref), we
sort by the `level`, strip the level out, and then retain unique entries.
The aim of this function is to determine an optimal writing order when
saving pattern data (although the GDS-II spec does not require cells to be
in a particular order, there may be performance ramifications).

For performance reasons, this function modifies `a` but what you want is the
returned result array.
"""
function order!(a::AbstractArray)
    a = sort!(a, lt=(x,y)->x[1]<y[1], rev=true)
    unique(map(x->x[2], a))
end

"""
    transform(c::Cell, d::CellRef)
Given a Cell `c` containing [`CellReference`](@ref) or [`CellArray`](@ref)
`d` in its tree of references, this function returns a
`CoordinateTransformations.AffineMap` object that lets you translate from the
coordinate system of `d` to the coordinate system of `c`.

If the *same exact* `CellReference` or `CellArray` (as in `===`, same address in
memory) is included multiple times in the tree of references, then the resulting
transform will be based on the first time it is encountered. The tree is
traversed one level at a time to find the reference (optimized for shallow
references).

Example: You want to translate (2.0,3.0) in the coordinate system of the
referenced cell `d` to the coordinate system of `c`:

```
julia> trans = transform(c,d)

julia> trans(Point(2.0,3.0))
```
"""
function transform(c::Cell, d::CellRef)
    x,y = transform(c, d, CoordinateTransformations.LinearMap(StaticArrays.SMatrix{2,2}(1.0I)))

    x || error("Reference tree does not contain $d.")
    return y
end

function transform(c::Cell, d::CellRef, a)
    # look for the reference in the top level of the reference tree.
    for ref in c.refs
        if ref === d
            sgn = ifelse(d.xrefl, -1, 1)
            return true, a ∘ Translation(d.origin) ∘
            CoordinateTransformations.LinearMap(
                StaticArrays.@SMatrix [d.mag*cos(d.rot) -d.mag*sgn*sin(d.rot);
                                       d.mag*sin(d.rot)  d.mag*sgn*cos(d.rot)])
        end
    end

    # didn't find the reference at this level.
    # we must go deeper...
    for ref in c.refs
        sgn = ifelse(ref.xrefl, -1, 1)
        (x,y) = transform(ref.cell, d, a ∘ Translation(ref.origin) ∘
            CoordinateTransformations.LinearMap(
                StaticArrays.@SMatrix [ref.mag*cos(ref.rot) -ref.mag*sgn*sin(ref.rot);
                                       ref.mag*sin(ref.rot)  ref.mag*sgn*cos(ref.rot)]))
        # were we successful?
        if x
            return x, y
        end
    end

    # we should have found `d` by now. report our failure
    return false, a
end

"""
    transform(c::Cell, d::CellRef, e::CellRef, f::CellRef...)
Given a Cell `c` containing [`CellReference`](@ref) or [`CellArray`](@ref)
`last(f)` in its tree of references, this function returns a
`CoordinateTransformations.AffineMap` object that lets you translate from the
coordinate system of `last(f)` to the coordinate system of `c`. This method is needed
when you want to specify intermediate `CellRef`s explicitly.

For example, suppose for instance you have a hierarchy of cells, where cell A references
B1 and B2, which both reference C. Schematically, it might look like this:

```
a -- b1 -- c
  \\      /
   \\ b2 /
```

Cell C appears in two places inside cell A, owing to the fact that it is referenced by
both B1 and B2. If you need to get the coordinate system of C via B2, then you need to do
`transform(cellA, cellrefB2, cellrefC)`, rather than simply `transform(cellA, cellrefC)`,
because the latter will just take the first path to C available, via B1.
"""
function transform(c::Cell, d::CellRef, e::CellRef, f::CellRef...)
    t = transform(c,d) ∘ transform(d.cell, e)
    if length(f) == 0
        return t
    elseif length(f) == 1
        return t ∘ transform(e.cell, f[1])
    else
        t = t ∘ transform(e.cell, f[1])
        for i in 1:(length(f)-1)
            t = t ∘ transform(f[i].cell, f[i+1])
        end
        return t
    end
end

for op in (:(Base.:+), :(Base.:-))
    @eval function ($op)(r::Cell{S,T}, p::Point) where {S <: Coordinate,T <: Meta}
        n = Cell{S,T}(r.name, similar(r.elements), similar(r.refs))
        for (ia, ib) in zip(eachindex(r.elements), eachindex(n.elements))
            @inbounds n.elements[ib] = ($op)(r.elements[ia], p)
        end
        for (ia, ib) in zip(eachindex(r.refs), eachindex(n.refs))
            @inbounds n.refs[ib] = ($op)(r.refs[ia], p)
        end
        n
    end
    @eval function ($op)(r::CellArray{S,T}, p::Point) where {S <: Coordinate,T}
        CellArray(r.cell, ($op)(r.origin,p), r.deltacol, r.deltarow,
            r.col, r.row, r.xrefl, r.mag, r.rot)
    end
    @eval function ($op)(r::CellReference{S,T}, p::Point) where {S <: Coordinate,T}
        CellReference(r.cell, ($op)(r.origin,p),
            xrefl=r.xrefl, mag=r.mag, rot=r.rot)
    end
end

end
