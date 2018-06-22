# AddressEvent

[![Build Status](https://travis-ci.org/damiendr/AddressEvent.jl.svg?branch=master)](https://travis-ci.org/damiendr/AddressEvent.jl) [![codecov.io](http://codecov.io/github/damiendr/AddressEvent.jl/coverage.svg?branch=master)](http://codecov.io/github/damiendr/AddressEvent.jl?branch=master)

An unofficial Julia library to read files produced by event-based sensors like the DVS128 and DAVIS240 cameras:
- AER-DAT files (1.0 and 2.0): https://inivation.com/support/software/fileformat/
- DVS events stored in ROS bags: https://github.com/uzh-rpg/rpg_dvs_ros

## Example

Read DVS128 events from an AER-DAT file:
```julia
using AddressEvent.AERDAT
events = open("recorded.aerdat") do io
    dat = AERDAT(io)
    read_events(dat, DVS128)
end
imsize = image_size(DVS128)
```

Read only the DVS events from a DAVIS240 recording:
```julia
read_events(dat, DAVIS240_DVS)
```

Extract DVS events from a ROS bag:
```julia
using AddressEvent.ROSDVS
events = open("recorded.bag") do io
    imsize = (0,0)
    events = DVSEvent[]
    sub = Subscription("/davis/right/events") do io
        imsize = read_events!(io, events)
    end
    bag = Bag(io)
    read_topics(bag, sub)
    events, imsize
end
```

Group events into 50 ms frames:
```julia
for frame in iter_frames(events, 50000)
    ...
end
```

Draw some events as a single frame:
```julia
    draw_events(events[1:20000], imsize);
```

Draw events as a film strip ([dataset](https://sourceforge.net/p/jaer/wiki/AER%20data/)):
```julia
using Images
gray(img) = Gray.(0.5 .+ img./max(1,2maximum(abs.(extrema(img)))))
frames = iter_frames(events, 50*1000)
film = film_strip(collect(take(frames, 7)))
display(gray(film))
```
![](film.png)

Export an MP4 video (50 ms frames):
```julia
export_video("video.mp4", events, 50000, imsize)
```
