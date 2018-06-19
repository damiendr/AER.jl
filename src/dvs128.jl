# Support for the DVS128 camera.

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

isevent(::Type{DVS128}, a::AEDATEvent) = true

""" Draw events at their location on a 2D canvas """
function draw_events(events::Vector{<:AEDATEvent{DVS128}})
    canvas = zeros(128,128)
    for e in events
        i = 128 - e.address.y
        j = e.address.x+1
        canvas[i,j] += e.address.pol ? 1 : -1
    end
    canvas
end

""" Returns the (times,locations,polarities) of the supplied events. """
function spike_locs(events::Vector{<:AEDATEvent{DVS128}})
    ts = collect(e.timestamp for e in events)
    id = collect(e.address.y * 128 + e.address.x for e in events)
    pol = collect(e.address.pol for e in events)
    ts, id, pol
end
