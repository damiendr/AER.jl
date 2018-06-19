# AER

[![Build Status](https://travis-ci.org/damiendr/AER.jl.svg?branch=master)](https://travis-ci.org/damiendr/AER.jl) [![codecov.io](http://codecov.io/github/damiendr/AER.jl/coverage.svg?branch=master)](http://codecov.io/github/damiendr/AER.jl?branch=master)

A Julia library to read AER DAT files (1.0 and 2.0): https://inivation.com/support/software/fileformat/

## Example

Open an AERDAT file for reading:
```julia
using AER
dat = AEDATFile("recorded.dat")
```

Read DVS128 events:
```julia
read_events(dat, DVS128)
```

Read only the DVS events from a DAVIS240 recording:
```julia
read_events(dat, DAVIS240_DVS)
```

Group events into 50 ms frames:
```julia
for frame in iter_frames(dat, DAVIS240_DVS, 50000)
    ...
end
```

Draw events a film strip:
```julia
using Images
gray(img) = Gray.(0.5 .+ img./max(1,2max(abs.(extrema(img))...)))
frames = iter_frames(dat, DVS128, 50.0*1000)
film = film_strip(collect(take(frames, 7)))
display(gray(film))
```
![](film.png)
