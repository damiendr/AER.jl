# Support for the DAVIS240 camera.
# DAVIS240 has three different event types.

const DAVIS240_SIZE = (180,240)

""" DVS event (from event-based sensor) """
struct DAVIS240_DVS
    y::Int16
    x::Int16
    ext::Bool
    pol::Bool
end

""" APS packet (from frame-based sensor) """
struct DAVIS240_APS
    y::Int16
    x::Int16
    kind::Int8
    sample::Int16
end

""" IMU packet """
struct DAVIS240_IMU
    channel::Int8
    sample::Int8
end

DAVIS240_Any = Union{DAVIS240_DVS, DAVIS240_APS, DAVIS240_IMU}

""" Extracts the event subtype: DVS, APS or IMU """
event_subtype(data::UInt32) = if ((data >> 31) & 0x1 == 0) DAVIS240_DVS
    elseif ((data >> 10) & 0x03) == 0x03 DAVIS240_IMU
    else DAVIS240_APS
end

# Events can be interpreted as a specific class
# if they have the corresponding subtype:
isevent(T::Type{<:DAVIS240_Any}, e::Event{UInt32}) =
    event_subtype(e.address) === T

event_pol(e::DAVIS240_DVS) = e.pol
event_coord(e::Union{DAVIS240_DVS,DAVIS240_APS}) = (e.x, e.y)
event_location(e::Union{DAVIS240_DVS,DAVIS240_APS}, imsize) = (DAVIS240_SIZE[1]-e.y, e.x+1)

image_size(e::Type{<:Union{DAVIS240_DVS,DAVIS240_APS}}) = DAVIS240_SIZE

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

