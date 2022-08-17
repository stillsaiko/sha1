%builtins range_check bitwise

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.memset import memset
from starkware.cairo.common.bitwise import bitwise_xor, bitwise_and, bitwise_or, BitwiseBuiltin
from starkware.cairo.common.math import unsigned_div_rem

func sha1{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}(input : felt*, size : felt) -> (hash160 : felt):
	alloc_locals
	let (w) = alloc()
	# fill_chunk
	memset(w + 0, 0x80000000, 1)
	memset(w + 1, 0x00000000, 15)
	let w = w + 16

	# extend the sixteen 32-bit words into eighty 32-bit words
	tempvar range_check_ptr = range_check_ptr
	tempvar bitwise_ptr = bitwise_ptr
	tempvar w = w
	tempvar count = 64
	message_schedule:
		# Note 3: SHA-0 differs by not having this leftrotate.
		assert bitwise_ptr[0].x = [w - 3]
		assert bitwise_ptr[0].y = [w - 8]
		assert bitwise_ptr[1].x = [w - 14]
		assert bitwise_ptr[1].y = [w - 16]
		assert bitwise_ptr[2].x = bitwise_ptr[0].x_xor_y
		assert bitwise_ptr[2].y = bitwise_ptr[1].x_xor_y
		# W <<< 1
		let (rshift_31, _) = unsigned_div_rem(bitwise_ptr[2].x_or_y, 0x80000000)
		assert bitwise_ptr[3].x = 2 * bitwise_ptr[2].x_xor_y + rshift_31
		assert bitwise_ptr[3].y = 0xFFFFFFFF
		assert [w] = bitwise_ptr[3].x_and_y
		tempvar range_check_ptr = range_check_ptr
		tempvar bitwise_ptr = bitwise_ptr + 4 * BitwiseBuiltin.SIZE
		tempvar w = w + 1
		tempvar count = count - 1
	jmp message_schedule if count != 0

	let w = w - 80

	# f = (b and c) or ((not b) and d)
	# k = 0x5A827999
	tempvar e = 0xC3D2E1F0
	tempvar d = 0x10325476
	tempvar c = 0x98BADCFE
	tempvar b = 0xEFCDAB89
	tempvar a = 0x67452301
	tempvar range_check_ptr = range_check_ptr
	tempvar bitwise_ptr = bitwise_ptr
	tempvar w = w
	tempvar count = 20
	compress_b_and_c_or_not_b_and_d:
		let k = 0x5A827999
		# A <<< 5
		let (rshift_27, _) = unsigned_div_rem(a, 2 ** 27)
		# B <<< 30
		let (rshift_2, _) = unsigned_div_rem(b, 2 ** 2)
		# B & C | ~B & D
		assert bitwise_ptr[0].x = b
		assert bitwise_ptr[0].y = 0xFFFFFFFF
		assert bitwise_ptr[1].x = b
		assert bitwise_ptr[1].y = c
		assert bitwise_ptr[2].x = bitwise_ptr[0].x_xor_y
		assert bitwise_ptr[2].y = d
		assert bitwise_ptr[3].x = bitwise_ptr[1].x_and_y
		assert bitwise_ptr[3].y = bitwise_ptr[2].x_and_y
		let f = bitwise_ptr[3].x_or_y
		assert bitwise_ptr[4].x = (a * 2 ** 5 + rshift_27) + f + e + 0x5A827999 + [w]
		assert bitwise_ptr[4].y = 0xFFFFFFFF
		assert bitwise_ptr[5].x = b * 2 ** 30 + rshift_2
		assert bitwise_ptr[5].y = 0xFFFFFFFF
		# f = (b & c) | ((~ b) & d)
		# temp = (a << 5 | a >> 27) + f + e + k + w[i]
		let temp = bitwise_ptr[4].x_and_y
		# (a, b, c, d, e) <- (temp, a, (b << 30 | b >> 2), c, d)
		tempvar e = d
		tempvar d = c
		tempvar c = bitwise_ptr[5].x_and_y
		tempvar b = a
		tempvar a = temp
		tempvar range_check_ptr = range_check_ptr
		tempvar bitwise_ptr = bitwise_ptr + 6 * BitwiseBuiltin.SIZE
		tempvar w = w + 1
		tempvar count = count - 1
	jmp compress_b_and_c_or_not_b_and_d if count != 0

	# f = b xor c xor d
	# k = 0x6ED9EBA1
	tempvar e = e
	tempvar d = d
	tempvar c = c
	tempvar b = b
	tempvar a = a
	tempvar range_check_ptr = range_check_ptr
	tempvar bitwise_ptr = bitwise_ptr
	tempvar w = w
	tempvar count = 20
	compress_b_xor_c_xor_d_6ed9eba1:
		# A <<< 5
		let (rshift_27, _) = unsigned_div_rem(a, 0x08000000)
		# B <<< 30
		let (rshift_2, _) = unsigned_div_rem(b, 0x00000004)
		# B ^ C ^ D
		assert bitwise_ptr[0].x = b
		assert bitwise_ptr[0].y = c
		assert bitwise_ptr[1].x = bitwise_ptr[0].x_xor_y
		assert bitwise_ptr[1].y = d
		assert bitwise_ptr[2].x = 0x6ED9EBA1 + [w] + (2 ** 5 * a + rshift_27) + bitwise_ptr[1].x_xor_y + e
		assert bitwise_ptr[2].y = 0xFFFFFFFF
		assert bitwise_ptr[3].x = 2 ** 30 * b + rshift_2
		assert bitwise_ptr[3].y = 0xFFFFFFFF
		tempvar e = d
		tempvar d = c
		tempvar c = bitwise_ptr[3].x_and_y
		tempvar b = a
		tempvar a = bitwise_ptr[2].x_and_y
		tempvar range_check_ptr = range_check_ptr
		tempvar bitwise_ptr = bitwise_ptr + 4 * BitwiseBuiltin.SIZE
		tempvar w = w + 1
		tempvar count = count - 1
	jmp compress_b_xor_c_xor_d_6ed9eba1 if count != 0

	# f = (b and c) or (b and d) or (c and d) 
	# k = 0x8F1BBCDC
	tempvar e = e
	tempvar d = d
	tempvar c = c
	tempvar b = b
	tempvar a = a
	tempvar range_check_ptr = range_check_ptr
	tempvar bitwise_ptr = bitwise_ptr
	tempvar w = w
	tempvar count = 20
	compress_b_and_c_or_b_and_d_or_c_and_d:
		# A <<< 5
		let (rshift_27, _) = unsigned_div_rem(a, 0x08000000)
		# B <<< 30
		let (rshift_2, _) = unsigned_div_rem(b, 0x00000004)
		# B & C | B & D | C & D
		assert bitwise_ptr[0].x = b
		assert bitwise_ptr[0].y = c
		assert bitwise_ptr[1].x = b
		assert bitwise_ptr[1].y = d
		assert bitwise_ptr[2].x = c
		assert bitwise_ptr[2].y = d
		assert bitwise_ptr[3].x = bitwise_ptr[0].x_and_y
		assert bitwise_ptr[3].y = bitwise_ptr[1].x_and_y
		assert bitwise_ptr[4].x = bitwise_ptr[2].x_and_y
		assert bitwise_ptr[4].y = bitwise_ptr[3].x_or_y
		assert bitwise_ptr[5].x = 0x8F1BBCDC + [w] + (2 ** 5 * a + rshift_27) + bitwise_ptr[4].x_or_y + e
		assert bitwise_ptr[5].y = 0xFFFFFFFF
		assert bitwise_ptr[6].x = 2 ** 30 * b + rshift_2
		assert bitwise_ptr[6].y = 0xFFFFFFFF
		tempvar e = d
		tempvar d = c
		tempvar c = bitwise_ptr[6].x_and_y
		tempvar b = a
		tempvar a = bitwise_ptr[5].x_and_y
		tempvar range_check_ptr = range_check_ptr
		tempvar bitwise_ptr = bitwise_ptr + 7 * BitwiseBuiltin.SIZE
		tempvar w = w + 1
		tempvar count = count - 1
	jmp compress_b_and_c_or_b_and_d_or_c_and_d if count != 0

	# f = b xor c xor d
	# k = 0xCA62C1D6
	tempvar e = e
	tempvar d = d
	tempvar c = c
	tempvar b = b
	tempvar a = a
	tempvar range_check_ptr = range_check_ptr
	tempvar bitwise_ptr = bitwise_ptr
	tempvar w = w
	tempvar count = 20
	compress_b_xor_c_xor_d_ca62c1d6:
		# A <<< 5
		let (rshift_27, _) = unsigned_div_rem(a, 0x08000000)
		# B <<< 30
		let (rshift_2, _) = unsigned_div_rem(b, 0x00000004)
		# B ^ C ^ D
		assert bitwise_ptr[0].x = b
		assert bitwise_ptr[0].y = c
		assert bitwise_ptr[1].x = bitwise_ptr[0].x_xor_y
		assert bitwise_ptr[1].y = d
		assert bitwise_ptr[2].x = 0xCA62C1D6 + [w] + (2 ** 5 * a + rshift_27) + bitwise_ptr[1].x_xor_y + e
		assert bitwise_ptr[2].y = 0xFFFFFFFF
		assert bitwise_ptr[3].x = 2 ** 30 * b + rshift_2
		assert bitwise_ptr[3].y = 0xFFFFFFFF
		tempvar e = d
		tempvar d = c
		tempvar c = bitwise_ptr[3].x_and_y
		tempvar b = a
		tempvar a = bitwise_ptr[2].x_and_y
		tempvar range_check_ptr = range_check_ptr
		tempvar bitwise_ptr = bitwise_ptr + 4 * BitwiseBuiltin.SIZE
		tempvar w = w + 1
		tempvar count = count - 1
	jmp compress_b_xor_c_xor_d_ca62c1d6 if count != 0

	assert bitwise_ptr[0].x = 0x67452301 + a
	assert bitwise_ptr[0].y = 0xFFFFFFFF
	assert bitwise_ptr[1].x = 0xEFCDAB89 + b
	assert bitwise_ptr[1].y = 0xFFFFFFFF
	assert bitwise_ptr[2].x = 0x98BADCFE + c
	assert bitwise_ptr[2].y = 0xFFFFFFFF
	assert bitwise_ptr[3].x = 0x10325476 + d
	assert bitwise_ptr[3].y = 0xFFFFFFFF
	assert bitwise_ptr[4].x = 0xC3D2E1F0 + e
	assert bitwise_ptr[4].y = 0xFFFFFFFF

	let bitwise_ptr = bitwise_ptr + 5*BitwiseBuiltin.SIZE

	return (bitwise_ptr[-5].x_and_y * 2**128 +
			bitwise_ptr[-4].x_and_y * 2**96 +
			bitwise_ptr[-3].x_and_y * 2**64 +
			bitwise_ptr[-2].x_and_y * 2**32 +
			bitwise_ptr[-1].x_and_y)
end

func main{range_check_ptr, bitwise_ptr : BitwiseBuiltin*}():
	alloc_locals
	let (input) = alloc() # zero
	let (hash160) = sha1(input, 0)
	# test static explicit
	assert hash160 = 0xda39a3ee5e6b4b0d3255bfef95601890afd80709
	# test dynamic implicit
	%{
		import hashlib
		assert ids.hash160 == int(hashlib.sha1(b"").hexdigest(), 16)
	%}
	return ()
end