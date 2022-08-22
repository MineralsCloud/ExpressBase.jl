module Config

using EasyConfig: Config
using JSON: JSON
using TOML: TOML
using ValSplit: @valsplit
using YAML: YAML

export load, save, of_format, format

struct DataFormat{T} end

struct File{D<:DataFormat,N}
    filename::N
end
File{F}(file::File{F}) where {F<:DataFormat} = file
File{F}(file::AbstractString) where {F<:DataFormat} = File{F,String}(String(file))
File{F}(file) where {F<:DataFormat} = File{F,typeof(file)}(file)

struct UnsupportedExtensionError <: Exception
    ext::String
end

format(::Val{:json}) = DataFormat{:JSON}()
format(::Union{Val{:yaml},Val{:yml}}) = DataFormat{:YAML}()
format(::Val{:toml}) = DataFormat{:TOML}()
@valsplit format(Val(ext::Symbol)) = throw(UnsupportedExtensionError(string(ext)))

"""
    save(file, data)

Save `data` to `file`.

By now, `YAML`, `JSON`, and `TOML` formats are supported. The format is recognized by `file` extension.

If `data` is a `Dict`, its keys should be `String`s so that `load` can return the same `data`.

!!! warning
    Allowed `data` types can be referenced in [`JSON.jl` documentation](https://github.com/JuliaIO/JSON.jl/blob/master/README.md)
    and [`YAML.jl` documentation](https://github.com/JuliaData/YAML.jl/blob/master/README.md).
    For `TOML` format, only `AbstractDict` type is allowed.
"""
function save(file, data)
    path, ext = expanduser(file), extension(file)
    save(File{format(ext)}(path), data)
    return nothing
end
function save(file::File{DataFormat{:JSON}}, data)
    open(file, "w") do io
        JSON.print(io, data)
    end
end
function save(file::File{DataFormat{:TOML}}, data)
    open(file, "w") do io
        TOML.print(io, data)
    end
end
function save(file::File{DataFormat{:YAML}}, data)
    open(file, "w") do io
        YAML.write(io, data, "")
    end
end

"""
    load(file)

Load data from `file` to a `Dict`.

By now, `YAML`, `JSON`, and `TOML` formats are supported. The format is recognized by `file` extension.
"""
function load(file)
    path = filepath(file)
    ext = extension(path)
    return load(File{format(ext)}(path))
end
# load(file, ::Type{Config}) = Config(load(file))
load(path::File{DataFormat{:JSON}}) = JSON.parsefile(path)
function load(path::File{DataFormat{:TOML}})
    open(path, "r") do io
        return TOML.parse(io)
    end
end
function load(path::File{DataFormat{:YAML}})
    open(path, "r") do io
        dict = YAML.load(io)
        return JSON.parse(JSON.json(dict))  # To keep up with JSON & TOML results
    end
end

"""
    of_format(destination, source)

Convert `source` to the format of `destination`. Similar to `oftype`.
"""
function of_format(destination, source)
    data = load(source)
    return save(destination, data)
end

function Base.show(io::IO, error::UnsupportedExtensionError)
    return print(io, "unsupported extension `.", error.ext, "`!")
end

end