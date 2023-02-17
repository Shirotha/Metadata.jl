# TODO: add local::Bool that propagates bottom to top (stating at true and staying that way until (including) the first Item with String name is encountered)
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

struct Context{ADJ, PROP, CHILD}
    path::String
    adjectives::ADJ
    properties::PROP
    children::CHILD
    parent::Union{Context, Nothing}
end

Context(path, adjectives, properties, children) = Context(path, adjectives, properties, children, nothing)
Context(context::Context, path, adjectives, properties, children) = Context(
    joinpath(context.path, path),
    CatView(context.adjectives, adjectives),
    MergeView(context.properties, properties),
    CatView(context.children, children),
    context
)
# TODO: replace filter condition with islocal
function Context(root::Item)
    @assert root.name isa String
    @assert root.count == 1
    return Context(root.name, root.adjectives, root.properties, filter(i -> i.name isa Symbol, root.children))
end
function Context(root::Item, context::Context)
    @assert root.name isa String
    @assert root.count == 1
    return Context(context, root.name, root.adjectives, root.properties, filter(i -> i.name isa Symbol, root.children))
end

function Item(item::Item, context::Context)
    @assert item.name isa String
    @assert item.count == 1
    name = joinpath(context.path, item.name)
    adjectives = unique(CatView(context.adjectives, item.adjectives))
    properties = merge(context.properties, item.properties)
    children = vcat(context.children, item.children)
    return Item(name, 1, adjectives, properties, children)
end

# TODO: implement ItemView similar to Context for file Items