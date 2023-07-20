module Config

using Configurations: OptionField
using Unitful: Unitful, FreeUnits, Quantity, uparse, dimension, lookup_units
using UnitfulAtomic

import Configurations: from_dict

export Subdirectory, InputFile, OutputFile, list_io

using Configurations: @option
using Formatting: sprintf1

abstract type AbstractConfig end

    base::String = ""
@option struct InputFile
    extension::String = "in"
end

    base::String = ""
@option struct OutputFile
    extension::String = "out"
end

@option struct Subdirectory
    root::String = pwd()
    pattern::String = "%s"
end

@option struct IO
    subdir::Subdirectory = Subdirectory()
    in::InputFile = InputFile()
    out::OutputFile = OutputFile()
end

function list_io(io::IO, name)
    path = joinpath(io.subdir.root, sprintf1(io.subdir.pattern, name))
    in, out = join((io.in.base, io.in.extension), '.'),
    join((io.out.base, io.out.extension), '.')
    return joinpath(path, in) => joinpath(path, out)
end

abstract type SamplingPoints end

function from_dict(
    ::Type{<:SamplingPoints},
    ::OptionField{:numbers},
    ::Type{Vector{Float64}},
    str::AbstractString,
)
    return eval(Meta.parse(str))
end
function from_dict(
    ::Type{<:SamplingPoints}, ::OptionField{:unit}, ::Type{<:FreeUnits}, str::AbstractString
)
    return _uparse(str)
end

# Similar to https://github.com/JuliaCollections/IterTools.jl/blob/0ecaa88/src/IterTools.jl#L1028-L1032
function Base.iterate(iter::SamplingPoints, state=1)
    if state > length(iter.numbers)
        return nothing
    else
        return getindex(iter.numbers, state) * iter.unit, state + 1
    end
end

Base.eltype(iter::SamplingPoints) = Quantity{Float64,dimension(iter.unit),typeof(iter.unit)}

Base.length(iter::SamplingPoints) = length(iter.numbers)

Base.size(iter::SamplingPoints) = size(iter.numbers)

_uparse(str::AbstractString) =
    lookup_units([Unitful, UnitfulAtomic], Meta.parse(filter(!isspace, str)))

end
