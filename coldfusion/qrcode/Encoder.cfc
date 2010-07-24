/**
 * Native ColdFusion QR Code Encoder
 * Based on the ZXing code from Google.
 *    http://code.google.com/p/zxing/
 * Licensed under the Apache 2.0 license:
 *    http://www.apache.org/licenses/LICENSE-2.0
 * @author	satorux@google.com (Satoru Takabayashi) - creator
 * @author	dswitkin@google.com (Daniel Switkin) - ported from C++
 * @author	Rick Osborne
 */
component {

	this.ALPHANUMERIC_TABLE = [
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  // 0x00-0x0f
		-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,  // 0x10-0x1f
		36, -1, -1, -1, 37, 38, -1, -1, -1, -1, 39, 40, -1, 41, 42, 43,  // 0x20-0x2f
		0,   1,  2,  3,  4,  5,  6,  7,  8,  9, 44, -1, -1, -1, -1, -1,  // 0x30-0x3f
		-1, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24,  // 0x40-0x4f
		25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, -1, -1, -1, -1, -1   // 0x50-0x5f
	];
	this.DEFAULT_BYTE_MODE_ENCODING = "ISO-8859-1";

	/**
	 * @hint The mask penalty calculation is complicated.  See Table 21 of JISX0510:2004 (p.45) for details. Basically it applies four rules and summate all penalties.
	 */
	public numeric function calculateMaskPenalty (required ByteMatrix matrix) {
		local.penalty = 0;
		local.penalty += MaskUtil.applyMaskPenaltyRule1(matrix);
		local.penalty += MaskUtil.applyMaskPenaltyRule2(matrix);
		local.penalty += MaskUtil.applyMaskPenaltyRule3(matrix);
		local.penalty += MaskUtil.applyMaskPenaltyRule4(matrix);
		return local.penalty;
	}  // calculateMaskPenalty

	/**
	 * Encode "bytes" with the error correction level "ecLevel". The encoding mode will be chosen
	 * internally by chooseMode(). On success, store the result in "qrCode".
	 *
	 * We recommend you to use QRCode.EC_LEVEL_L (the lowest level) for
	 * "getECLevel" since our primary use is to show QR code on desktop screens. We don't need very
	 * strong error correction for this purpose.
	 *
	 * Note that there is no way to encode bytes in MODE_KANJI. We might want to add EncodeWithMode()
	 * with which clients can specify the encoding mode. For now, we don't need the functionality.
	 */
	public void function encode (required string content, required string ecLevel, required QRCode qrCode, struct hints = structNew()) {
		local.encoding = structKeyExists(arguments.hints, "CHARACTER_SET") ? arguments.hints["CHARACTER_SET"] : "DEFAULT_BYTE_MODE_ENCODING";
		// Step 1: Choose the mode (encoding).
		local.mode = chooseMode(arguments.content, local.encoding);
		// // Step 2: Append "bytes" into "dataBits" in appropriate encoding.
		local.dataBits = new BitVector();
		appendBytes(arguments.content, local.mode, local.dataBits, local.encoding);
		// Step 3: Initialize QR code that can contain "dataBits".
		local.numInputBytes = local.dataBits.sizeInBytes();
		initQRCode(local.numInputBytes, arguments.ecLevel, local.mode, arguments.qrCode);
		// Step 4: Build another bit vector that contains header and data.
		local.headerAndDataBits = new BitVector();
		// Step 4.5: Append ECI message if applicable
		if ((local.mode eq "BYTE") and (local.encoding neq "DEFAULT_BYTE_MODE_ENCODING")) {
			local.eci = new CharacterSetECI().getCharacterSetECIByName(local.encoding);
			if (local.eci neq "") {
				appendECI(local.eci, local.headerAndDataBits);
			}
		}
		appendModeInfo(local.mode, local.headerAndDataBits);
		local.numLetters = (local.mode eq "BYTE") ? local.dataBits.sizeInBytes() : arguments.content.length;
		appendLengthInfo(local.numLetters, arguments.qrCode.getVersion(), local.mode, local.headerAndDataBits);
		local.headerAndDataBits.appendBitVector(local.dataBits);
		local.headerAndDataBits.makeByteArray();// make byte array
		// Step 5: Terminate the bits properly.
		terminateBits(arguments.qrCode.getNumDataBytes(), local.headerAndDataBits);
		// Step 6: Interleave data bits with error correction code.
		local.finalBits = new BitVector();
		interleaveWithECBytes(local.headerAndDataBits, arguments.qrCode.getNumTotalBytes(), arguments.qrCode.getNumDataBytes(), arguments.qrCode.getNumRSBlocks(), local.finalBits);
		local.finalBits.makeByteArray();// make byte array
		// Step 7: Choose the mask pattern and set to "qrCode".
		local.matrix = new ByteMatrix(arguments.qrCode.getMatrixWidth(), arguments.qrCode.getMatrixWidth());
		//finalBits
		local.ec = arguments.qrCode.getECLevel();
		local.v = arguments.qrCode.getVersion();
		//matrix
		local.maskpattern = chooseMaskPattern(local.finalBits, arguments.qrCode.getECLevel(), arguments.qrCode.getVersion(), local.matrix);
		arguments.qrCode.setMaskPattern(maskpattern);
		// Step 8.  Build the matrix and set it to "qrCode".
		new MatrixUtil().buildMatrix(local.finalBits, arguments.qrCode.getECLevel(), arguments.qrCode.getVersion(), arguments.qrCode.getMaskPattern(), local.matrix);
		arguments.qrCode.setMatrix(matrix);
		// Step 9.  Make sure we have a valid QR Code.
		if (not arguments.qrCode.isValid()) {
		  throw ("Invalid QR code: " & arguments.qrCode.toString());
		}

	} // encode

	/**
	 * @return the code point of the table used in alphanumeric mode or -1 if there is no corresponding code in the table.
	 */
	public numeric function getAlphanumericCode(required numeric code) {
		if (arguments.code lt arrayLen(this.ALPHANUMERIC_TABLE)) {
			return this.ALPHANUMERIC_TABLE[arguments.code + 1];
		}
		return -1;
	}

	/**
	* @hint Choose the best mode by examining the content. Note that 'encoding' is used as a hint; if it is Shift_JIS then we assume the input is Kanji and return KANJI.
	*/
	public string function chooseMode(required string content, string encoding = "") {
		if (arguments.encoding eq "Shift_JIS") {
			return Mode.KANJI;
		}
		local.hasNumeric = false;
		local.hasAlphanumeric = false;
		for (local.i = 1; local.i lte content.length; local.i++) {
			local.c = arguments.content.charAt(i);
			if(isNumeric(local.c)) {
				local.hasNumeric = true;
			} else if (getAlphanumericCode(local.c.charAt(0)) neq -1) {
				local.hasAlphanumeric = true;
			} else {
				return "BYTE";
			}
		} // for i
		if (local.hasAlphanumeric) {
			return "ALPHANUMERIC";
		} else if (local.hasNumeric) {
			return "NUMERIC";
		}
		return "BYTE";
	}

  	private numeric function chooseMaskPattern(required BitVector bits, required string ecLevel, required numeric version, required ByteMatrix matrix) {
		local.minPenalty = javaCast("int", 0).MAX_VALUE;  // Lower penalty is better.
		local.bestMaskPattern = -1;
		local.numMaskPatterns = new QRCode().NUM_MASK_PATTERNS;
		local.matrixUtil = new MatrixUtil();
		// We try all mask patterns to choose the best one.
		for (local.maskPattern = 0; maskPattern lt local.numMaskPatterns; local.maskPattern++) {
			local.matrixUtil.buildMatrix(arguments.bits, arguments.ecLevel, arguments.version, arguments.maskPattern, arguments.matrix);
			local.penalty = calculateMaskPenalty(arguments.matrix);
			if (local.penalty lt local.minPenalty) {
				local.minPenalty = local.penalty;
				local.bestMaskPattern = local.maskPattern;
			}
		} // for maskPattern
		return local.bestMaskPattern;
	}

	/**
	* @hint Initialize "qrCode" according to "numInputBytes", "ecLevel", and "mode". On success, modify "qrCode".
	*/
	private void function initQRCode (required numeric numInputBytes, required string ecLevel, required string mode, required QRCode qrCode) {
		arguments.qrCode.setECLevel(arguments.ecLevel);
		arguments.qrCode.setMode(arguments.mode);
		local.decoderVersion = new Version();

		// In the following comments, we use numbers of Version 7-H.
		for (local.versionNum = 1; local.versionNum lte 40; local.versionNum++) {
			local.version = local.decoderVersion.getVersionForNumber(local.versionNum);
			// numBytes = 196
			local.numBytes = local.version.getTotalCodewords();
			// getNumECBytes = 130
			local.ecBlocks = local.version.getECBlocksForLevel(local.ecLevel);
			local.numEcBytes = local.ecBlocks.getTotalECCodewords();
			// getNumRSBlocks = 5
			local.numRSBlocks = local.ecBlocks.getNumBlocks();
			// getNumDataBytes = 196 - 130 = 66
			local.numDataBytes = local.numBytes - local.numEcBytes;
			// We want to choose the smallest version which can contain data of "numInputBytes" + some
			// extra bits for the header (mode info and length info). The header can be three bytes
			// (precisely 4 + 16 bits) at most. Hence we do +3 here.
			if (local.numDataBytes gte arguments.numInputBytes + 3) {
				// Yay, we found the proper rs block info!
				local.qrCode.setVersion(local.versionNum);
				local.qrCode.setNumTotalBytes(local.numBytes);
				local.qrCode.setNumDataBytes(local.numDataBytes);
				local.qrCode.setNumRSBlocks(local.numRSBlocks);
				// getNumECBytes = 196 - 66 = 130
				local.qrCode.setNumECBytes(local.numEcBytes);
				// matrix width = 21 + 6 * 4 = 45
				local.qrCode.setMatrixWidth(local.version.getDimensionForVersion());
				return;
			}
		}
		throw "Cannot find proper rs block info (input data too big?)";
	}

	/**
	 * @hint Terminate bits as described in 8.4.8 and 8.4.9 of JISX0510:2004 (p.24).
	 */
	public void function terminateBits(required numeric numDataBytes, required BitVector bits) {
		local.capacity = arguments.numDataBytes * 8;
		if (arguments.bits.size() gt local.capacity) {
			throw "data bits cannot fit in the QR Code: #arguments.bits.size()# gt #local.capacity#";
		}
		// Append termination bits. See 8.4.8 of JISX0510:2004 (p.24) for details.
		// TODO: srowen says we can remove this for loop, since the 4 terminator bits are optional if
		// the last byte has less than 4 bits left. So it amounts to padding the last byte with zeroes
		// either way.
		for (local.i = 0; (local.i lt 4) and (arguments.bits.size() lt local.capacity); local.i++) {
			arguments.bits.appendBit(0);
		} // for i
		local.numBitsInLastByte = arguments.bits.size() mod 8;
		// If the last byte isn't 8-bit aligned, we'll add padding bits.
		if (local.numBitsInLastByte gt 0) {
			local.numPaddingBits = 8 - local.numBitsInLastByte;
			for (local.i = 0; local.i lt local.numPaddingBits; local.i++) {
				arguments.bits.appendBit(0);
			}
		}
		// Should be 8-bit aligned here.
		if ((arguments.bits.size() mod 8) neq 0) {
			throw "Number of bits is not a multiple of 8";
		}
		// If we have more space, we'll fill the space with padding patterns defined in 8.4.9 (p.24).
		local.numPaddingBytes = local.numDataBytes - arguments.bits.sizeInBytes();
		for (local.i = 0; local.i lt local.numPaddingBytes; local.i++) {
			if ((local.i mod 2) eq 0) {
				arguments.bits.appendBits(236, 8);
			} else {
				arguments.bits.appendBits(17, 8);
			}
		}
		if (arguments.bits.size() neq local.capacity) {
			throw "Bits size does not equal capacity";
		}
	}

	/**
	* @hint Get number of data bytes and number of error correction bytes for block id "blockID". Store the result in "numDataBytesInBlock", and "numECBytesInBlock". See table 12 in 8.5.1 of JISX0510:2004 (p.30)
	*/
	public void function getNumDataBytesAndNumECBytesForBlockID(required numeric numTotalBytes, required numeric numDataBytes, required numeric numRSBlocks, required numeric blockID, required array numDataBytesInBlock, required array numECBytesInBlock) {
		if (arguments.blockID gte arguments.numRSBlocks) {
			throw "Block ID too large";
		}
		// numRsBlocksInGroup2 = 196 mod 5 = 1
		local.numRsBlocksInGroup2 = arguments.numTotalBytes mod arguments.numRSBlocks;
		// numRsBlocksInGroup1 = 5 - 1 = 4
		local.numRsBlocksInGroup1 = arguments.numRSBlocks - local.numRsBlocksInGroup2;
		// numTotalBytesInGroup1 = 196 / 5 = 39
		local.numTotalBytesInGroup1 = arguments.numTotalBytes / arguments.numRSBlocks;
		// numTotalBytesInGroup2 = 39 + 1 = 40
		local.numTotalBytesInGroup2 = local.numTotalBytesInGroup1 + 1;
		// numDataBytesInGroup1 = 66 / 5 = 13
		local.numDataBytesInGroup1 = arguments.numDataBytes / arguments.numRSBlocks;
		// numDataBytesInGroup2 = 13 + 1 = 14
		local.numDataBytesInGroup2 = local.numDataBytesInGroup1 + 1;
		// numEcBytesInGroup1 = 39 - 13 = 26
		local.numEcBytesInGroup1 = local.numTotalBytesInGroup1 - local.numDataBytesInGroup1;
		// numEcBytesInGroup2 = 40 - 14 = 26
		local.numEcBytesInGroup2 = local.numTotalBytesInGroup2 - local.numDataBytesInGroup2;
		// Sanity checks.
		// 26 = 26
		if (local.numEcBytesInGroup1 neq local.numEcBytesInGroup2) {
			throw "EC bytes mismatch";
		}
		// 5 = 4 + 1.
		if (arguments.numRSBlocks neq (local.numRsBlocksInGroup1 + local.numRsBlocksInGroup2)) {
			throw "RS blocks mismatch";
		}
		// 196 = (13 + 26) * 4 + (14 + 26) * 1
		if (arguments.numTotalBytes neq ((local.numDataBytesInGroup1 + local.numEcBytesInGroup1) * local.numRsBlocksInGroup1) + ((local.numDataBytesInGroup2 + local.numEcBytesInGroup2) * local.numRsBlocksInGroup2)) {
			throw "Total bytes mismatch";
		}

		if (arguments.blockID lt local.numRsBlocksInGroup1) {
			arguments.numDataBytesInBlock[1] = local.numDataBytesInGroup1;
			arguments.numECBytesInBlock[1] = local.numEcBytesInGroup1;
		} else {
			arguments.numDataBytesInBlock[1] = local.numDataBytesInGroup2;
			arguments.numECBytesInBlock[1] = local.numEcBytesInGroup2;
		}
	}

	/**
	* @hint Interleave "bits" with corresponding error correction bytes. On success, store the result in "result". The interleave rule is complicated. See 8.6 of JISX0510:2004 (p.37) for details.
	*/
	public static function interleaveWithECBytes(required BitVector bits, required numeric numTotalBytes, required numeric numDataBytes, required numeric numRSBlocks, required BitVector result) {

		// "bits" must have "getNumDataBytes" bytes of data.
		if (arguments.bits.sizeInBytes() neq arguments.numDataBytes) {
			throw "Number of bits and data bytes does not match";
		}

		// Step 1.  Divide data bytes into blocks and generate error correction bytes for them. We'll
		// store the divided data bytes blocks and error correction bytes blocks into "blocks".
		local.dataBytesOffset = 0;
		local.maxNumDataBytes = 0;
		local.maxNumEcBytes = 0;

		// Since, we know the number of reedsolmon blocks, we can initialize the vector with the number.
		//local.blocks:ArrayList = new ArrayList(numRSBlocks);
		local.blocks = [];

		for (local.i4 = 0; local.i4 lt numRSBlocks; local.i4++) {
			local.numDataBytesInBlock = [ 0 ];
			local.numEcBytesInBlock = [ 0 ];
			getNumDataBytesAndNumECBytesForBlockID( arguments.numTotalBytes, arguments.numDataBytes, arguments.numRSBlocks, local.i4, local.numDataBytesInBlock, local.numEcBytesInBlock);
			local.dataBytes2 = new zxingByteArray();
			local.dataBytes2._set(bits.getArray(), local.dataBytesOffset, local.numDataBytesInBlock[1]);
			local.ecBytes2 = generateECBytes(local.dataBytes2, local.numEcBytesInBlock[1]);
			local.blocks.addElement(new BlockPair(local.dataBytes2, local.ecBytes2));
			local.maxNumDataBytes = max(local.maxNumDataBytes, local.dataBytes2.size());
			local.maxNumEcBytes = max(local.maxNumEcBytes, local.ecBytes2.size());
			local.dataBytesOffset += local.numDataBytesInBlock[1];
		}

		if (arguments.numDataBytes neq local.dataBytesOffset) {
			throw "Data bytes does not match offset";
		}


		// First, place data blocks.
		for (local.i2 = 1; local.i2 lte local.maxNumDataBytes; local.i2++) {
			for (local.j2 = 1; local.j2 lte local.blocks.size(); local.j2++) {
				local.dataBytes = local.blocks.elementAt(local.j2).getDataBytes();
				if (local.i2 lte local.dataBytes.size()) {
					arguments.result.appendBits(local.dataBytes.at(i2), 8);
				}
			}
		}
		// Then, place error correction blocks.
		for (local.i = 1; i lte maxNumEcBytes; local.i++) {
			for (local.j = 1; j lte blocks.size(); local.j++) {
				local.ecBytes = local.blocks.elementAt(local.j).getErrorCorrectionBytes();
				if (local.i lte local.ecBytes.size()) {
					arguments.result.appendBits(local.ecBytes.at(i), 8);
				}
			}
		}
		if (numTotalBytes neq result.sizeInBytes()) {  // Should be same.
			throw "Interleaving error: #numTotalBytes# and #arguments.result.sizeInBytes()# differ.";
		}
	}

	public zxingByteArray function generateECBytes(required zxingByteArray dataBytes, required numeric numEcBytesInBlock) {
		local.numDataBytes = arguments.dataBytes.size();
		local.toEncode = [];
		arraySet(local.toEncode, 1, numDataBytes + numEcBytesInBlock);
		for (local.i = 1; local.i lte local.numDataBytes; local.i++) {
			local.toEncode[local.i] = arguments.dataBytes.at(local.i);
		}
		new ReedSolomonEncoder("QR_CODE_FIELD").encode(local.toEncode, arguments.numEcBytesInBlock);

		local.ecBytes = new zxingByteArray(arguments.numEcBytesInBlock);
		for (local.i4 = 1; local.i4 lte numEcBytesInBlock; local.i4++) {
			local.ecBytes.setByte(local.i4, local.toEncode[local.numDataBytes + local.i4]);
		}
		return local.ecBytes;
	}

	/**
	* @hint Append mode info. On success, store the result in "bits".
	*/
	public void function appendModeInfo(required Mode mode, required BitVector bits) {
		arguments.bits.appendBits(arguments.mode.getBits(), 4);
	}


	/**
	* @hint Append length info. On success, store the result in "bits".
	*/
	public void function appendLengthInfo(required numeric numLetters, required numeric version, required Mode mode, required BitVector bits) {
		local.numBits = arguments.mode.getCharacterCountBits(new DecoderVersion().getVersionForNumber(arguments.version));
		local.maxLetters = (bitShln(1, numBits) - 1);
		if (arguments.numLetters gt local.maxLetters) {
			throw "#numLetters# is bigger than #maxLetters#";
		}
		arguments.bits.appendBits(arguments.numLetters, local.numBits);
	}

	/**
	* @hint Append "bytes" in "mode" mode (encoding) into "bits". On success, store the result in "bits".
	*/
	public void function appendBytes(required string content, required string mode, required BitVector bits, required string encoding) {
		if (arguments.mode eq "NUMERIC") {
			appendNumericBytes(arguments.content, arguments.bits);
		} else if (arguments.mode eq "ALPHANUMERIC") {
			appendAlphanumericBytes(arguments.content, arguments.bits);
		} else if (arguments.mode eq "BYTE") {
			append8BitBytes(arguments.content, arguments.bits, arguments.encoding);
		} else if (arguments.mode eq "KANJI") {
			appendKanjiBytes(arguments.content, arguments.bits);
		} else {
			throw "Invalid mode: #arguments.mode#";
		}
	}

	public void function appendNumericBytes(required string content, required BitVector bits) {
		local.length = len(arguments.content);
		local.i = 0;
		local.zero = chr("0");
		while (local.i lt local.length) {
			local.num1 = arguments.content.charCodeAt(i) - local.zero;
			if (local.i + 2 lt local.length) {
				// Encode three numeric letters in ten bits.
				local.num2 = arguments.content.charCodeAt(i + 1) - local.zero;
				local.num3 = arguments.content.charCodeAt(i + 2) - local.zero;
				arguments.bits.appendBits(local.num1 * 100 + local.num2 * 10 + local.num3, 10);
				local.i += 3;
			} else if (local.i + 1 lt local.length) {
				// Encode two numeric letters in seven bits.
				local.num22 = arguments.content.charCodeAt(i + 1) - local.zero;
				bits.appendBits(local.num1 * 10 + local.num22, 7);
				local.i += 2;
			} else {
				// Encode one numeric letter in four bits.
				arguments.bits.appendBits(local.num1, 4);
				local.i++;
			}
		}
	}

	public void function appendAlphanumericBytes(required string content, required BitVector bits) {
		local.length = arguments.content.length;
		local.i = 0;
		while (local.i lt local.length) {
			local.code1 = getAlphanumericCode(arguments.content.charCodeAt(i));
			if (local.code1 eq -1) {
				throw "appendAlphanumericBytes assertion 1";
			}
			if (local.i + 1 lt local.length) {
				local.code2 = getAlphanumericCode(arguments.content.charCodeAt(i + 1));
				if (local.code2 eq -1) {
					throw "appendAlphanumericBytes assertion 2";
				}
				// Encode two alphanumeric letters in 11 bits.
				arguments.bits.appendBits(local.code1 * 45 + local.code2, 11);
				local.i += 2;
			} else {
				// Encode one alphanumeric letter in six bits.
				arguments.bits.appendBits(local.code1, 6);
				local.i++;
			}
		}
	}

	public void function append8BitBytes(required string content, required BitVector bits, required string encoding) {
		local.bytes = new ByteArray();
		try {
			//bytes = content.getBytes(encoding);
			if ((arguments.encoding eq "Shift_JIS") or (arguments.encoding eq "SJIS")) { local.bytes.writeMultiByte(arguments.content, "shift-jis");}
			else if (arguments.encoding eq "Cp437")     { local.bytes.writeMultiByte(arguments.content, "IBM437"); }
			else if (arguments.encoding eq "ISO8859_2") { local.bytes.writeMultiByte(arguments.content, "iso-8859-2"); }
			else if (arguments.encoding eq "ISO8859_3") { local.bytes.writeMultiByte(arguments.content, "iso-8859-3"); }
			else if (arguments.encoding eq "ISO8859_4") { local.bytes.writeMultiByte(arguments.content, "iso-8859-4"); }
			else if (arguments.encoding eq "ISO8859_5") { local.bytes.writeMultiByte(arguments.content, "iso-8859-5"); }
			else if (arguments.encoding eq "ISO8859_6") { local.bytes.writeMultiByte(arguments.content, "iso-8859-6"); }
			else if (arguments.encoding eq "ISO8859_7") { local.bytes.writeMultiByte(arguments.content, "iso-8859-7"); }
			else if (arguments.encoding eq "ISO8859_8") { local.bytes.writeMultiByte(arguments.content, "iso-8859-8"); }
			else if (arguments.encoding eq "ISO8859_9") { local.bytes.writeMultiByte(arguments.content, "iso-8859-9"); }
			else if (arguments.encoding eq "ISO8859_11"){ local.bytes.writeMultiByte(arguments.content, "iso-8859-11"); }
			else if (arguments.encoding eq "ISO8859_15"){ local.bytes.writeMultiByte(arguments.content, "iso-8859-15"); }
			else if ((arguments.encoding eq "ISO-8859-1") or (encoding eq "ISO8859-1")) { local.bytes.writeMultiByte(arguments.content, "iso-8859-1"); }
			else {
				throw "Encoding #arguments.encoding# not supported";
			}
			local.bytes.position = 0;

		} catch (any uee) {
			throw uee.message;
		}
		for (local.i = 0; i lt local.bytes.length; local.i++) {
			arguments.bits.appendBits(local.bytes[local.i], 8);
		}
	}

	public void function appendKanjiBytes(required string content, required BitVector bits) {
		local.bytes = new ByteArray();
		local.ff = inputBaseN("FF", 16);
		local.x8140 = inputBaseN("8140", 16);
		local.x9ffc = inputBaseN("9FFC", 16);
		local.xebbf = inputBaseN("EBBF", 16);
		local.xc140 = inputBaseN("C140", 16);
		local.xe040 = inputBaseN("E040", 16);
		local.c0 = inputBaseN("C0", 16);
		try {
			// we need data in the ShiftJis format
			//bytes = content.getBytes("Shift_JIS");
			local.bytes.writeMultiByte(arguments.content, "shift-jis");
			local.bytes.position = 0;
		} catch (any uee) {
			throw uee.message;
		}
		local.length = local.bytes.length;
		for (local.i = 0; local.i lt local.length; local.i += 2) {
			local.byte1 = bitAnd(local.bytes[local.i], local.ff);
			local.byte2 = bitAnd(local.bytes[local.i + 1], local.ff);
			local.code  = bitOr(bitShln(local.byte1, 8), local.byte2);
			local.subtracted = -1;
			if ((local.code gte local.x8140) and (code lte local.x9ffc)) {
				local.subtracted = local.code - local.x8140;
			} else if ((code gte local.xe040) and (code lte local.xebbf)) {
				local.subtracted = local.code - local.xc140;
			}
			if (local.subtracted eq -1) {
				throw "Invalid byte sequence";
			}
			local.encoded = (bitShrn(subtracted, 8) * local.c0) + bitAnd(local.subtracted, local.ff);
			arguments.bits.appendBits(local.encoded, 13);
		}
	}

	public void function appendECI(required CharacterSetECI eci, required BitVector bits) {
		arguments.bits.appendBits(new Mode("ECI").getBits(), 4);
		// This is correct for values up to 127, which is all we need now.
		arguments.bits.appendBits(arguments.eci.getValue(), 8);
	}

}