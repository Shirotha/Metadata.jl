struct Item
    name::Union{Symbol, String}
    count::Int
    adjectives::Vector{Symbol}
    properties::Dict{Symbol, String}
    children::Vector{Item}
end

==(a::Item, b::Item) =
    a.name == b.name &&
    a.count == b.count &&
    a.adjectives == b.adjectives &&
    a.properties == b.properties &&
    a.children == b.children

function show(io::IO, ::MIME"text/plain", item::Item; indent::Int=0)
    prefix = repeat(' ', indent)
    print(io, prefix)
    if item.count != 1
        print(io, item.count, ' ')
    end
    if item.name isa Symbol
        print(io, item.name)
    else
        print(io, '[', item.name, ']')
    end
    if isempty(item.adjectives)
        println(io)
    else
        println(io, " (", join(item.adjectives, ", "), ')')
    end

    for (name, value) in item.properties
        println(io, prefix, "  ", name, ": ", value)
    end
    for child in item.children
        show(io, MIME"text/plain"(), child; indent = indent + 2)
    end
end