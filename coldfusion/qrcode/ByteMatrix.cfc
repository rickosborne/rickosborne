/**
 * Native ColdFusion Byte Matrix
 * Based on the ZXing code from Google.
 *    http://code.google.com/p/zxing/
 * Licensed under the Apache 2.0 license:
 *    http://www.apache.org/licenses/LICENSE-2.0
 * @author    Rick Osborne
 */
component {

	public any function init (required numeric height, required numeric width) {
		variables.bytes = arrayNew(arguments.height);
		for (local.i = 1; local.i lte arguments.width; local.i++) {
			variables.bytes[local.i] = arrayNew(arguments.width);
		} // for i
		variables.height = arguments.height;
		variables.width  = arguments.width;
	} // init

	public numeric function height ()   { return variables.height; }
	public numeric function width ()    { return variables.width;  }
	public numeric function _get (required numeric x, required numeric y) { return variables.bytes[arguments.x][arguments.y]; }
	public array   function getArray () { return variables.bytes; }

	public void function _set (required numeric x, required numeric y, required any value) {
		if (isNumeric(arguments.value) and (int(arguments.value) eq arguments.value)) {
			variables.bytes[arguments.x][arguments.y] = arguments.value;
		} else {
			throw "ByteMatrix : _set : unknown type of value";
		}
	} // _set

	public void function clear (required numeric value) {
		for (local.y = 1; local.y lte variables.height; local.y++) {
			arraySet(variables.bytes[local.y], 1, variables.width, arguments.value);
			// for (local.x = 1; local.x lte variables.width; local.x++) {
			//	variables.bytes[local.y][local.x] = arguments.value;
			// } // for x
		}  // for y
	} // clear

	public numeric function sum () {
		local.result = 0;
		for (local.y = 1; local.y lte variables.height; local.y++) {
			local.result += arraySum(variables.bytes[local.y]);
			// for (local.x = 1; local.x lte variables.width; local.x++) {
			//	local.result += variables.bytes[local.y][local.x];
			// } // for x
		}  // for y
		return local.result;
	} // sum

	public string function toString () {
		local.crlf = chr(13) & chr(10);
		local.result = "";
		for (local.y = 1; local.y lte variables.height; local.y++) {
			for (local.x = 1; local.x lte variables.width; local.x++) {
				local.result &= (variables.bytes[local.y][local.x] eq 0) ? "0" : (variables.bytes[local.y][local.x] eq 1 ? "1" : ".");
			} // for x
			local.result &= local.crlf;
		}  // for y
		return local.result;
	} // toString

}