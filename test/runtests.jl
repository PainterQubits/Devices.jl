using Base.Test
using Devices
using Unitful
import Unitful: m, cm, nm, μm, s, °, rad, DimensionError
import Clipper
import ForwardDiff

# This is needed in case the user has changed the default length promotion type.
ru = promote_type(typeof(m),typeof(cm))()

@testset "Points" begin
    @testset "> Point constructors" begin
        @test_throws ErrorException Point(2,3m)
        @test_throws ErrorException Point(2s,3s)    # has to be a length
        @test typeof(Point(2,3)) == Point{Int}
        @test typeof(Point(2,3.)) == Point{Float64}
        @test typeof(Point(2.,3)) == Point{Float64}
        @test typeof(Point(2m,3.0m)) == Point{typeof(3.0ru)}
        @test typeof(Point(2m,3cm)) == Point{typeof(2ru//1)}
        @test typeof(Point(2.0m,3cm)) == Point{typeof(2.0ru)}
    end

    @testset "> Point arithmetic" begin
        @test Point(2,3) + Point(4,5) == Point(6,8)
        @test Point(1,0) - Point(0,1) == Point(1,-1)
        @test Point(3,3)/3 == Point(1,1)
        @test Point(1,1)*3 == Point(3,3)
        @test 3*Point(1,1) == Point(3,3)
        @test Point(2m,3m) + Point(4m,5m) == Point(6m,8m)
        @test Point(2m,3m) + Point(4cm,5cm) == Point(204ru//100,305ru//100)
        @test Point(2.0m,3m) + Point(4cm,5cm) == Point(2.04ru,3.05ru)
    end

    @testset "> Point array arithmetic" begin
        @test [Point(1,2), Point(3,4)] .+ Point(1,1) == [Point(2,3), Point(4,5)]
        @test Point(1,1) .+ [Point(1,2), Point(3,4)] == [Point(2,3), Point(4,5)]
        @test [Point(1,2), Point(3,4)] + [Point(1,1), Point(-1,2)] == [Point(2,3), Point(2,6)]
        @test_throws ErrorException Point(1,2) + [Point(3,4)]
        @test_throws ErrorException [Point(1,2)] + Point(3,4)

        @test [Point(1,2), Point(3,4)] .- Point(1,1) == [Point(0,1), Point(2,3)]
        @test Point(1,1) .- [Point(1,2), Point(2,3)] == [Point(0,-1), Point(-1,-2)]
        @test [Point(2,3)] - [Point(1,3)] == [Point(1,0)]
        @test_throws ErrorException Point(1,2) - [Point(1,0)]
        @test_throws ErrorException [Point(2,3)] - Point(1,0)

        @test [Point(1,3)] .* 3 == [Point(3,9)]
        @test [Point(1,3)] * 3 == [Point(3,9)]
        @test 3 .* [Point(1,3)] == [Point(3,9)]
        @test 3 * [Point(1,3)] == [Point(3,9)]

        @test [Point(1m,2m)] + [Point(1cm,2cm)] == [Point(101ru//100, 202ru//100)]
        @test [Point(1m,2m)] .+ Point(1cm,2cm) == [Point(101ru//100, 202ru//100)]
        @test [Point(1m,2m)] - [Point(1cm,2cm)] == [Point(99ru//100, 198ru//100)]
        @test [Point(1m,2m)] .- Point(1cm,2cm) == [Point(99ru//100, 198ru//100)]
    end

    @testset "> Point accessors" begin
        @test getx(Point(1,2)) == 1
        @test gety(Point(1,2)) == 2
    end

    @testset "> Point conversion" begin
        @test [Point(1,3), Point(2,4)] .* m == [Point(1m,3m), Point(2m,4m)]
        @test convert(Point{Float64}, Clipper.IntPoint(1,2)) == Point(1.,2.)
        @test convert(Point{Int}, Clipper.IntPoint(1,2)) == Point(1,2)
    end
end

@testset "Polygon basics" begin
    @testset "> Rectangle construction" begin
        # lower-left and upper-right constructor
        r = Rectangle(Point(1,2), Point(2,0))
        @test typeof(r) == Rectangle{Int}
        @test r.ll == Point(1,0)
        @test r.ur == Point(2,2)

        # with units
        # @test typeof(Rectangle(Point(1m,2cm), Point(3nm,4μm))) ==
            # Rectangle{typeof(1ru//1)} #TODO: uncomment once Julia #18465 is fixed

        # width and height constructor
        @test typeof(Rectangle(1,2)) == Rectangle{Int}
        @test typeof(Rectangle(1.0,2)) == Rectangle{Float64}
        @test typeof(Rectangle(1.0m,2.0μm)) == Rectangle{typeof(1.0*ru)}
    end

    @testset "> Polygon construction" begin
        @test_throws ErrorException Polygon(Point(1,2), Point(3,5), Point(4cm,7cm))
    end

    @testset "> Rectangle methods" begin
        # width and height
        @test width(Rectangle(1,2)) == 1
        @test height(Rectangle(1,2)) == 2
        @test width(Rectangle(1m,2m)) == 1m
        @test height(Rectangle(1m,2m)) == 2m

        # propriety
        @test Rectangle(Point(3,3),Point(0,0)) ==
            Rectangle(Point(0,0), Point(3,3))
        @test isproper(Rectangle(3,3))
        @test !isproper(Rectangle(0,0))

        # centering
        @test_throws InexactError centered!(Rectangle(1,1))
        @test_throws InexactError centered!(Rectangle(1m,1m))
        @test centered(Rectangle(1,1)) ==
            Rectangle(Point(-0.5,-0.5), Point(0.5,0.5))

        # Rectangle equality
        @test Rectangle(1,2) == Rectangle(1,2)
        @test Rectangle(1,2) ≈ Rectangle(1,2)

        # Rectangle bounds
        @test bounds(Rectangle(1,2)) == Rectangle(1,2)
    end

    @testset "> Polygon methods" begin
        pfloat = Polygon(Point(0.0m, 0.0m),
                         Point(1.0m, 0.0m),
                         Point(0.0m, 1.0m))
        # Polygon equality
        @test pfloat == Polygon(Point(0.0m, 0.0m),
                         Point(1.0m, 0.0m),
                         Point(0.0m, 1.0m))
        @test pfloat ≈ Polygon(Point(0.0m, 0.0m),
                         Point(1.0m, 0.0m),
                         Point(0.0m, 1.0m))

        # Bounds
        @test bounds(pfloat) ≈ Rectangle(1m,1m)
    end
end

@testset "Polygon coordinate transformations" begin
    pfloat = Polygon(Point(0.0m, 0.0m),
                     Point(1.0m, 0.0m),
                     Point(0.0m, 1.0m))
    pint = Polygon(Point(0m,0m),
                   Point(1m,0m),
                   Point(0m,1m))
    rfloat = Rectangle(1.0m,1.0m)
    rint = Rectangle(1m,1m)
    rinttr = Rectangle(Point(1m,2m), Point(2m,3m))
    pfloatrot = Polygon(Point(0.0m, 0.0m),
                        Point(0.0m, 1.0m),
                        Point(-1.0m, 0.0m))
    pfloattr = Polygon(Point(1.0m, 2.0m),
                       Point(2.0m, 2.0m),
                       Point(1.0m, 3.0m))
    rotDeg = Rotation(90°)
    rotRad = Rotation(π/2*rad)
    rotFlt = Rotation(π/2)
    trU = Translation(1m, 2m)
    @test rotDeg(pfloat) ≈ pfloatrot
    @test rotRad(pfloat) ≈ pfloatrot
    @test rotFlt(pfloat) ≈ pfloatrot
    @test rotDeg(pint) ≈ pfloatrot
    @test rotRad(pint) ≈ pfloatrot
    @test rotFlt(pint) ≈ pfloatrot
    @test trU(pfloat) ≈ pfloattr
    @test trU(pint) ≈ pfloattr
    @test trU(rint) == rinttr
    @test trU(rfloat) == rinttr
end

@testset "Polygon clipping" begin
    @testset "> Clipping individuals w/o units" begin
        # Rectangle{Int}, Rectangle{Int} clipping
        r1 = Rectangle(2,2)
        r2 = Rectangle(1,2)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{Int}[(2,2),(1,2),(1,0),(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{Int}

        # Rectangle{Int}, Polygon{Int} clipping
        p2 = Polygon(Point{Int}[(0,0), (1,0), (1,2), (0,2)])
        @test clip(Clipper.ClipTypeDifference, r1, p2)[1] ==
            Polygon(Point{Int}[(2,2),(1,2),(1,0),(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, p2)[1]) ==
            Polygon{Int}

        # Polygon{Int}, Polygon{Int} clipping
        p1 = Polygon(Point{Int}[(0,0), (2,0), (2,2), (0,2)])
        @test clip(Clipper.ClipTypeDifference, p1, p2)[1] ==
            Polygon(Point{Int}[(2,2),(1,2),(1,0),(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, p1, p2)[1]) ==
            Polygon{Int}

        # Rectangle{Float64}, Rectangle{Float64} clipping
        r1 = Rectangle(2.0,2.0)
        r2 = Rectangle(1.0,2.0)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{Float64}[(2.0,2.0),(1.0,2.0),(1.0,0.0),(2.0,0.0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{Float64}

        # Rectangle{Float64}, Polygon{Float64} clipping
        p2 = Polygon(Point{Float64}[(0,0), (1,0), (1,2), (0,2)])
        @test clip(Clipper.ClipTypeDifference, r1, p2)[1] ==
            Polygon(Point{Float64}[(2,2),(1,2),(1,0),(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, p2)[1]) ==
            Polygon{Float64}

        # Polygon{Float64}, Polygon{Float64} clipping
        p1 = Polygon(Point{Float64}[(0,0), (2,0), (2,2), (0,2)])
        @test clip(Clipper.ClipTypeDifference, p1, p2)[1] ==
            Polygon(Point{Float64}[(2,2),(1,2),(1,0),(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, p1, p2)[1]) ==
            Polygon{Float64}

        # Test a case where the AbstractPolygon subtypes and numeric types are mixed
        # Rectangle{Int}, Polygon{Float64} clipping
        r2 = Rectangle(1,2)
        @test clip(Clipper.ClipTypeDifference, p1, r2)[1] ==
            Polygon(Point{Float64}[(2,2),(1,2),(1,0),(2,0)])
        @test typeof(clip(Clipper.ClipTypeDifference, p1, r2)[1]) ==
            Polygon{Float64}
    end

    @testset "> Clipping individuals w/units" begin
        # Rectangle{typeof(1μm)}, Rectangle{typeof(1μm)} clipping
        r1 = Rectangle(2μm,2μm)
        r2 = Rectangle(1μm,2μm)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{typeof(1μm)}[(2μm,2μm),(1μm,2μm),(1μm,0μm),(2μm,0μm)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{typeof(1μm)}

        r1 = Rectangle(2.0μm,2.0μm)
        r2 = Rectangle(1.0μm,2.0μm)
        @test clip(Clipper.ClipTypeDifference, r1, r2)[1] ==
            Polygon(Point{typeof(1.0μm)}[(2μm,2μm),(1μm,2μm),(1μm,0μm),(2μm,0μm)])
        @test typeof(clip(Clipper.ClipTypeDifference, r1, r2)[1]) ==
            Polygon{typeof(1.0μm)}

        # MIXED UNITS do not behave ideally yet.
    end

    @testset "> Clipping arrays w/o units" begin
        r1 = Rectangle(2,2)
        s = [r1, r1+Point(0,4), r1+Point(0,8)]
        c = [Rectangle(1,10)]
        r = clip(Clipper.ClipTypeDifference, s, c)
        @test Polygon(Point{Int}[(2,2),(1,2),(1,0),(2,0)]) in r
        @test Polygon(Point{Int}[(2,6),(1,6),(1,4),(2,4)]) in r
        @test Polygon(Point{Int}[(2,10),(1,10),(1,8),(2,8)]) in r
        @test length(r) == 3
    end
end

@testset "Polygon offsetting" begin
    r = Rectangle(1, 1)
    @test offset(r, 1)[1] ==
        Polygon([Point(2,2),Point(-1,2),Point(-1,-1),Point(2,-1)])
    @test_throws DimensionError offset(r,1μm)

    r = Rectangle(1.0, 1.0)
    @test offset(r, 0.5)[1] ==
        Polygon(Point{Float64}[(1.5, 1.5),(-0.5, 1.5),(-0.5, -0.5),(1.5, -0.5)])
    @test_throws DimensionError offset(r, 0.5μm)

    r = Rectangle(1μm, 1μm)
    @test_throws DimensionError offset(r, 1)
    @test offset(r, 1μm)[1] == Polygon(
        Point{typeof(1μm)}[(2μm, 2μm),(-1μm, 2μm),(-1μm, -1μm),(2μm, -1μm)])
    @test offset(r, 5000nm)[1] == Polygon(
        Point{typeof(1μm)}[(6μm, 6μm),(-5μm, 6μm),(-5μm, -5μm),(6μm, -5μm)])

    r = Rectangle(1.0μm, 1.0μm)
    @test_throws DimensionError offset(r, 1.0)
    @test offset(r, 50nm)[1] ≈ Polygon(
        Point{typeof(0.5μm)}[(1.05μm,1.05μm),(-0.05μm,1.05μm),
                             (-0.05μm,-0.05μm),(1.05μm,-0.05μm)])

end

@testset "Cell methods" begin
    # Setup nested cell refs
    c = Cell("main")
    c2 = Cell("c2")
    c3 = Cell("c3")
    r = Rectangle(5,10)
    @test_throws Unitful.DimensionError render!(c3, Rectangle(5m,10m))
    render!(c3, r)
    c2ref = CellReference(c2, Point(-10.0,0.0); mag=1.0, rot=180°)
    @test c2ref.cell === c2
    c3ref = CellReference(c3, Point(10.0,0.0); mag=2.0, rot=90°)
    push!(c.refs, c2ref)
    push!(c2.refs, c3ref)
    tr = transform(c,c3ref)

    # Test cell transformations
    @test tr(Point(1,1)) ≈ Point(-18.0,-2.0)
    @test c["c2"]["c3"] == c3ref
    c′ = c + Point(10.0,10.0)
    c2ref′ = c2ref + Point(10.,10.)

    # Test bounds with cell refs
    @test bounds(c3) == r
    @test bounds(c2) == bounds(c3ref)
    @test bounds(c) == bounds(c2ref)
    @test bounds(c′) ≈ (bounds(c) + Point(10.0,10.0))
    @test bounds(c2ref′) ≈ (bounds(c2ref) + Point(10.,10.))

    # More setup
    c = Cell("main")
    c2 = Cell("rect")
    render!(c2, Rectangle(5,5))
    arr = CellArray(c2, Point(0,0); dc=Point(10,0), dr=Point(0,10),
        ncols=10, nrows=10)
    @test arr.cell === c2
    push!(c.refs, arr)

    # Test bounds with cell arrays
    @test bounds(c) == Rectangle(95,95)

    # TODO: Tests for `flatten`
end

@testset "Paths" begin
    @testset "> Path constructors" begin
        @test typeof(Path()) == Path{Float64}
        @test typeof(Path(Point(0.0μm, 0.0μm))) == Path{typeof(1.0μm)}
        @test α0(Path(Point(0.0μm, 0.0μm); α0 = 90°)) == 90.0° == π*rad/2 == π/2
        @test α0(Path(Point(0.0μm, 0.0μm); α0 = π/2)) == 90.0° == π*rad/2 == π/2
    end

    @testset "> Path segments" begin
        p = Path(Point(0.0μm, 0.0μm))
        @test_throws Unitful.DimensionError straight!(p, 10.0)
        @test pathlength(p) == 0.0μm
        straight!(p, 10μm)
        @test pathlength(p) == 10μm
        @test ForwardDiff.derivative(p[1].seg.f, 0.0) ≈ Point(10.0μm, 0.0μm)
    end

    # TODO: How to test `CompoundSegment` / `CompoundStyle`?
    # TODO: How to test `DecoratedStyle` / `attach!`?
end

# TODO: How to test GDS import?
# TODO: How to test GDS export? diff with known good result files?
