using AER
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

# AEDAT 1.0
v1_data = [0x7f, 0x22, 0x01, 0x39, 0xa4, 0xd0]

## Test reading bytes (correct byte order etc):
evt = read(IOBuffer(v1_data), AEDATEvent{UInt16})
@assert evt == AEDATEvent{UInt16}(0x7f22, 20554960)

## Determine file version:
dat = AEDATFile(IOBuffer(v1_data))
@assert isa(dat, AEDATFile{1,0})

## Test parsing an event:
dat = AEDATFile(IOBuffer(v1_data))
evt = read_event(dat)
@assert AER.isevent(DVS128, evt)

evt2 = convert(AEDATEvent{DVS128}, evt)
@assert evt2 == AEDATEvent{DVS128}(DVS128(false, 17, 127, false), 20554960)

dat = AEDATFile(IOBuffer(v1_data))
evt3 = read_event(dat, DVS128)
@assert evt2 == evt3


# AEDAT 2.0
v2_data = [0xa9, 0xcc, 0xe2, 0x00, 0x10, 0x21, 0x07, 0xb2]
v2_header = "#!AER-DAT2.0\r\n# Foo\r\n"

## Test reading bytes (correct byte order etc):
evt = read(IOBuffer(v2_data), AEDATEvent{UInt32})
@assert evt == AEDATEvent{UInt32}(0xa9cce200, 270600114)

## Test reading file version and header:
function v2_io()
    io = IOBuffer()
    print(io, v2_header)
    write(io, v2_data)
    seekstart(io)
    io
end
dat = AEDATFile(v2_io())
@assert isa(dat, AEDATFile{2,0}) dat
@assert dat.header == [" Foo\r\n"]

## Test default event types:
mark(dat.io)
evt1 = read_event(dat)
reset(dat.io)
mark(dat.io)
evt2 = read_event(dat, UInt32)
@assert evt1 == evt2

## Test parsing an event:
@assert AER.isevent(DAVIS240_APS, evt1)
reset(dat.io)
mark(dat.io)
evt = read_event(dat, DAVIS240_APS)
@assert evt == AEDATEvent{DAVIS240_APS}(DAVIS240_APS(167, 206, 0, 512), 270600114)
