
struct DVS128
    pol::Bool
    y::Int8
    x::Int8
    ext::Bool
end

function Base.convert(::Type{DVS128}, a::Union{UInt16,UInt32})
    pol = a & 0x1
    y = (a >> 1) & 0x7F
    x = (a >> 8) & 0x7F
    ext = (a >> 15) & 0x1
    DVS128(pol, y, x, ext)
end

