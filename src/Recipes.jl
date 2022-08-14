module Recipes

abstract type Recipe end
# See https://github.com/JuliaLang/julia/blob/3fa2d26/base/operators.jl#L1078-L1083 & https://github.com/JuliaGeometry/CoordinateTransformations.jl/blob/ff9ea6e/src/core.jl#L29-L32
struct ComposedRecipe{R1<:Recipe,R2<:Recipe} <: Recipe
    r1::R1
    r2::R2
end

# function build(::Type{Workflow}, r::ComposedRecipe)
#     wf1 = build(Workflow, r.r1)
#     wf2 = build(Workflow, r.r2)
#     return wf1 → wf2
# end

# See https://github.com/JuliaLang/julia/blob/3fa2d26/base/operators.jl#L1088
Base.:∘(r1::Recipe, r2::Recipe) = ComposedRecipe(r1, r2)

# See https://github.com/JuliaGeometry/CoordinateTransformations.jl/blob/ff9ea6e/src/core.jl#L78
Base.inv(r::ComposedRecipe) = inv(r.r2) ∘ inv(r.r1)
Base.inv(r::Recipe) = r

# See https://github.com/JuliaGeometry/CoordinateTransformations.jl/blob/ff9ea6e/src/core.jl#L34
Base.show(io::IO, r::ComposedRecipe) = print(io, '(', r.r1, " ∘ ", r.r2, ')')

end
