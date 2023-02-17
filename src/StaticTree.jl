struct StaticTree{I <: Integer}
    children::SJVector{I, I}
    parents::Vector{I}
end
const STree = StaticTree

children(st::StaticTree, v::Integer) = st.children[v]
parent(st::StaticTree, v::Integer) = st.parent[v]

function StaticTree(parents::Vector{I}) where I
    n = maximum(parents)
    @assert all(i -> 0 <= i <= n, parents)
    @assert count(iszero, parents) == 1

    adj = [I[] for _ in 1:n]
    for (i, p) in enumerate(parents)
        push!(adj[p], i)
    end

    return STree{I}(SJVector(adj), parents)
end