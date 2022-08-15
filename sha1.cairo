%builtins output range_check bitwise

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memset import memset
from starkware.cairo.common.bitwise import bitwise_xor, bitwise_and, bitwise_or, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem, assert_le
from starkware.cairo.common.math_cmp import is_le, is_in_range

# extend the sixteen 32-bit words into eighty 32-bit words
func message_schedule_loop{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(w : felt*, i : felt):
    alloc_locals
    if i == 80:
        return ()
    end
    # Note 3: SHA-0 differs by not having this leftrotate.
    let (w_3_xor_8) = bitwise_or([w - 3], [w - 8])
    #assert bitwise_ptr[0].x = [w - 3]
    #assert bitwise_ptr[0].y = [w - 8]
    let (w_14_xor_16) = bitwise_xor([w - 14], [w - 16])
    #assert bitwise_ptr[1].x = [w - 14]
    #assert bitwise_ptr[1].y = [w - 16]
    let (w_3_xor_8_xor_w_14_xor_16) = bitwise_xor(w_3_xor_8, w_14_xor_16)
    #assert bitwise_ptr[2].x = bitwise_ptr[0].x_xor_y
    #assert bitwise_ptr[2].y = bitwise_ptr[1].x_xor_y
    let (rshift_31, _) = unsigned_div_rem(
        w_3_xor_8_xor_w_14_xor_16, # bitwise_ptr[2].x_xor_y
        0x80000000)
    let (_, lshift_1) = unsigned_div_rem(
        2 * w_3_xor_8_xor_w_14_xor_16, # bitwise_ptr[2].x_xor_y
        2 ** 32)
    #let bitwise_ptr = bitwise_ptr + 3
    assert [w + i] = lshift_1 + rshift_31
    
    return message_schedule_loop(w, i + 1)
end

func in_range_00_19{bitwise_ptr : BitwiseBuiltin*}(f : felt*, k : felt*, a : felt, b : felt, c : felt, d : felt, e : felt):
    let (not_b) = bitwise_xor(b, 0xFFFFFFFF)
    #assert bitwise_ptr[0].x = b
    #assert bitwise_ptr[0].y = 0xFFFFFFFF
    let (b_and_c) = bitwise_and(b, c)
    #assert bitwise_ptr[1].x = b
    #assert bitwise_ptr[1].y = c
    let (not_b_and_d) = bitwise_and(not_b, d)
    #assert bitwise_ptr[2].x = not_b # bitwise_ptr[0].x_xor_y
    #assert bitwise_ptr[2].y = d
    let (b_and_c_or_not_b_and_d) = bitwise_or(b_and_c, not_b_and_d)
    #assert bitwise_ptr[3].x = b_and_c # bitwise_ptr[1].x_and_y
    #assert bitwise_ptr[3].y = not_b_and_d # bitwise_ptr[2].x_and_y
    assert [f] = b_and_c_or_not_b_and_d
    assert [k] = 0x5A827999
    return ()
    #assert p = bitwise_ptr + 4
end

func in_range_20_39{bitwise_ptr : BitwiseBuiltin*}(f : felt*, k : felt*, a : felt, b : felt, c : felt, d : felt, e : felt):
    let (b_xor_c) = bitwise_xor(b, c)
    #assert bitwise_ptr[0].x = b
    #assert bitwise_ptr[0].y = c
    let (b_xor_c_xor_d) = bitwise_xor(b_xor_c, d)
    #assert bitwise_ptr[1].x = b_xor_c # bitwise_ptr[0].x_xor_y
    #assert bitwise_ptr[1].y = d
    assert [f] = b_xor_c_xor_d
    assert [k] = 0x6ED9EBA1
    return ()
    #assert p = bitwise_ptr + 2 * BitwiseBuiltin.SIZE
end

func in_range_40_59{bitwise_ptr : BitwiseBuiltin*}(f : felt*, k : felt*, a : felt, b : felt, c : felt, d : felt, e : felt):
    let (b_and_c) = bitwise_and(b, c)
    #assert bitwise_ptr[0].x = b
    #assert bitwise_ptr[0].y = c
    let (b_and_d) = bitwise_and(b, d)
    #assert bitwise_ptr[1].x = b
    #assert bitwise_ptr[1].y = d
    let (c_and_d) = bitwise_and(c, d)
    #assert bitwise_ptr[2].x = c
    #assert bitwise_ptr[2].y = d
    let (b_and_c_or_b_and_d) = bitwise_or(b_and_c, b_and_d)
    #assert bitwise_ptr[3].x = b_and_c # bitwise_ptr[0].x_or_y
    #assert bitwise_ptr[3].y = b_and_d # bitwise_ptr[1].x_or_y
    let (b_and_c_or_b_and_d_or_c_and_d) = bitwise_or(b_and_c_or_b_and_d, c_and_d)
    #assert bitwise_ptr[4].x = b_and_c_or_b_and_d # bitwise_ptr[3].x_or_y
    #assert bitwise_ptr[4].y = c_and_d # bitwise_ptr[2].x_and_y
    assert [f] = b_and_c_or_b_and_d_or_c_and_d
    assert [k] = 0x8F1BBCDC
    return ()
    #assert p = bitwise_ptr + 5
end

func in_range_60_79{bitwise_ptr : BitwiseBuiltin*}(f : felt*, k : felt*, a : felt, b : felt, c : felt, d : felt, e : felt):
        let (b_xor_c) = bitwise_xor(b, c)
        #assert bitwise_ptr[0].x = b
        #assert bitwise_ptr[0].y = c
        let (b_xor_c_xor_d) = bitwise_xor(b_xor_c, d)
        #assert bitwise_ptr[1].x = b_xor_c # bitwise_ptr[0].x_xor_y
        #assert bitwise_ptr[1].y = d
        assert [f] = b_xor_c_xor_d
        assert [k] = 0xCA62C1D6
        return ()
        #assert p = bitwise_ptr + 2
end

func compress_loop{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(
                     w : felt*, a : felt, b : felt, c : felt, d : felt, e : felt, i : felt)
                            -> (a : felt, b : felt, c : felt, d : felt, e : felt):
    alloc_locals
    if i == 80:
        return (a, b, c, d, e)
    end
    
    let (is_in_range_00_19) = is_in_range(i, 00, 20)
    let (is_in_range_20_39) = is_in_range(i, 20, 40)
    let (is_in_range_40_59) = is_in_range(i, 40, 60)
    let (is_in_range_60_79) = is_in_range(i, 60, 80)
    
    #local f : felt
    #local k : felt
    
    #local p : BitwiseBuiltin*
    
    let (f : felt*) = alloc()
    let (k : felt*) = alloc()
    
    #if is_in_range_00_19 == 1:
        in_range_00_19(f + 0, k + 0, a, b, c, d, e)
    #end
    
    #if is_in_range_20_39 == 1:
        in_range_20_39(f + 1, k + 1, a, b, c, d, e)
    #end
    
    #if is_in_range_40_59 == 1:
        in_range_40_59(f + 2, k + 2, a, b, c, d, e)
    #end
    
    #if is_in_range_60_79 == 1:
        in_range_60_79(f + 3, k + 3, a, b, c, d, e)
    #end
    
    let (j, _) = unsigned_div_rem(i, 20)
    
    assert_le(i, 79)
    
    #let bitwise_ptr = p
    
    let (rshift_27, _) = unsigned_div_rem(a, 0x08000000)
    let (_, lshift_5) = unsigned_div_rem(32 * a, 2 ** 32)
    let (rshift_2, _) = unsigned_div_rem(b, 0x00000004)
    let (_, lshift_30) = unsigned_div_rem(2 ** 30 * b, 2 ** 32)
    
    tempvar temp = (lshift_5 + rshift_27) + [f + j] + e + [k + j] + [w + i]
    return compress_loop(w, temp, a, (lshift_30 + rshift_2), c, d, i + 1)
end

func sha1{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(input : felt*, size : felt) -> (hash160 : felt):
    alloc_locals
    let (w) = alloc()
    assert [w + 0] = 0x80000000
    memset(w + 1, 0x00000000, 16 - 1)
    message_schedule_loop(w + 16, 16)
    memset(w + 64, 1, 16)
    let (a, b, c, d, e) = compress_loop(w, 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0, 0)
    return (a * 2**128 + b * 2**96 + c * 2**64 + d * 2**32 + e)
end

func main{output_ptr : felt*, range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
    alloc_locals
    let (input) = alloc()
    let (hash160) = sha1(input, 0)
    serialize_word(hash160) # da39a3ee5e6b4b0d3255bfef95601890afd80709
    return ()
end
