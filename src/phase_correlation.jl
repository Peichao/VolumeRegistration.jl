function normalize(x::Complex{T}) where {T}
    return x / (abs(x) + eps(T))
end

"""
Gaussian filter in the fourier domain
(a Gaussian in the fourier domain is again a gaussian with inverse variance)

"""
function gaussian_fft_filter(shape::NTuple{N,Integer}, σ::Union{T,NTuple{N,T}}) where {N,T}
    σ2 = (to_ntuple(Val{N}(), σ) .^ 2) .* 2
    kernels = [exp.(-(((1:s) .- s / 2) .^ 2) ./ σs) for (s, σs) in zip(shape, σ2)]
    gauss_filt = ([prod(k) for k in Iterators.product(kernels...)])
    gauss_filt ./= sum(gauss_filt)
    return T.(abs.(fft(ifftshift(gauss_filt))))
end

function prepare_fft_reference(target_img::AbstractArray{T,N}, σ_ref) where {T,N}
    output = Complex{T}.(target_img)
    prepare_fft_reference!(output, σ_ref)
    return output
end

function prepare_fft_reference!(
    target_img::AbstractArray{T,N},
    σ_ref::Union{Real,NTuple{N,T2}},
) where {T,N,T2}
    fft!(target_img)
    return target_img .=
        normalize.(conj.(target_img)) .* gaussian_fft_filter(size(target_img), σ_ref)
end

function prepare_fft_reference!(target_img, σ_ref::Nothing)
    fft!(target_img)
    return target_img .= normalize.(conj.(target_img))
end

function phase_correlation(
    src_img::AbstractArray{T,N},
    target_img::AbstractArray{T,N};
    σ_ref::Union{Nothing,Real} = T(1.15),
) where {T<:Real,N}
    return phase_correlation(fft(src_img), prepare_fft_reference(target_img, σ_ref))
end

function phase_correlation(
    src_img::AbstractArray{T,N},
    target_img::AbstractArray{T2,N},
) where {T<:Real,T2<:Complex,N}
    return phase_correlation(fft(src_img), target_img)
end

function phase_correlation(
    src_freq::AbstractArray{T,N},
    target_freq::AbstractArray{T,N},
) where {T<:Complex{T2},N} where {T2}
    src_freq .= normalize.(src_freq) .* target_freq
    ifft!(src_freq)
    return src_freq
end

"""
Takes the data corresponding to the real part of the corners of the 
phase correlation array of interest for shift finding

$(SIGNATURES)

# Arugments


"""
function extract_low_frequencies(
    data::AbstractArray{Complex{T},N},
    corner_size::NTuple{N,Integer},
    interpolate_middle = false,
) where {T,N}
    corner = Array{T}(undef, corner_size)
    mid_val = corner_size .÷ 2
    data_size = size(data)

    for idx in CartesianIndices(corner_size)
        idx_original =
            (
                (x, mid, full) -> (x > mid) ? (x - mid) : full - mid + x
            ).(idx.I, mid_val, data_size)
        corner[idx] = real(data[idx_original...])
    end

    # if interpolating the middle, average the values in the cross-shaped area around it
    if interpolate_middle
        corner[(mid_val .+ 1)...] =
            mean(
                corner[(mid_val .+ 1 .+ ntuple(i -> i_dim == i ? 1 : 0, Val{N}()))...] +
                corner[(mid_val .+ 1 .+ ntuple(i -> i_dim == i ? -1 : 0, Val{N}()))...]
                for i_dim = 1:N
            ) / 2
    end

    return corner
end

function phase_correlation_shift(pc, window_size; interpolate_middle = false)
    window_mid = window_size .÷ 2 .+ 1
    lf = extract_low_frequencies(pc, window_size, interpolate_middle)
    max_loc = argmax(lf)
    return max_loc.I .- window_mid, lf[max_loc]
end

function phase_correlation_shift(pc, window_size, us; interpolate_middle = false)
    window_size = min.(size(pc), window_size)
    lf = extract_low_frequencies(pc, window_size, interpolate_middle)
    return shift_around_maximum(us, lf)
end

function shift_around_maximum(us, lf)
    window_mid = size(lf) .÷ 2 .+ 1
    os_mid = us.original_size .÷ 2
    max_loc =
        argmax(lf[CartesianIndex(os_mid .+ 1):CartesianIndex(size(lf) .- os_mid)]).I .+
        os_mid
    ups_shift = upsampled_shift(
        us,
        lf[CartesianIndex(max_loc .- os_mid):CartesianIndex(max_loc .+ os_mid)],
    )
    return ups_shift .+ max_loc .- window_mid, lf[max_loc...]
end
