# from nose.tools import *
# from bibpy import *
# import glob
using Test
using Citations
using Glob



function test_parsing()
    for example in glob("*.bib")
        parse_bib(example)
    end
end

function parse_bib(f)
    contents = readlines(open(f, "r"))
    data = clear_comments(contents)
    bib = Parser(data)
#     # bib.parse()
#     # data = bib.json()
end


test_parsing()
