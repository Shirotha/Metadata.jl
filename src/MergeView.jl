struct MergeView{KEY, VALUE, N, T} <: AbstractDict{KEY, VALUE}
    dict::T
end

@generated function MergeView(dict::T) <: Tuple
    N = length(T.parameters)
    @assert N > 0
    DICT = eltype(T)
    @assert DICT <: AbstractDict
    PAIR = eltype(DICT)
    KEY, VALUE = PAIR.parameters
    return quote
        return MergeView{$KEY, $VALUE, $N, $T}(dict)
    end
end
MergeView(dict::AbstractDict...) = MergeView(tuple(dict...))

eltype(::Type{<:MergeView{KEY, VALUE}}) where {KEY, VALUE} = Pair{KEY, VALUE}
eltype(::T) where T <: MergeView = eltype(T)

length(mv::MergeView) = sum(length.(mv))

haskey(mv::MergeView, key) = any(Fix2(haskey, key), mv.dict)

function getindex(mv::MergeView, key)
    for d in reverse(mv.dict)
        haskey(d, key) && return d[key]
    end
    throw(KeyError(key))
end

function iterate(mv::MergeView{KEY, VALUE, N}) where {KEY, VALUE, N}
    n = 1
    iter = iterate(mv.dict[n])
    while isnothing(iter)
        n += 1
        n > N && return nothing

        iter = iterate(mv.dict[n])
    end

    return iter[1], (n, iter[2])
end
function iterate(mv::MergeView{KEY, VALUE, N}, (n, s)::Tuple{Int, Int}) where {KEY, VALUE, N}
    1 <= n <= N || return nothing

    iter = iterate(mv.dict[n], s)
    while isnothing(iter)
        n += 1
        n > N && return nothing

        iter = iterate(mv.dict[n])
    end

    return iter[1], (n, iter[2])
end

# TODO: implement merge