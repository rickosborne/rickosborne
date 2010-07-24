/**
 * Native ColdFusion QR Code
 * Based on the ZXing code from Google.
 *    http://code.google.com/p/zxing/
 * Licensed under the Apache 2.0 license:
 *    http://www.apache.org/licenses/LICENSE-2.0
 * @author    Rick Osborne
 */
component accessors="true" {

	property name="mode" type="string" default="" getter="true" setter="true" hint="Mode of the QR Code.";
	property name="ecLevel" type="string" default="" getter="true" setter="true" hint="Error correction level of the QR Code.";
	property name="version" type="numeric" default="-1" getter="true" setter="true" hint="Version of the QR Code.  The bigger size, the bigger version.";
	property name="matrixWidth" type="numeric" default="-1" getter="true" setter="true" hint="ByteMatrix width of the QR Code.";
	property name="maskPattern" type="numeric" default="-1" getter="true" setter="true" hint="Mask pattern of the QR Code.";
	property name="numTotalBytes" type="numeric" default="-1" getter="true" setter="true" hint="Number of total bytes in the QR Code.";
	property name="numDataBytes" type="numeric" default="-1" getter="true" setter="true" hint="Number of data bytes in the QR Code.";
	property name="numECBytes" type="numeric" default="-1" getter="true" setter="true" hint="Number of error correction bytes in the QR Code.";
	property name="numRSBlocks" type="numeric" default="-1" getter="true" setter="true" hint="Number of Reed-Solomon blocks in the QR Code.";
	property name="matrix" type="any" getter="true" setter="true" hint="ByteMatrix data of the QR Code.";

	this.NUM_MASK_PATTERNS = 8;

	public any function init() {
		variables.mode = "";
		variables.ecLevel = "";
		variables.version = -1;
		variables.matrixWidth = -1;
		variables.maskPattern = -1;
		variables.numTotalBytes = -1;
		variables.numDataBytes = -1;
		variables.numECBytes = -1;
		variables.numRSBlocks = -1;
		variables.matrix = false;
		return this;
	} // init

	/**
	 * @hint Return the value of the module (cell) pointed by "x" and "y" in the matrix of the QR Code. They call cells in the matrix "modules". 1 represents a black cell, and 0 represents a white cell.
	 */
	public numeric function at (required numeric x, required numeric y) {
		local.value = variables.matrix[arguments.x][arguments.y];
		if (not ((local.value eq 1) or (local.value eq 0))) {
			throw "QRCode: Bad value";
		} // if not 0/1
		return local.value;
	} // at

	/**
	 * @hint Checks all the member variables are set properly. Returns true on success. Otherwise, returns false.
	 */
	public boolean function isValid() {
		return (variables.mode neq "")
			and (variables.ecLevel neq "")
			and (variables.matrixWidth neq -1)
			and (variables.maskPattern neq -1)
			and (variables.numTotalBytes neq -1)
			and (variables.numDataBytes neq -1)
			and (variables.numECBytes neq -1)
			and (variables.numRSBlocks neq -1)
			and isValidMaskPattern(variables.maskPattern)
			and (variables.numTotalBytes eq (variables.numDataBytes + variables.numECBytes))
			and (not isSimpleValue(variables.matrix))
			and (variables.matrixWidth eq variables.matrix.width())
			and (variables.matrix.width() eq variables.matrix.height());
	} // isValid

	/**
	 * @hint Return debug string.
	 */
	 public string function toString() {
	 	local.crlf = chr(13) & chr(10);
	 	local.result = "<<#crlf#"
			& " mode: #variables.mode# #crlf#"
			& " ecLevel: #variables.ecLevel# #crlf#"
			& " version: #variables.version# #crlf#"
			& " matrixWidth: #variables.matrixWidth# #crlf#"
			& " maskPattern: #variables.maskPattern# #crlf#"
			& " numTotalBytes: #variables.numTotalBytes# #crlf#"
			& " numDataBytes: #variables.numDataBytes# #crlf#"
			& " numECBytes: #variables.numECBytes# #crlf#"
			& " numRSBlocks: #variables.numRSBlocks# #crlf#";
		if (isSimpleValue(variables.matrix)) {
			local.result &= " matrix: null #crlf#";
		} else {
			local.result &= " matrix: #variables.matrix.toString()# #crlf#";
		}
		local.result &= ">>#crlf#";
		return local.result;
	 } // toString

	 /**
	  * @hint Check if "mask_pattern" is valid.
	  */
	 public boolean function isValidMaskPattern(required numeric maskPattern) {
	 	return (variables.maskPattern gte 0) and (variables.maskPattern lt this.NUM_MASK_PATTERNS);
	 }

}
