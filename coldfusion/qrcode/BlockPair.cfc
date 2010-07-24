/**
 * Native ColdFusion QR Code generator
 * Based on the ZXing code from Google.
 *    http://code.google.com/p/zxing/
 * Licensed under the Apache 2.0 license:
 *    http://www.apache.org/licenses/LICENSE-2.0
 * @author    Rick Osborne
 */
component accessors="true" {

	property name="dataBytes" type="zxingByteArray" setter="false";
	property name="errorCorrectionBytes" type="zxingByteArray" setter="false";

	public any function init(required zxingByteArray data, required zxingByteArray errorCorrection) {
		variables.dataBytes = arguments.data;
		variables.errorCorrectionBytes = arguments.errorCorrection;
		return this;
	} // init

}