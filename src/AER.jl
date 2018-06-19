module AER

struct AEDATFile{H,E}
    version_major::Int
    version_minor::Int
    header::H
    events::Vector{E}
end

const HEADER_STR = "#!AER-DAT"



end # module
