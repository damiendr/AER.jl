module AER


include("aedat.jl")
export AEDATFile, AEDATEvent, read_event, read_events, read_frames, iter_frames

include("dvs128.jl")
export DVS128, draw_events, film_strip, spike_locs

include("davis240.jl")
export DAVIS240, DAVIS240_DVS, DAVIS240_APS, DAVIS240_IMU

end # module
