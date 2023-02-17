lb(x::T) where T <: Unsigned = 8sizeof(T) - leading_zeros(x)
lb(x) = lb(unsigned(x))
nextbitssize(bits::Integer) = max(nextpow2(bits), 8)
nextunsignedtype(bits::Integer) = eval(Symbol(:UInt, nextbitssize(bits)))
function narrowmax(i::Integer)
    @assert i >= 0
    return nextunsignedtype(lb(i))
end

function sortedfindfirst(a::AbstractArray, x, o::Ordering=Forward)
    i = searchsortedfirst(a, x, o)
    i > lastindex(a) && return nothing
    i == firstindex(a) && lt(o, x, a[i]) && return nothing
    return i 
end
sortedfindfirst(a::AbstractVector, x, default, o::Ordering=Forward; by=identity, lt=isless, rev::Bool=false) =
    sortedfindfirst(a, x, default, ord(lt, by, rev, o))