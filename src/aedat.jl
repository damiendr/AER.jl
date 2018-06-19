# Support for AEDAT files
# https://inivation.com/support/software/fileformat/


const HEADER_RE = r"#\!AER\-DAT(\d)\.(\d)\r\n"
const HEADER_BYTES = 14


""" An AEDAT file version X.Y """
struct AEDATFile{X,Y,I<:IO}
    header::Vector{String}
    io::I
end

""" Opens an AEDAT file. """
AEDATFile(filename::AbstractString) = AEDATFile(open(filename))

""" Opens a stream as an AEDAT file. """
function AEDATFile(io::IO)
    header = String[]
    X = 1
    Y = 0
    # AEDAT files use a header to encode
    # the version number: '#!AER-DATX.Y'.
    # If it's missing, we have a 1.0 file.
    mark(io)
    head_str = convert(String, read(io, HEADER_BYTES))
    head_match = match(HEADER_RE, head_str)
    if head_match != nothing
        # Found a header. Let's parse the version
        # number and any subsequent header lines:
        X = parse(head_match.captures[1])::Int
        Y = parse(head_match.captures[2])::Int
        read_header!(io, header)
    else
        # No header for some 1.0 files
        reset(io)
    end
    AEDATFile{X,Y,typeof(io)}(header, io)
end

""" Closes an AEDAT file. """
Base.close(dat::AEDATFile) = close(dat.io)

""" Reads header lines and leaves the stream
at the start of the content section. """
function read_header!(io::IO, header)
    while true
        mark(io)
        c = read(io, Char)
        if c == '#'
            line = readuntil(io, "\r\n")
            push!(header, line)
        else
            break
        end
    end
    reset(io)
    nothing
end

""" AEDAT 1.0 or 2.0 event with address type A """
struct AEDATEvent{A}
    address::A
    timestamp::Int32
end

Base.convert(::Type{AEDATEvent{C}}, event::AEDATEvent) where {C} =
    AEDATEvent{C}(convert(C,event.address), event.timestamp)


""" Reads a single raw event from a stream """
function Base.read(io::IO, T::Type{AEDATEvent{A}}) where {A<:Unsigned}
    a = read(io, A)::A
    t = read(io, UInt32)::UInt32
    T(ntoh(a), reinterpret(Int32, ntoh(t)))
end

raw_event_type(dat::AEDATFile{1,0}) = AEDATEvent{UInt16}
raw_event_type(dat::AEDATFile{2,0}) = AEDATEvent{UInt32}

isevent(::Type, e::AEDATEvent) = false
isevent(::Type{T}, e::AEDATEvent{T}) where {T} = true


""" Reads a single raw event """
read_event(dat::AEDATFile) = read(dat.io, raw_event_type(dat))

""" Reads a single event as class C """
read_event(dat::AEDATFile, C) = convert(AEDATEvent{C}, read_event(dat))


""" Reads the next events of class C, ignoring other event types """
function read_events(dat::AEDATFile, C, maxcount=-1)
    events = AEDATEvent{C}[]
    while !eof(dat.io)
        raw = read_event(dat)
        if isevent(C, raw)
            event = convert(AEDATEvent{C}, raw)
            push!(events, event)
            if maxcount != -1 && length(events) >= maxcount
                break
            end
        end
    end
    events
end


""" Iterates over events of class `C`, grouped into frames of duration `period` (typ. us) """
function iter_frames(dat::AEDATFile, C, period::Integer)
    out = Channel{Vector{AEDATEvent{C}}}(0)
    @schedule iter_frames(dat, C, period, out)
    out
end

function iter_frames(dat::AEDATFile, C, period::Integer, out::Channel)
    frame = AEDATEvent{C}[]
    t0 = -1
    while !eof(dat.io)
        raw = read_event(dat)
        if t0 == -1
            t0 = Int(raw.timestamp)
        end
        while (raw.timestamp - t0) >= period
            put!(out, frame)
            frame = AEDATEvent{C}[]
            t0 += Int(period)
        end
        if isevent(C, raw)
            event = convert(AEDATEvent{C}, raw)
            push!(frame, event)
        end
    end
    put!(out, frame)
    close(out)
end


""" Draws a film strip with the supplied frames """
function film_strip(frames::Vector{<:Vector{<:AEDATEvent}})
    imgs = hcat([draw_events(events) for events in frames]...)
end

