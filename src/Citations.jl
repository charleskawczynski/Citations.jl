module Citations

# include("bib.jl")

export @add_reference
export @bibliography
export cite

include("types.jl")

global_reference_list = Dict()

macro add_reference(references...)
    for ref in references
        r = eval(ref)
        global_reference_list[r.first] = r.second
    end
end

function parse_bib(bib_contents)
    # s = convert.(Ref(String), split(bib_contents, "\n"))
    # return s
    bib_contents
end

macro bibliography(bib_file)
    contents = readlines(bib_file)
    contents = join(contents, "\n")
    @show typeof(contents)
    citation_list = parse_bib(contents)
    @show typeof(citation_list)
    @show citation_list
    for (k,v) in citation_list
        global_reference_list[k] = v
    end
    return nothing
end

"""
    cite(ref)

Cite reference in `global_reference_list`
"""
cite(ref) = global_reference_list[ref]

# function __init__()
#     println("Hello!")
#     refs = []
#     @add_reference(refs...)
# end

end # module
