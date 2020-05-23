function sum_shift(t, shift, size)
    return sum(((t.I .- size .÷ 2) .* shift)./size)
 end

function fft_translate(a::AbstractArray{T, N}, shifts) where {T, N}
    return fft_translate(fft(a), shifts)
end

"Translate using discrete fourier transform"
function fft_translate(a::AbstractArray{T, N}, shifts) where {N, T <: Complex }
    shift_mat = T.(fftshift(exp.( -im*2π .* sum_shift.(CartesianIndices(a), Ref(.-shifts), Ref(size(a))))));
    return abs.(ifft(a.*shift_mat))
end


function translate(a::AbstractArray{T, N}, shifts::NTuple{N, Integer}) where {N, T}
    translated = Array{Union{Missing, T}}(missing, size(a))
    # TODO write translation with indexing
end

function translate(a::AbstractArray{T, N}, shifts::NTuple{N, Real}) where {N, T}
    return fft_translate(a, shifts)
end

# function fft_translate(a::CuArray{T, N}, shifts) where {N, T <: Complex }
#     shift_mat = fftshift(exp.( -im*2π .* cu(Complex{Float32}.(sum_shift.(CartesianIndices(a), Ref(-shifts), Ref(size(a)))))));
#     return abs.(ifft(a.*shift_mat))
# end