using Test

include("../src/Metadata.jl")
using .Metadata
import .Metadata: Item

@testset verbose=true "Metadata" begin

    include("parser.jl")

end