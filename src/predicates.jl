#=
See LICENSE.md.
=#

const Float64Like = Union{Float64, Length{Float64}}

macro Fast_Two_Sum_Tail(a, b, x, y)
    return esc(quote
        bvirt = $x - $a
        $y = $b - bvirt
    end)
end

macro Fast_Two_Sum(a, b, x, y)
    return esc(quote
        $x = $a + $b
        @Fast_Two_Sum_Tail($a, $b, $x, $y)
    end)
end

macro Two_Sum_Tail(a, b, x, y)
    return esc(quote
        bvirt = $x - $a
        avirt = $x - bvirt
        bround = $b - bvirt
        around = $a - avirt
        $y = around + bround
    end)
end

macro Two_Sum(a, b, x, y)
    return esc(quote
        $x = $a + $b
        @Two_Sum_Tail($a, $b, $x, $y)
    end)
end

macro Two_Diff_Tail(a, b, x, y)
    return esc(quote
        bvirt = $a - $x
        avirt = $x + bvirt
        bround = bvirt - $b
        around = $a - avirt
        $y = around + bround
    end)
end

macro Two_Diff(a, b, x, y)
    return esc(quote
        $x = $a - $b
        @Two_Diff_Tail($a, $b, $x, $y)
    end)
end

macro Split(a, ahi, alo)
    return esc(quote
        c = splitter * $a
        abig = c - $a
        $ahi = c - abig
        $alo = $a - $ahi
    end)
end

macro Two_One_Diff(a1, a0, b, x2, x1, x0)
    return esc(quote
        @Two_Diff($a0, $b , _i, $x0)
        @Two_Sum( $a1, _i, $x2, $x1)
    end)
end

macro Two_Two_Diff(a1, a0, b1, b0, x3, x2, x1, x0)
    return esc(quote
        @Two_One_Diff($a1, $a0, $b0, _j, _0, $x0)
        @Two_One_Diff(_j, _0, $b1, $x3, $x2, $x1)
    end)
end

macro Two_Product_Tail(a, b, x, y)
    return esc(quote
        @Split($a, ahi, alo)
        @Split($b, bhi, blo)
        err1 = $x - (ahi * bhi)
        err2 = err1 - (alo * bhi)
        err3 = err2 - (ahi * blo)
        $y = (alo * blo) - err3
    end)
end

macro Two_Product(a, b, x, y)
    return esc(quote
        $x = $a * $b
        @Two_Product_Tail($a, $b, $x, $y)
    end)
end

function orient2dadapt(pa::Point{T}, pb::Point{T}, pc::Point{T}, detsum,
            ccwerrboundB::Float64 = Devices.ccwerrboundB,
            ccwerrboundC::Float64 = Devices.ccwerrboundC,
            resulterrbound::Float64 = Devices.resulterrbound) where {T}
    z = zero(T)*zero(T)
    B = Vector{typeof(z)}(undef, 4)
    C1 = Vector{typeof(z)}(undef, 8)
    C2 = Vector{typeof(z)}(undef, 12)
    D = Vector{typeof(z)}(undef, 16)
    u = Vector{typeof(z)}(undef, 4)

    acx = pa[1] - pc[1]
    bcx = pb[1] - pc[1]
    acy = pa[2] - pc[2]
    bcy = pb[2] - pc[2]

    @Two_Product(acx, bcy, detleft, detlefttail)
    @Two_Product(acy, bcx, detright, detrighttail)

    @Two_Two_Diff(detleft, detlefttail, detright, detrighttail,
               B3, B[3], B[2], B[1])
    B[4] = B3

    det = sum(B)
    errbound = ccwerrboundB * detsum
    if (det >= errbound) || (-det >= errbound)
        return sign(det)
    end

    @Two_Diff_Tail(pa[1], pc[1], acx, acxtail)
    @Two_Diff_Tail(pb[1], pc[1], bcx, bcxtail)
    @Two_Diff_Tail(pa[2], pc[2], acy, acytail)
    @Two_Diff_Tail(pb[2], pc[2], bcy, bcytail)

    if (acxtail == z) && (acytail == z) && (bcxtail == z) && (bcytail == z)
        return sign(det)
    end

    errbound = ccwerrboundC * detsum + resulterrbound * abs(det)
    det += (acx * bcytail + bcy * acxtail) - (acy * bcxtail + bcx * acytail)
    if (det >= errbound) || (-det >= errbound)
        return sign(det)
    end

    @Two_Product(acxtail, bcy, s1, s0)
    @Two_Product(acytail, bcx, t1, t0)
    @Two_Two_Diff(s1, s0, t1, t0, u3, u[3], u[2], u[1])
    u[4] = u3
    C1length = fast_expansion_sum_zeroelim(4, B, 4, u, C1)

    @Two_Product(acx, bcytail, s1, s0)
    @Two_Product(acy, bcxtail, t1, t0)
    @Two_Two_Diff(s1, s0, t1, t0, u3, u[3], u[2], u[1])
    u[4] = u3
    C2length = fast_expansion_sum_zeroelim(C1length, C1, 4, u, C2)

    @Two_Product(acxtail, bcytail, s1, s0)
    @Two_Product(acytail, bcxtail, t1, t0)
    @Two_Two_Diff(s1, s0, t1, t0, u3, u[3], u[2], u[1])
    u[4] = u3
    Dlength = fast_expansion_sum_zeroelim(C2length, C2, 4, u, D)

    return sign(D[Dlength])
