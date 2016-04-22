module Points

import Base.convert
import FixedSizeArrays: FixedVectorNoTuple, Point
import PyCall.PyObject
export Point
export getx, gety

"""
`getx(p::Point)`

Get the x-coordinate of a point.
"""
@inline getx(p::Point) = p._[1]

"""
`gety(p::Point)`

Get the y-coordinate of a point.
"""
@inline gety(p::Point) = p._[2]

# For use with gdspy
PyObject(p::Point) = PyObject((getx(p), gety(p)))

end
