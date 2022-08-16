%builtins output range_check bitwise

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memset import memset
from starkware.cairo.common.bitwise import bitwise_xor, bitwise_and, bitwise_or, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem

# extend the sixteen 32-bit words into eighty 32-bit words
func message_schedule_loop{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, write_ptr : felt*}(count : felt):
    alloc_locals
    if count == 0:
        return ()
    end
    # Note 3: SHA-0 differs by not having this leftrotate.
    let (w_3_xor_8) = bitwise_or([write_ptr - 3], [write_ptr - 8])
    let (w_14_xor_16) = bitwise_xor([write_ptr - 14], [write_ptr - 16])
    let (w_3_xor_8_xor_w_14_xor_16) = bitwise_xor(w_3_xor_8, w_14_xor_16)
    let (rshift_31, _) = unsigned_div_rem(w_3_xor_8_xor_w_14_xor_16, 0x80000000)
    let (_, lshift_1) = unsigned_div_rem(2 * w_3_xor_8_xor_w_14_xor_16, 2 ** 32)
    #let bitwise_ptr = bitwise_ptr + 3
    assert [write_ptr] = lshift_1 + rshift_31
    let write_ptr = write_ptr + 1
    return message_schedule_loop(count - 1)
end

func rotate_5_30{range_check_ptr}(
    a : felt, b : felt, c : felt, d : felt, e : felt, f : felt, k : felt, w : felt) -> (
    a : felt, b : felt, c : felt, d : felt, e : felt):

    let (rshift_27, _) = unsigned_div_rem(a, 0x08000000)
    let (_, lshift_5) = unsigned_div_rem(32 * a, 2 ** 32)
    let (rshift_2, _) = unsigned_div_rem(b, 0x00000004)
    let (_, lshift_30) = unsigned_div_rem(2 ** 30 * b, 2 ** 32)
    
    return (a = w + lshift_5 + rshift_27 + f + e + k, b = a, c = (lshift_30 + rshift_2), d = c, e = d)
end

func compress_b_and_c_or_not_b_and_d{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, read_ptr : felt*}(
          k : felt, a : felt, b : felt, c : felt, d : felt, e : felt, count : felt)
                -> (a : felt, b : felt, c : felt, d : felt, e : felt):
    alloc_locals
    if count == 0:
        return (a, b, c, d, e)
    end

    let (not_b) = bitwise_xor(b, 0xFFFFFFFF)
    let (b_and_c) = bitwise_and(b, c)
    let (not_b_and_d) = bitwise_and(not_b, d)
    let (f) = bitwise_or(b_and_c, not_b_and_d)
    let (a, b, c, d, e) = rotate_5_30(a = a, b = b, c = c, d = d, e = e, f = f, k = k, w = [read_ptr])
    let read_ptr = read_ptr + 1
    return compress_b_and_c_or_not_b_and_d(k, a, b, c, d, e, count - 1)
end


func compress_b_xor_c_xor_d{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, read_ptr : felt*}(
              k : felt, a : felt, b : felt, c : felt, d : felt, e : felt, count : felt)
                    -> (a : felt, b : felt, c : felt, d : felt, e : felt):
    alloc_locals
    if count == 0:
        return (a, b, c, d, e)
    end

    let (b_xor_c) = bitwise_xor(b, c)
    let (f) = bitwise_xor(b_xor_c, d)
    let (a, b, c, d, e) = rotate_5_30(a = a, b = b, c = c, d = d, e = e, f = f, k = k, w = [read_ptr])
    let read_ptr = read_ptr + 1
    return compress_b_xor_c_xor_d(k, a, b, c, d, e, count - 1)
end

func compress_b_and_c_or_b_and_d_or_c_and_d{range_check_ptr, bitwise_ptr : BitwiseBuiltin*, read_ptr : felt*}(
              k : felt, a : felt, b : felt, c : felt, d : felt, e : felt, count : felt)
                    -> (a : felt, b : felt, c : felt, d : felt, e : felt):
    alloc_locals
    if count == 0:
        return (a, b, c, d, e)
    end

    let (b_and_c) = bitwise_and(b, c)
    let (b_and_d) = bitwise_and(b, d)
    let (c_and_d) = bitwise_and(c, d)
    let (b_and_c_or_b_and_d) = bitwise_or(b_and_c, b_and_d)
    let (f) = bitwise_or(b_and_c_or_b_and_d, c_and_d)
    let (a, b, c, d, e) = rotate_5_30(a = a, b = b, c = c, d = d, e = e, f = f, k = k, w = [read_ptr])
    let read_ptr = read_ptr + 1
    return compress_b_and_c_or_b_and_d_or_c_and_d(k, a, b, c, d, e, count - 1)
end

func fill_chunk{write_ptr : felt*}():
    memset(write_ptr + 0, 0x80000000, 1)
    memset(write_ptr + 1, 0x00000000, 15)
    let write_ptr = write_ptr + 16
    return ()
end

func sha1{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(input : felt*, size : felt) -> (hash160 : felt):
    alloc_locals
    let (write_ptr) = alloc()
    let read_ptr = write_ptr
    fill_chunk{write_ptr = write_ptr}()
    message_schedule_loop{write_ptr = write_ptr}(64)

    let (a, b, c, d, e) = compress_b_and_c_or_not_b_and_d{read_ptr = read_ptr}(
        k = 0x5A827999,
        a = 0x67452301,
        b = 0xEFCDAB89,
        c = 0x98BADCFE,
        d = 0x10325476,
        e = 0xC3D2E1F0, count = 20)

    let (a, b, c, d, e) = compress_b_xor_c_xor_d{read_ptr = read_ptr}(
        k = 0x6ED9EBA1, a = a, b = b, c = c, d = d, e = e, count = 20)

    let (a, b, c, d, e) = compress_b_and_c_or_b_and_d_or_c_and_d{read_ptr = read_ptr}(
        k = 0x8F1BBCDC, a = a, b = b, c = c, d = d, e = e, count = 20)

    let (a, b, c, d, e) = compress_b_xor_c_xor_d{read_ptr = read_ptr}(
        k = 0xCA62C1D6, a = a, b = b, c = c, d = d, e = e, count = 20)

    return (a * 2**128 + b * 2**96 + c * 2**64 + d * 2**32 + e)
end

func main{output_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    let (input) = alloc()
    let (hash160) = sha1(input, 0)
    serialize_word(hash160) # da39a3ee5e6b4b0d3255bfef95601890afd80709
    return ()
end
