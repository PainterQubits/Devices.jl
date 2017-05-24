include("rectangles.jl")
include("polygons.jl")
include("paths.jl")
include("corners.jl")
include("trace.jl")
include("cpw.jl")
include("decorated.jl")
include("compound.jl")

# Generic fallback methods
render!(c::Cell, p::Rectangle, s::Rectangles.Style=Rectangles.Plain();
        layer::Int = DEFAULT_LAYER, datatype::Int = DEFAULT_DATATYPE) =
    render!(c, p, s, GDSMeta(layer, datatype))
render!(c::Cell, p::Rectangle, meta::Meta) = render!(c, p, Rectangles.Plain(), meta)

render!(c::Cell, p::Polygon, s::Polygons.Style=Polygons.Plain();
        layer::Int = DEFAULT_LAYER, datatype::Int = DEFAULT_DATATYPE) =
    render!(c, p, s, GDSMeta(layer, datatype))
render!(c::Cell, p::Polygon, meta::Meta) = render!(c, p, Polygons.Plain(), meta)

render!(c::Cell, seg::Paths.Segment, s::Paths.Style;
        layer::Int = DEFAULT_LAYER, datatype::Int = DEFAULT_DATATYPE, kwargs...) =
    render!(c, seg, s, GDSMeta(layer, datatype); kwargs...)

# If there's no specific method for this segment type, use the fallback method for the style.
render!(c::Cell, seg::Paths.Segment, s::Paths.Style, meta::Meta; kwargs...) =
    render!(c, seg, pathlength(seg), s, meta; kwargs...)

# NoRender and friends
function render!(c::Cell, seg::Paths.Segment, s::Paths.NoRender, meta::Meta; kwargs...) end
function render!(c::Cell, seg::Paths.Segment, s::Paths.NoRenderContinuous, meta::Meta;
    kwargs...) end
function render!(c::Cell, seg::Paths.Segment, s::Paths.NoRenderDiscrete, meta::Meta;
    kwargs...) end
function render!(c::Cell, seg::Paths.Segment, s::Paths.SimpleNoRender,
    meta::Meta; kwargs...) end
