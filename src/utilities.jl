"""
Small utilities to get window size from iterables or single number
"""
function to_ntuple(::Val{N}, val::Number) where {N}
    return ntuple(x->val, Val{N}())
end

function to_ntuple(::Val{N}, val::NTuple{N, T}) where {N, T}
    return val
end

function to_ntuple(::Val{N}, val) where {N}
    error("Unsupported paramter format")
end