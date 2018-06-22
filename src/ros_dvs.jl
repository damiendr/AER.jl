# Support for data produced by the DVS ROS driver:
# https://github.com/uzh-rpg/rpg_dvs_ros

module ROSDVS

using RobotOSData

import AddressEvent.read_events!
import AddressEvent.event_time
import AddressEvent.event_coord
import AddressEvent.event_location
import AddressEvent.event_pol


struct DVSEvent
    x::Int16
    y::Int16
    time_s::UInt32
    time_ns::UInt32
    pol::Bool
end

struct DVSMessage
    header::RobotOSData.Header
    height::Int32
    width::Int32
    events::Vector{DVSEvent}
end

event_time(e::DVSEvent) = e.time_s*1000000 + e.time_ns÷1000
event_coord(e::DVSEvent) = (e.x, e.y)
event_location(e::DVSEvent, imsize) = (e.y+1, e.x+1)
event_pol(e::DVSEvent) = e.pol


function Base.read(io::IO, ::Type{DVSEvent})
    x = ltoh(read(io, Int16))
    y = ltoh(read(io, Int16))
    s = ltoh(read(io, UInt32))
    ns = ltoh(read(io, UInt32))
    pol = read(io, UInt8)
    DVSEvent(x, y, s, ns, pol)
end

function Base.read(io::IO, ::Type{DVSMessage})
    header = read(io, RobotOSData.Header)
    height = ltoh(read(io, Int32))
    width = ltoh(read(io, Int32))
    events = read_array(io, DVSEvent)
    DVSMessage(header, height, width, events)
end

"""
Reads a message from `io`, stores the events in `out`,
and returns the frame size `(height, width)`.
"""
function read_events!(io::IO, out::Vector{DVSEvent})
    header = read(io, RobotOSData.Header)
    height = ltoh(read(io, Int32))
    width = ltoh(read(io, Int32))
    read_array!(out, io, DVSEvent)
    return (height, width)
end

export DVSEvent, DVSMessage

end # module
