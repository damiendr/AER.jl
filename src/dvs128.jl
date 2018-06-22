# Support for the DVS128 camera.

const DVS128_SIZE = (128,128)

""" Event class for the DVS128 """
struct DVS128
    pol::Bool
    x::Int8
    y::Int8
    ext::Bool
end

function Base.convert(::Type{DVS128}, a::Union{UInt16,UInt32})
    # Unpack the DVS128 fields from a 16-bit or 32-bit address:
    pol = a & 0x1
    x = (a >> 1) & 0x7F
    y = (a >> 8) & 0x7F
    ext = (a >> 15) & 0x1
    DVS128(pol, x, y, ext)
end

event_coord(e::DVS128) = (e.x, e.y)
event_pol(e::DVS128) = e.pol
event_location(e::DVS128, imsize) = (DVS128_SIZE[1]-e.y, e.x+1)

image_size(e::Type{DVS128}) = DVS128_SIZE

# There's no positive way to identify a DVS128 event.
# These are normally not mixed with other event types
# anyways. They can be found in 1.0 and 2.0 files.
isevent(::Type{DVS128}, a::Event{UInt16}) = true
isevent(::Type{DVS128}, a::Event{UInt32}) = true

