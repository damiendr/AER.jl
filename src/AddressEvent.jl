module AddressEvent


""" Event timestamp in us. """
function event_time end

""" Raw event coordinates (x,y). """
function event_coord end

""" Event location (i,j) in standard image coordinates """
function event_location end

""" Event polarity. """
function event_pol end

export event_time, event_coord, event_pol, event_location

function read_events end
function read_events! end

""" Groups `events` into frames of duration `period_us`. """
function iter_frames(f::Function, events, period_us::Integer)
    E = eltype(events)
    frame = E[]
    t0 = -1
    for event in events
        if t0 == -1
            t0 = Int(event_time(event))
        end
        while (event_time(event) - t0) >= period_us
            f(frame)
            frame = E[]
            t0 += Int(period_us)
        end
        push!(frame, event)
    end
    f(frame)
end

function iter_frames(events, period_us::Integer)
    out = Channel{Vector{eltype(events)}}(0)
    @schedule try
        iter_frames(events, period_us) do frame
            put!(out, frame)
        end
    finally
        close(out)
    end
    out
end

function read_frames(events, period_us::Integer)
    frames = Vector{eltype(events)}[]
    iter_frames(events, period_us) do frame
        push!(frames, frame)
    end
    frames
end

export read_events, read_events!, iter_frames, read_frames

""" Standard image size for a particular event type """
function image_size(E)
    error("No default image size for $E")
end

""" Draw events at their location on a 2D canvas """
function draw_events!(events, canvas::Matrix)
    for e in events
        i, j = event_location(e, size(canvas))
        canvas[i,j] += event_pol(e) ? 1 : -1
    end
end

function draw_events(events, imsize)
    canvas = zeros(imsize)
    draw_events!(events, canvas)
    canvas
end

function draw_events(events::Vector{E}) where {E}
    draw_events(events, image_size(E))
end

""" Draws a film strip with the supplied frames """
function film_strip(frames::Vector{<:Vector{<:E}}, imsize=image_size(E)) where {E}
    imgs = hcat([draw_events(events, zeros(imsize)) for events in frames]...)
end

using Images
using StatsBase

""" Turns rasterized events into an image, ignoring hot pixels """
gray_img(img) = Gray.(0.5 .+ img./max(1,2*quantile(img[:],0.99)))

""" Exports events as a video. """
function export_video(filename::String, events, period_us::Number, imsize=image_size(events))
    open(`ffmpeg -f image2pipe -vcodec png -r $(1000000/period_us) -i - -vcodec h264 -pix_fmt yuv420p $filename`, "w") do io
        for frame in iter_frames(events, period_us)
            img = gray_img(draw_events(frame, imsize))
            show(io, MIME("image/png"), img)
        end
    end
end

export image_size, draw_events, draw_events!, film_strip, export_video

include("aer_dat.jl")
include("ros_dvs.jl")

end # module
