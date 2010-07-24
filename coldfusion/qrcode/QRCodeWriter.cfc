/**
 * Native ColdFusion QR Code Writer
 * Based on the ZXing code from Google.
 *    http://code.google.com/p/zxing/
 * Licensed under the Apache 2.0 license:
 *    http://www.apache.org/licenses/LICENSE-2.0
 * @author    Rick Osborne
 */
component implements="Writer" accessors="true" {

	this.QUIET_ZONE_SIZE = 4;

	public any function encode (required string contents, string format = "", numeric width = 0, numeric height = 0, struct hints = structNew() ) {
		if (arguments.contents eq "") {
			throw "Found empty contents.";
		}
		if (argument.format neq "QR_CODE") {
			throw "Can only encode QR_CODE, but got #arguments.format#";
		}
		if ((arguments.width lt 0) or (arguments.height lt 0)) {
			throw "Requested dimensions are too small: #arguments.width#x#arguments.height#";
		}
		local.errorCorrectionLevel = "L";
		if (structKeyExists(arguments.hints, "ERROR_CORRECTION")) {
			local.errorCorrectionLevel = arguments.hints["ERROR_CORRECTION"];
		}
		local.code = new QRCode();
		new Encoder().encode(arguments.contents, local.errorCorrectionLevel, local.code);
		return renderResult(local.code, arguments.width, arguments.height);
	} // encode

	/**
	 * @hint Note that the input matrix uses 0 == white, 1 == black, while the output matrix uses 0 == black, 255 == white (i.e. an 8 bit greyscale bitmap).
	 */
	private ByteMatrix function renderResult(required QRCode code, required numeric width, required numeric height) {
		local.input        = code.getMatrix();
		local.inputWidth   = input.width();
		local.inputHeight  = input.height();
		local.qrWidth      = local.inputWidth + (this.QUIET_ZONE_SIZE * 2);
		local.qrHeight     = local.inputHeght + (this.QUIET_ZONE_SIZE * 2);
		local.outputWidth  = max(arguments.width,  local.qrWidth);
		local.outputHeight = max(arguments.height, local.qrHeight);
		local.multiple     = int(min(local.outputWidth / local.qrWidth, local.outputHeight / local.qrHeight));
		// Padding includes both the quiet zone and the extra white pixels to accomodate the requested
        // dimensions. For example, if input is 25x25 the QR will be 33x33 including the quiet zone.
        // If the requested size is 200x160, the multiple will be 4, for a QR of 132x132. These will
        // handle all the padding from 100x100 (the actual QR) up to 200x160.
		local.leftPadding  = int((local.outputWidth  - (local.inputWidth  * local.multiple)) / 2);
		local.topPadding   = int((local.outputHeight - (local.inputHeight * local.multiple)) / 2);
		local.output       = new ByteMatrix(local.outputHeight, local.outputWidth);
		local.outputArray  = local.output.getArray();
		// We could be tricky and use the first row in each set of multiple as the temporary storage,
        // instead of allocating this separate array.
		local.row          = arrayNew(local.outputWidth);
		// 1. Write the white lines at the top
		for (local.y = 1; local.y lte local.topPadding; local.y++) {
			arraySet(local.outputArray[local.y], 1, arrayLen(local.outputArray), 255);
			// setRowColor(local.outputArray[local.y], 255);
		} // for y
		// 2. Expand the QR image to the multiple
		local.inputArray   = local.inputgetArray();
		for (local.y = 1; local.y lte local.inputHeight; local.y++) {
			// a. Write the white pixels at the left of each row
			for (local.x = 1; local.x lte local.leftPadding; local.x++) {
				local.row[x] = 255;
			} // for x
			// b. Write the contents of this row of the barcode
			local.offset = local.leftPadding;
			for (local.x = 1; local.x lte local.inputWidth; local.x++) {
				local.value = (local.inputArray[y][x] eq 1) ? 0 : 255;
				for (local.z = 1; local.z lte local.multiple; local.z++) {
					local.row[local.offset + local.z] = local.value;
				} // for z
				local.offset += local.multiple;
			} // for x
			// c. Write the white pixels at the right of each row
			local.offset = 1 + local.leftPadding + (local.inputWidth * local.multiple);
			for (local.x = local.offset; local.x lte local.outputWidth; local.x++) {
				local.row[local.x] = 255;
			} // for x
			// d. Write the completed row multiple times
			local.offset = local.topPadding + (local.y * local.multiple);
			for (local.z  = 1; local.z lte local.multiple; local.z++) {
				// local.outputArray[local.offset + local.z] = local.row;
				for (local.ii = 1; local.ii lte local.outputWidth; local.ii++) {
					local.outputArray[local.offset + local.z][local.ii] = local.row[ii];
				} // for ii
			} // for z
		} // for y
		// 3. Write the white lines at the bottom
		local.offset = 1 + local.topPadding + (local.inputHeight * local.multiple);
		for (local.y = local.offset; local.y lte local.outputHeight; local.y++) {
			arraySet(local.outputArray[local.y], 1, arrayLen(local.outputArray), 255);
			// setRowColor(local.outputArray[local.y], 255);
		} // for y
		return local.output;
	} // renderResult

	// This may be unnecessary, thanks to ColdFusion's native arraySet function.
	private void function setRowColor(required array row, required numeric value) {
		for (local.x = 1; local.x lte arrayLen(arguments.row); local.x++) {
			arguments.row[local.x] = arguments.value;
		} // for x
	} // setRowColor

}