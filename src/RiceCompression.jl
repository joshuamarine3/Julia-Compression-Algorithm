# module RiceCompression

# export rice_encode, rice_decode

# function encode_unary(quotient::Int)
#     # Unary encoding for the quotient
#     unary = fill(true, quotient)  # Create a vector of `true` of length quotient
#     return vcat(unary, false)      # Append a `false` to signify the end of unary encoding
# end

# function encode_binary(remainder::Int, k::Int)
#     # Binary encoding for the remainder
#     binary = Bool[]
#     for i in k-1:-1:0
#         push!(binary, isone((remainder >> i) & 1))
#     end
#     return binary
# end

# function rice_encode(data::Vector{Int}, k::Int)
#     # Ensure k is a positive integer
#     if k <= 0
#         throw(ArgumentError("k must be a positive integer"))
#     end

#     # Calculate the Rice parameter
#     rice_param = 2^k

#     # Initialize the encoded array
#     encoded = Bool[]

#     for value in data
#         quotient = div(value, rice_param)
#         remainder = value % rice_param

#         # Append unary and binary encodings to the encoded array
#         append!(encoded, encode_unary(quotient))
#         append!(encoded, encode_binary(remainder, k))
#     end

#     return encoded
# end

# function decode_unary(encoded::Vector{Bool}, start::Int)
#     i = start

#     # Decode unary part
#     quotient = 0
#     while i <= length(encoded) && encoded[i]
#         quotient += 1
#         i += 1
#     end

#     if i > length(encoded) || encoded[i] != false
#         throw(ArgumentError("Invalid unary encoding"))
#     end

#     # Move to the next part (after the unary terminator)
#     i += 1

#     return quotient, i
# end

# function decode_binary(encoded::Vector{Bool}, start::Int, k::Int)
#     remainder = 0
#     for j in 0:k-1
#         if start + j > length(encoded)
#             throw(ArgumentError("Invalid binary encoding"))
#         end
#         remainder = (remainder << 1) | (encoded[start + j] ? 1 : 0)
#     end

#     return remainder, start + k
# end

# function rice_decode(encoded::Vector{Bool}, k::Int)
#     # Ensure k is a positive integer
#     if k <= 0
#         throw(ArgumentError("k must be a positive integer"))
#     end

#     # Calculate the Rice parameter
#     rice_param = 2^k

#     # Initialize the decoded array
#     decoded = Int[]

#     i = 1
#     while i <= length(encoded)
#         # Decode unary part
#         quotient, next_pos = decode_unary(encoded, i)

#         # Decode binary part
#         remainder, next_pos = decode_binary(encoded, next_pos, k)

#         # Calculate the original value
#         value = quotient * rice_param + remainder
#         push!(decoded, value)

#         i = next_pos
#     end

#     return decoded
# end

# end  # module

# Source for Rice Algorithm: https://michaeldipperstein.github.io/rice.html

module RiceCompression

export rice_encode, rice_decode

"""
    encode_unary(quotient::Int)::Vector{Bool}

Encodes the quotient using unary coding: `quotient` 1s followed by a 0.
"""
function encode_unary(quotient::Int)::BitVector
    return BitVector(vcat(fill(true, quotient), false))
end

"""
    encode_binary(remainder::Int, k::Int)::Vector{Bool}

Encodes the remainder using k bits in binary (MSB first).
"""
function encode_binary(remainder::Int, k::Int)::BitVector
    bits = BitVector()
    for i in k-1:-1:0
        push!(bits, (remainder >> i) & 1 == 1)
    end
    return bits
end

"""
    rice_encode(data::Vector{Int}, k::Int)::BitVector

Encodes an array of integers using Rice coding with parameter k.
Returns a BitVector to optimize space usage.
"""
function rice_encode(data::Vector{Int}, k::Int)::BitVector
    encoded = BitVector()  # Initialize an empty BitVector
    divisor = 1 << k  # 2^k

    for x in data
        quotient = x ÷ divisor
        remainder = x % divisor

        append!(encoded, encode_unary(quotient))
        append!(encoded, encode_binary(remainder, k))
    end

    return encoded  # Explicitly convert to BitVector
end

"""
    decode_unary(encoded::BitVector, pos::Int)::Tuple{Int, Int}

Decodes the unary-coded quotient starting at `pos`.
Returns the quotient and the updated position.
"""
function decode_unary(encoded::BitVector, pos::Int)::Tuple{Int, Int}
    quotient = 0
    while pos <= length(encoded) && encoded[pos]
        quotient += 1
        pos += 1
    end
    return quotient, pos + 1  # Skip the terminating 0
end

"""
    decode_binary(encoded::BitVector, pos::Int, k::Int)::Tuple{Int, Int}

Decodes a k-bit binary remainder starting at `pos`.
Returns the remainder and the updated position.
"""
function decode_binary(encoded::BitVector, pos::Int, k::Int)::Tuple{Int, Int}
    remainder = 0
    for _ in 1:k
        remainder = (remainder << 1) | (encoded[pos] ? 1 : 0)
        pos += 1
    end
    return remainder, pos
end

"""
    rice_decode(encoded::BitVector, k::Int)::Vector{Int}

Decodes a Rice-coded bit stream into its original integer array.
"""
function rice_decode(encoded::BitVector, k::Int)::Vector{Int}
    decoded = Int[]
    divisor = 1 << k  # 2^k
    pos = 1

    while pos <= length(encoded)
        quotient, pos = decode_unary(encoded, pos)
        remainder, pos = decode_binary(encoded, pos, k)
        push!(decoded, quotient * divisor + remainder)
    end

    return decoded
end

end  # module



# Testing the implementation
using ..RiceCompression

# Test array
data = Int[10, 20, 30, 40]
k = 3

# Encoding
compressed = RiceCompression.rice_encode(data, k)

# Decoding
decoded = RiceCompression.rice_decode(compressed, k)

println("Original Data: ", data)
println("Size of original data (bytes): ", summarysize(data))
println("Compressed Data: ", compressed)
println("Size of compressed data (bytes): ", summarysize(compressed))
println("Decoded Data: ", decoded)
println("Size of decoded data (bytes): ", summarysize(decoded))
println("Match: ", data == decoded)