# Support for AER-DAT files
# https://inivation.com/support/software/fileformat/

module AERDAT


import AddressEvent.event_time
import AddressEvent.event_coord
import AddressEvent.event_location
import AddressEvent.event_pol

import AddressEvent.read_events
import AddressEvent.read_events!

import AddressEvent.image_size


const HEADER_RE = r"#\!AER\-DAT(\d)\.(\d)\r\n"
const HEADER_BYTES = 14


""" An AER-DAT file version X.Y """
struct AERDATFile{X,Y,I<:IO}
    header::Vector{String}
    io::I
end

""" Opens an AER-DAT file. """
AERDATFile(filename::AbstractString) = AERDATFile(open(filename))

""" Opens a stream as an AER-DAT file. """
function AERDATFile(io::IO)
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
    AERDATFile{X,Y,typeof(io)}(header, io)
end

""" Closes an AER-DAT file. """
Base.close(dat::AERDATFile) = close(dat.io)

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

""" An AER-DAT 1.0 or 2.0 event with an address of class C """
struct Event{C}
    address::C
    timestamp::Int32
end

event_time(e::Event) = e.timestamp
event_coord(e::Event) = event_coord(e.address)
event_location(e::Event, imsize) = event_location(e.address, imsize)
event_pol(e::Event) = event_pol(e.address)

image_size(e::Type{<:Event{C}}) where {C} = image_size(C)

# Convert between event types by converting the address field:
Base.convert(::Type{Event{C}}, event::Event) where {C} =
    Event{C}(convert(C, event.address), event.timestamp)

""" Reads a single raw event from a stream """
function Base.read(io::IO, ::Type{Event{C}}) where {C<:Unsigned}
    a = ntoh(read(io, C))
    t = ntoh(read(io, Int32))
    Event{C}(a, t)
end

""" Returns the raw event type for a given AEDAT file """
raw_event_type(dat::AERDATFile{1}) = Event{UInt16}
raw_event_type(dat::AERDATFile{2}) = Event{UInt32}

""" Checks whether an event can be interpreted as a certain class """
isevent(::Type, e::Event) = false
isevent(::Type{A}, e::Event{B}) where {A,B<:A} = true


include("dvs128.jl")
export DVS128

include("davis240.jl")
export DAVIS240, DAVIS240_DVS, DAVIS240_APS, DAVIS240_IMU




""" Reads a single raw event """
read_event(dat::AERDATFile) = read(dat.io, raw_event_type(dat))

""" Reads a single event as class C """
read_event(dat::AERDATFile, ::Type{C}) where {C} = convert(Event{C}, read_event(dat))

""" Reads the next events of class C, ignoring other event types """
function read_events(dat::AERDATFile, ::Type{C}, maxcount=-1) where {C}
    events = Event{C}[]
    read_events!(dat, events, maxcount)
    events
end

"""
Reads the next events of class C, ignoring other event types, and stores them in `out`.
"""
function read_events!(dat::AERDATFile, out::Vector{Event{C}}, maxcount=-1) where {C}
    iter_events(dat, C, maxcount) do event
        push!(out, event)
    end
end

""" Iterates over events of class C, ignoring other event types """
function iter_events(dat::AERDATFile, ::Type{C}, maxcount=-1) where {C}
    out = Channel{Vector{Event{C}}}(0)
    @schedule try
        iter_events(dat, C, maxcount) do event
            put!(out, frame)
        end
    finally
        close(out)
    end
    out
end

function iter_events(f::Function, dat::AERDATFile, ::Type{C}, maxcount) where {C}
    count = 0
    while !eof(dat.io)
        raw = read_event(dat)
        if isevent(C, raw)
            event = convert(Event{C}, raw)
            f(event)
            count += 1
            if maxcount != -1 && count >= maxcount
                break
            end
        end
    end
end


export AERDATFile


end # module
