# Support for AEDAT 1.0 files
# https://inivation.com/support/software/fileformat/

struct AEDAT1Event{A}
    address::A
    timestamp::Int32
end

function read(io::IO, T::Type{AEDAT1Event{A}}) where A
    a = read(io, UInt16)::UInt16
    t = read(io, UInt32)::UInt32
    AEDAT1Event(convert(A,ntoh(a)), reinterpret(Int32, ntoh(t)))
end

