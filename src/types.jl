#### References

abstract type AbstractReference end

Base.@kwdef struct Article <: AbstractReference
    hyphenation
    author
    title
    shorttitle
    journaltitle
    volume
    date
    pages
    annotation
    indextitle
    number
end

Base.@kwdef struct Book <: AbstractReference
    keywords
    hyphenation
    author
    editor
    title
    publisher
    location
    date
    series
    annotation
    sorttitle
    commentator
    annotator
    translator
    indextitle
    shorttitle
    volumes
end

