/**
 * Native ColdFusion QR Code
 * Based on the ZXing code from Google.
 *    http://code.google.com/p/zxing/
 * Licensed under the Apache 2.0 license:
 *    http://www.apache.org/licenses/LICENSE-2.0
 * @author    Rick Osborne
 */
component {

	// For efficiency, start out with some room to work.
	this.DEFAULT_SIZE_IN_BYTES = 32;

	public any function init() {
		variables.sizeInBits = 0;
		variables.array = [];
		variables.xff = inputBaseN("FF", 16);
		variables.x7 = inputBaseN("7", 16);
		arraySet(variables.array, 1, this.DEFAULT_SIZE_IN_BYTES, 0);
		return this;
	} // init

	// Return the bit value at "index".
	public numeric function at(required numeric index) {
		if ((arguments.index lt 0) or (arguments.index gte variables.sizeInBits)) {
			throw "Bad index: #index#";
		}
		local.value = bitAnd(variables.array[bitShrn(index, 3) + 1], variables.xff);
		return bitAnd(bitShrn(local.value, (7 - bitAnd(arguments.index, variables.x7))), 1);
	}

	// Return the number of bits in the bit vector.
	public numeric function size() {
		return variables.sizeInBits;
	}

	// Return the number of bytes in the bit vector.
	public numeric function sizeInBytes() {
		return bitShrn(variables.sizeInBits + 7, 3);
	}

	// Append one bit to the bit vector.
	public void function appendBit(required numeric bit) {
		if (not ((arguments.bit eq 0) or (arguments.bit eq 1))) {
			throw "Bad bit";
		}
		local.numBitsInLastByte = bitAnd(sizeInBits, variables.x7);
		// We'll expand array if we don't have bits in the last byte.
		if (local.numBitsInLastByte eq 0) {
			appendByte(0);
			variables.sizeInBits -= 8;
		}
		// Modify the last byte.
		variables.array[bitShrn(variables.sizeInBits, 3) + 1] = bitOr(variables.array[bitShrn(sizeInBits, 3) + 1], bitShln(arguments.bit, (7 - local.numBitsInLastByte)));
		variables.sizeInBits++;
	}

	// Append "numBits" bits in "value" to the bit vector.
	// REQUIRES: 0<= numBits lte 32.
	//
	// Examples:
	// - appendBits(0x00, 1) adds 0.
	// - appendBits(0x00, 4) adds 0000.
	// - appendBits(0xff, 8) adds 11111111.
	public void function appendBits(required numeric value, required numeric numBits) {
		if ((arguments.numBits lt 0) or (arguments.numBits gt 32)) {
			throw "Num bits must be between 0 and 32";
		}
		local.numBitsLeft = arguments.numBits;
		while (local.numBitsLeft gt 0) {
			// Optimization for byte-oriented appending.
			if ((bitAnd(variables.sizeInBits, variables.x7) eq 0) and (local.numBitsLeft gte 8)) {
				local.newByte = bitAnd(bitShrn(arguments.value, local.numBitsLeft - 8), variables.xff);
				appendByte(local.newByte);
				local.numBitsLeft -= 8;
			} else {
				local.bit = bitAnd(bitShrn(arguments.value, local.numBitsLeft - 1), 1);
				appendBit(local.bit);
				local.numBitsLeft--;
			}
		}
	}

	// Append "bits".
	public void function appendBitVector(required BitVector bits) {
		local.size = arguments.bits.size();
		for (local.i = 0; local.i lt local.size; local.i++) {
			appendBit(arguments.bits.at(local.i));
		}
	}

	// Modify the bit vector by XOR'ing with "other"
	public void function xxor(required BitVector other) {
		if (sizeInBits neq other.size()) {
			throw "BitVector sizes don't match";
		}
		local.sizeInBytes = bitShrn(sizeInBits + 7, 3);
		for (local.i = 1; i lte sizeInBytes; ++i) {
		// The last byte could be incomplete (i.e. not have 8 bits in
		// it) but there is no problem since 0 XOR 0 eq 0.
			variables.array[i] = bitXor(variables.array[i], arguments.other.array[i]);
		}
	}

	// Return String like "01110111" for debugging.
	public string function toString() {
		local.result = "";
		for (local.i = 0; i lt sizeInBits; ++i) {
			if (at(i) eq 0) {
				result.Append('0');
			} else if (at(i) eq 1) {
				result.Append('1');
			} else {
				throw "Byte isn't 0 or 1";
			}
		}
		return result.ToString();
	}

	// Callers should not assume that array.length is the exact number of bytes needed to hold
	// sizeInBits - it will typically be larger for efficiency.
	public array function getArray() {
		return array;
	}

	// Add a new byte to the end, possibly reallocating and doubling the size of the array if we've
	// run out of room.
	private void function appendByte(required numeric value) {
		array[bitShrn(sizeInBits, 3) + 1] = value;
		sizeInBits += 8;
	}

	public void function makeByteArray() {
		for (local.i = 1; i lte arrayLen(array); i++) {
			if (array[i] gt 127) {
				array[i] -= 256;
			}
		}
	}


}