struct StaticJaggedVector{T, I <: Integer} <: AbstractVector{T}
    data::Vector{T}
    index::Vector{I}
end
const SJVector = StaticJaggedVector

size(jv::SJVector) = (length(jv.index) - 1,)
eltype(::Type{<:SJVector{T}}) where T = T
eltype(::SJVector{T}) where T = T

@propagate_inbounds function index_range(index::Vector{I}, i::Integer)
    a = index[i]
    b = index[i + one(i)] - one(I)
    return a:b
end

@propagate_inbounds function getindex(jv::SJVector, i::Integer)
    r = index_range(jv.index, i)
    return view(jv.data, r)
end
@propagate_inbounds function getindex(jv::SJVector, i::Integer, j::Integer)
    r = index_range(jv.index, i)
    return jv.data[r[j]]
end

StaticJaggedVector(data::AbstractVector{T}, index::AbstractVector{I}) where {T, I <: Integer} =
    SJVector{T, I}(data, index)
function StaticJaggedVector(jagged::AbstractVector{<:AbstractVector{T}}) where T
    index = fill(1, length(jagged) + 1)
    accumulate!((s, d) -> s + length(d), @view(index[2:end]), jagged)
    length = index[end] - 1
    I = narrowmax(length + 1)
    data = Vector{T}(undef, length)
    for (i, d) in enumerate(jagged)
        r = index_range(index, i)
        data[r] = d
    end
    return SJVector{T, I}(data, index)
end