end

function orientation(pa::Point{T}, pb::Point{T}, pc::Point{T},
            ccwerrboundA::Float64 = Devices.ccwerrboundA) where {T <: Float64Like}
    detleft = (pa[1] - pc[1]) * (pb[2] - pc[2])
    detright = (pa[2] - pc[2]) * (pb[1] - pc[1])
    det = detleft - detright

    if detleft > zero(detleft)
        if detright <= zero(detright)
            return sign(det)
        else
            detsum = detleft + detright
        end
    elseif detleft < zero(detleft)
        if detright >= zero(detright)
            return sign(det)
        else
            detsum = -detleft - detright
        end
    else
        return sign(det)
    end

    errbound = ccwerrboundA * detsum
    if (det >= errbound) || (-det >= errbound)
        return sign(det)
    end

    return orient2dadapt(pa, pb, pc, detsum)
end

# h cannot be e or f.
function fast_expansion_sum_zeroelim(elen::Int, e, flen::Int, f, h)
    enow = e[1]
    fnow = f[1]
    eindex = findex = 1
    if (fnow > enow) == (fnow > -enow)
        Q = enow
        eindex += 1
        enow = e[eindex]
    else
        Q = fnow
        findex += 1
        fnow = f[findex]
    end
    hindex = 0
    if (eindex <= elen) && (findex <= flen)
        if (fnow > enow) == (fnow > -enow)
            @Fast_Two_Sum(enow, Q, Qnew, hh)
            eindex += 1
            if eindex <= elen
                enow = e[eindex]
            end
        else
            @Fast_Two_Sum(fnow, Q, Qnew, hh)
            findex += 1
            if findex <= flen
                fnow = f[findex]
            end
        end
        Q = Qnew
        if hh != zero(hh)
            hindex += 1
            h[hindex] = hh
        end
        while (eindex <= elen) && (findex <= flen)
            if (fnow > enow) == (fnow > -enow)
                @Two_Sum(Q, enow, Qnew, hh)
                eindex += 1
                if eindex <= elen
                    enow = e[eindex]
                end
            else
                @Two_Sum(Q, fnow, Qnew, hh)
                findex += 1
                if findex <= flen
                    fnow = f[findex]
                end
            end
            Q = Qnew
            if hh != zero(hh)
                hindex += 1
                h[hindex] = hh
            end
        end
    end
    while eindex <= elen
        @Two_Sum(Q, enow, Qnew, hh)
        eindex += 1
        if eindex <= elen
            enow = e[eindex]
        end
        Q = Qnew
        if hh != zero(hh)
            hindex += 1
            h[hindex] = hh
        end
    end
    while findex <= flen
        @Two_Sum(Q, fnow, Qnew, hh)
        findex += 1
        if findex <= flen
            fnow = f[findex]
        end
        Q = Qnew
        if hh != zero(hh)
            hindex += 1
            h[hindex] = hh
        end
    end
    if (Q != zero(Q)) || (hindex == 0)
        hindex += 1
        h[hindex] = Q
    end
    return hindex
end
