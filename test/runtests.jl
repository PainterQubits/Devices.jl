using Devices
using Base.Test
import Clipper

# write your own tests here
@testset "Points" begin
    @testset "Point constructors" begin
        @test typeof(Point(2,3)) == Point{2,Int}
        @test typeof(Point(2,3.)) == Point{2,Float64}
        @test typeof(Point(2.,3)) == Point{2,Float64}
    end

    @testset "Point arithmetic" begin
        @test Point(2,3) + Point(4,5) == Point(6,8)
        @test Point(1,0) - Point(0,1) == Point(1,-1)
        @test Point(3,3)/3 == Point(1,1)
        @test Point(1,1)*3 == Point(3,3)
        @test 3*Point(1,1) == Point(3,3)
        @test_throws InexactError Point(2,3)/3
    end

    @testset "Point array arithmetic" begin
        @test [Point(1,2), Point(3,4)] .+ Point(1,1) == [Point(2,3), Point(4,5)]
        @test Point(1,1) .+ [Point(1,2), Point(3,4)] == [Point(2,3), Point(4,5)]
        @test [Point(1,2), Point(3,4)] + [Point(1,1), Point(-1,2)] == [Point(2,3), Point(2,6)]
        @test_throws MethodError Point(1,2) + [Point(3,4)]
        # @test_throws MethodError [Point(3,4)] + Point(1,2)    # this one fails

        @test [Point(1,2), Point(3,4)] .- Point(1,1) == [Point(0,1), Point(2,3)]
        @test Point(1,1) .- [Point(1,2), Point(2,3)] == [Point(0,1), Point(1,2)]
        @test [Point(2,3)] - [Point(1,3)] == [Point(1,0)]
        @test_throws MethodError Point(1,2) - [Point(1,0)]
        @test_throws MethodError [Point(2,3)] - Point(1,0)

        @test [Point(1,3)] .* 3 == [Point(3,9)]
        @test [Point(1,3)] * 3 == [Point(3,9)]
        @test 3 .* [Point(1,3)] == [Point(3,9)]
        @test 3 * [Point(1,3)] == [Point(3,9)]
    end

    @testset "Point accessors" begin
        @test getx(Point(1,2)) == 1
        @test gety(Point(1,2)) == 2
    end

    @testset "Point conversion" begin
        @test convert(Point{2,Float64}, Clipper.IntPoint(1,2)) == Point(1.,2.)
        @test convert(Point{2,Int}, Clipper.IntPoint(1,2)) == Point(1,2)
    end
end
