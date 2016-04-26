@enum GPCOp GPC_DIFF GPC_INT GPC_XOR GPC_UNION

immutable GPCVertex
    x::Cdouble
    y::Cdouble
end

immutable GPCVertexList
    num_vertices::Cint
    gpc_vertex::Ptr{GPCVertex}
end
# GPCVertexList(x::Polygon) = GPCVertexList(length(x.p), pointer(x.p))

immutable GPCPolygon
    num_contours::Cint
    hole::Ptr{Cint}
    contour::Ptr{GPCVertexList}
end

immutable GPCTristrip
    num_strips::Cint
    strip::Ptr{GPCVertexList}
end

"""
`gpc_clip(op::GPCOp, subject::Polygon{Cdouble}, clip::Polygon{Cdouble})`

Use the GPC clipping library to do polygon manipulations.
Valid GPCOp include `GPC_DIFF`, `GPC_INT`, `GPC_XOR`, `GPC_UNION`.
"""
function gpc_clip(op::GPCOp, subject::Polygon{Cdouble}, clip::Polygon{Cdouble})
    # Prepare polygons for use with GPC
    v_subj = reinterpret(GPCVertex, subject.p)
    v_clip = reinterpret(GPCVertex, clip.p)
    vl_subj = GPCVertexList(Cint(length(v_subj)), pointer(v_subj))
    vl_clip = GPCVertexList(Cint(length(v_clip)), pointer(v_clip))
    vla_subj = GPCVertexList[vl_subj]
    vla_clip = GPCVertexList[vl_clip]
    hole_subj = Cint[0]
    hole_clip = Cint[0]
    gpc_subj = GPCPolygon(Cint(1), pointer(hole_subj), pointer(vla_subj))
    gpc_clip = GPCPolygon(Cint(1), pointer(hole_clip), pointer(vla_clip))

    p = ccall((:jl_gpc_tristrip_clip, "gpc"), GPCTristrip,
        (Cint, Ptr{GPCPolygon}, Ptr{GPCPolygon}),
        op, pointer_from_objref(gpc_subj), pointer_from_objref(gpc_clip))

    vertex_lists = pointer_to_array(p.strip, (p.num_strips,), false)
    tristrips = Array{Tristrip{Cdouble},1}(length(vertex_lists))
    for (i,vl) in enumerate(vertex_lists)
        vertices = pointer_to_array(vl.gpc_vertex, (vl.num_vertices,), false)
        tristrips[i] = Tristrip(deepcopy(reinterpret(Point{2,Cdouble}, vertices)))
    end

    # Convert the tristrips to polygons
    polys = Array{Polygon{Cdouble},1}()
    for i in 1:length(tristrips)
        append!(polys, convert(Array{Polygon{Cdouble},1}, tristrips[i]))
    end

    # Free memory used by GPC
    ccall((:gpc_free_tristrip, "gpc"), Void, (Ptr{GPCTristrip},), pointer_from_objref(p))

    polys
end
