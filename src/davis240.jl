# Support for the DAVIS240 camera.

struct DAVIS240_DVS
    y::Int16
    x::Int16
    ext::Bool
    pol::Bool
end

struct DAVIS240_APS
    y::Int16
    x::Int16
    kind::Int8
    sample::Int16
end

struct DAVIS240_IMU
    channel::Int8
    sample::Int8
end

DAVIS240_Any = Union{DAVIS240_DVS, DAVIS240_APS, DAVIS240_IMU}

event_subtype(data::UInt32) = if ((data >> 31) & 0x1 == 0) DAVIS240_DVS
    elseif ((data >> 10) & 0x03) == 0x03 DAVIS240_IMU
    else DAVIS240_APS
end

isevent(T::Type{<:DAVIS240_Any}, e::AEDATEvent{UInt32}) =
    event_subtype(e.address) === T

function Base.convert(::Type{DAVIS240_DVS}, a::UInt32)
    y = (a >> 22) & 0x01FF
    x = (a >> 12) & 0x01FF
    ext = (a >> 10) & 0x1
    pol = (a >> 11) & 0x1
    DAVIS240_DVS(y, x, ext, pol)
end

function Base.convert(::Type{DAVIS240_APS}, a::UInt32)
    y = (a >> 22) & 0x01FF
    x = (a >> 12) & 0x01FF
    kind = (a >> 10) & 0x03
    sample = a & 0x03FF
    DAVIS240_APS(y, x, kind, sample)
end

function Base.convert(::Type{DAVIS240_IMU}, a::UInt32)
    channel = (a >> 28) & 0x07
    sample = (a >> 12) & 0x7fff
    DAVIS240_IMU(channel, sample)
end

""" Draw events at their location on a 2D canvas """
function draw_events(events::Vector{<:AEDATEvent{DAVIS240_DVS}})
    canvas = zeros(180,240)
    for e in events
        i = 180 - e.address.y
        j = e.address.x+1
        canvas[i,j] += e.address.pol ? 1 : -1
    end
    canvas
end

""" Returns the (times,locations,polarities) of the supplied events. """
function spike_locs(events::Vector{<:AEDATEvent{DAVIS240_DVS}})
    ts = collect(e.timestamp for e in events)
    id = collect(e.address.y * 240 + e.address.x for e in events)
    pol = collect(e.address.pol for e in events)
    ts, id, pol
end
