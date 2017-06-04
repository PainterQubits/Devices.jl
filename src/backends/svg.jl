module SVG
using Compat
using Unitful
import Unitful: Length, fm, pm, nm, μm, m, ustrip

import Devices: bounds, layer, datatype
using ..Points
import ..Rectangles: Rectangle, width, height
import ..Polygons: Polygon, points
using ..Cells

import FileIO: File, @format_str, load, save, stream, magic, skipmagic

const xmlstring = "<?xml version=\"1.0\" encoding=\"UTF-8\" ?>\n"

# https://www.w3schools.com/colors/colors_palettes.asp
const layercolors = Dict(
    0=> "#96ceb4",
    1=> "#ffeead",
    2=> "#ffcc5c",
    3=> "#ff6f69",
    4=> "#588c7e",
    5=> "#f2e394",
    6=> "#f2ae72",
    7=> "#d96459",
    8=> "#f9d5e5",
    9=> "#eeac99",
    10=>"#e06377",
    11=>"#c83349",
    12=>"#5b9aa0",
    13=>"#d6d4e0",
    14=>"#b8a9c9",
    15=>"#622569"
)

function fillcolor(options, layer)
    haskey(options, :layercolors) && haskey(options[:layercolors], layer) &&
        return options[:layercolors][layer]
    haskey(layercolors, layer) && return layercolors[layer]
    return "rgb(0,0,0)"
end

# TODO: Find a package for writing xml tags nicely and use that instead
# TODO: don't just presume we flatten everything. preserve cell structure in svg format.
#       <defs>, <symbol>, <use> tags for arrays, cell references?
function Base.reprmime(::MIME"image/svg+xml", c::Cell; options...)
    opt = Dict{Symbol,Any}(options)
    bnd = ustrip(bounds(c))

    vp = "viewBox=\"$(bnd.ll.x) 0 $(Int(round(width(bnd)))) $(Int(round(height(bnd))))\" "
    wh = haskey(opt, :width)? "width=\"$(opt[:width])\" " : ""
    wh *= haskey(opt, :height)? "height=\"$(opt[:height])\" " : ""

    ly = collect(layers(c))
    trans = Translation(0, bnd.ur.y) ∘ XReflection()
    data = join([group_tag(fillcolor(opt, l), join(
                (
                    polygon_tag(
                        svgify(
                            trans.(ustrip(points(p))),
                        )
                    ) for p in c.elements[layer.(c.elements) .== l]
                ), "")
            ) for l in ly[sortperm(ly)]], "")

    join([xmlstring,
        "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" $vp $wh>\n",
        data,
        "</svg>\n"],"")
end

Base.show(io, mime::MIME"image/svg+xml", c0::Cell; options...) =
    write(io, reprmime(mime, c0; options...))

"""
    save(::Union{AbstractString,IO}, c0::Cell; options...)
    save(f::File{format"SVG"}, c0::Cell; options...)
This bottom method is implicitly called when you use the convenient syntax of
the top method: `save("/path/to/my.gds", cell_i_want_to_save)`

Possible keyword arguments include:
  - `width`: Specifies the width parameter of the SVG tag. Defaults to the width of the cell
    bounding box (stripped of units).
  - `height`: Specifies the height parameter of the SVG tag. Defaults to the height of the
    cell bounding box (stripped of units).
  - `layercolors`: Should be a dictionary with `Int` keys for layers and color strings
    as values. By color strings we mean "#ff0000", "red", "rgb(255,0,0)", etc.
"""
function save(f::File{format"SVG"}, c0::Cell; options...)
    open(f, "w") do s
        io = stream(s)
        show(io, MIME"image/svg+xml"(), c0; options...)
    end
end

# TODO: SVG loader.
"""
    load(f::File{format"SVG"})
Not yet implemented.
"""
function load(f::File{format"SVG"})
    error("svg loading not yet implemented.")
    # open(f) do s
    # end
end

@inline group_tag(fill, polys) = string("<g fill=\"", fill, "\" >\n", polys, "</g>\n")
@inline polygon_tag(points) = string("<polygon points=\"", points, "\" />\n")

function svgify(pts)
    isempty(pts) && return ""
    join((string(Int(round(getx(p))), ",", Int(round(gety(p)))) for p in pts), " ")
end

end
