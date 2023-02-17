struct File{Mult <: Integer, IAdj <: Integer, IPropN <: Integer, IPropV <: Integer, IItem <: Integer, I <: Integer}
    # existance lookup
    hasadjective::BitVector
    hasproperty::BitVector
    hasitem::BitVector

    # hierachical data
    hierachy::STree{I}

    # per vertex data
    items::Vector{IItem}
    multiplicity::Vector{Mult}

    adjectives::SJVector{I, IAdj}

    propertynames::SJVector{I, IPropN}
    propertyvalues::SJVector{I, IPropV}
end

multiplicitytype(::Type{File{Mult, IAdj, IPropN, IPropV, IItem, I}}) where {Mult, IAdj, IPropN, IPropV, IItem, I} = Mult
adjectivetype(::Type{File{Mult, IAdj, IPropN, IPropV, IItem, I}}) where {Mult, IAdj, IPropN, IPropV, IItem, I} = IAdj
propertynametype(::Type{File{Mult, IAdj, IPropN, IPropV, IItem, I}}) where {Mult, IAdj, IPropN, IPropV, IItem, I} = IPropN
propertyvaluetype(::Type{File{Mult, IAdj, IPropN, IPropV, IItem, I}}) where {Mult, IAdj, IPropN, IPropV, IItem, I} = IPropV
itemtype(::Type{File{Mult, IAdj, IPropN, IPropV, IItem, I}}) where {Mult, IAdj, IPropN, IPropV, IItem, I} = IItem
vertextype(::Type{File{Mult, IAdj, IPropN, IPropV, IItem, I}}) where {Mult, IAdj, IPropN, IPropV, IItem, I} = I

multiplicitytype(::F) where F <: File = multiplicitytype(F)
adjectivetype(::F) where F <: File = adjectivetype(F)
propertynametype(::F) where F <: File = propertynametype(F)
propertyvaluetype(::F) where F <: File = propertyvaluetype(F)
itemtype(::F) where F <: File = itemtype(F)
vertextype(::F) where F <: File = vertextype(F)

hasadjective(f::File, adj::Integer) = f.hasadjective[adj]
hasproperty(f::File, prop::Integer) = f.hasproperty[prop]
hasitem(f::File, item::Integer) = f.hasitem[item]

function countadjective(f::File{Mult}, adj::Integer) where Mult
    result = zero(Mult)
    hasadjective(f, adj) || return result

    for (i, adjs) in enumerate(f.adjectives)
        insorted(adj, adjs) && (result += f.multiplicity[i])
    end

    return result
end
function countproperty(f::File{Mult}, prop::Integer) where Mult
    result = zero(Mult)
    hasproperty(f, prop) || return result

    for (i, props) in enumerate(f.propertynames)
        insorted(prop, props) && (result += f.multiplicity[i])
    end

    return result
end
function countproperty(f::File{Mult}, prop::Integer, val::Integer) where Mult
    result = zero(Mult)
    hasproperty(f, prop) || return result

    for (i, props) in enumerate(f.propertynames)
        j = sortedfindfirst(props, prop)
        !isnothing(j) && @inbounds(props[j]) == val && (result += f.multiplicity[i])
    end

    return result
end
function countitem(f::File{Mult}, item::Integer) where Mult
    result = zero(Mult)
    hasitem(f, item) || return result

    for (i, itm) in enumerate(f.items)
        itm == item && (result += f.multiplicity[i])
    end

    return result
end

function findalladjectives(f::File, adj::Integer)
    I = vertextype(f)
    result = I[]
    hasadjective(f, adj) || return result

    for (i, adjs) in enumerate(f.adjectives)
        insorted(adj, adjs) && push!(result, i)
    end

    return result
end
function findallproperties(f::File, prop::Integer)
    I = vertextype(f)
    result = I[]
    hasproperty(f, prop) || return result

    for (i, props) in enumerate(f.propertynames)
        insorted(prop, props) && push!(result, i)
    end

    return result
end
function findallproperties(f::File, prop::Integer, val::Integer)
    I = vertextype(f)
    result = I[]
    hasproperty(f, prop) || return result

    for (i, props) in enumerate(f.propertynames)
        j = sortedfindfirst(props, prop)
        !isnothing(j) && @inbounds(props[j]) == val && push!(result, i)
    end

    return result
end
function findallitems(f::File, item::Integer)
    I = vertextype(f)
    result = I[]
    hasitem(f, item) || return result

    for (i, itm) in enumerate(f.items)
        itm == item && push!(result, i)
    end

    return result
end

@propagate_inbounds function itempath(f::File, i::Integer)
    I = vertextype(f)
    result = I[]
    
    while !iszero(i)
        pushfirst!(result, i)
        i = parent(f.hierachy, i)
    end

    return result
end

# TODO: build database using PersistantCollections