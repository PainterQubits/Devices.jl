module Points

export Point
export getx, gety

immutable Point{T<:AbstractFloat}
    x::T
    y::T
end

getx(x::Point) = x.x
gety(x::Point) = x.y

end
