# include <cstdint> // uint32_t
# include <cstring> // strlen
# include <cassert> // assert

struct uint160_t {
	uint32_t word[5];
};

uint160_t sha1(const char *c_str) {
	uint32_t h[5] {
		0x67452301,
		0xEFCDAB89,
		0x98BADCFE,
		0x10325476,
		0xC3D2E1F0
	};
	uint32_t w[80] { };
	uint32_t len = strlen(c_str);
	for(int idx=0; idx<len; ++idx)
	reinterpret_cast<uint8_t *>(w)[idx / 4 << 2 | 3 - idx % 4] = c_str[idx];
	reinterpret_cast<uint8_t *>(w)[len / 4 << 2 | 3 - len % 4] = 0x80;
	reinterpret_cast<uint32_t *>(w)[15] = len << 3;
	{
		// Message schedule: extend the sixteen 32-bit words into eighty 32-bit words:
		for(int i=16; i<80; ++i) {
			// Note 3: SHA-0 differs by not having this leftrotate.
			uint32_t w_3_8_14_16 = w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16];
			w[i] = w_3_8_14_16 << 1 | w_3_8_14_16 >> 31;
		}

		// Initialize hash value for this chunk:
		uint32_t a = h[0];
		uint32_t b = h[1];
		uint32_t c = h[2];
		uint32_t d = h[3];
		uint32_t e = h[4];

		// Main loop:[10][56]
		for(int i=0; i<80; ++i) {
			uint32_t f;
			uint32_t k;
			if(0 <= i && i <= 19) {
				f = (b & c) | ((~ b) & d);
				k = 0x5A827999;
			}
			else if(20 <= i && i <= 39) {
				f = b ^ c ^ d;
				k = 0x6ED9EBA1;
			}
			else if(40 <= i && i <= 59) {
				f = (b & c) | (b & d) | (c & d); 
				k = 0x8F1BBCDC;
			}
			else if(60 <= i && i <= 79) {
				f = b ^ c ^ d;
				k = 0xCA62C1D6;
			}

			uint32_t temp = (a << 5 | a >> 27) + f + e + k + w[i];
			e = d;
			d = c;
			c = b << 30 | b >> 2;
			b = a;
			a = temp;
		}

		// Add this chunk's hash to result so far:
		h[0] += a;
		h[1] += b; 
		h[2] += c;
		h[3] += d;
		h[4] += e;
	}
	return {h[4], h[3], h[2], h[1], h[0]}; // big 32-bit endian
}

int main(void) {

	// 0x -> da39a3ee5e6b4b0d3255bfef95601890afd80709
	{
		uint160_t h = sha1("");
		assert(h.word[0] == 0xafd80709);
		assert(h.word[1] == 0x95601890);
		assert(h.word[2] == 0x3255bfef);
		assert(h.word[3] == 0x5e6b4b0d);
		assert(h.word[4] == 0xda39a3ee);
	}

	// 0x01 -> bf8b4530d8d246dd74ac53a13471bba17941dff7
	{
		uint160_t h = sha1("\x01");
		assert(h.word[0] == 0x7941dff7);
		assert(h.word[1] == 0x3471bba1);
		assert(h.word[2] == 0x74ac53a1);
		assert(h.word[3] == 0xd8d246dd);
		assert(h.word[4] == 0xbf8b4530);
	}

	// 0x01234567 -> 8cd28fc05e2ac7727d38f47d23300634dc376b3d
	{
		uint160_t h = sha1("\x01\x23\x45\x67");
		assert(h.word[0] == 0xdc376b3d);
		assert(h.word[1] == 0x23300634);
		assert(h.word[2] == 0x7d38f47d);
		assert(h.word[3] == 0x5e2ac772);
		assert(h.word[4] == 0x8cd28fc0);
	}

	// "The quick brown fox jumps over the lazy dog" -> 2fd4e1c67a2d28fced849ee1bb76e7391b93eb12
	{
		uint160_t h = sha1("The quick brown fox jumps over the lazy dog");
		assert(h.word[0] == 0x1b93eb12);
		assert(h.word[1] == 0xbb76e739);
		assert(h.word[2] == 0xed849ee1);
		assert(h.word[3] == 0x7a2d28fc);
		assert(h.word[4] == 0x2fd4e1c6);
	}

	return 0;
}