using Test
using Citations

# include("test_bib.jl")

@testset "add citation" begin
    @add_reference("kawczynski2018" => "@article{kawczynski2018characterization,....}")
    @test cite("kawczynski2018") == "@article{kawczynski2018characterization,....}"
end

# @testset "add bib" begin
#     @bibliography("bib_test.bib")
#     @test cite("angenendt") == ""
#     @test cite("bertram") == ""
# end

