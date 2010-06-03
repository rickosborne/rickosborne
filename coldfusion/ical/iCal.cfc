component {

variables.eol = chr(13) & chr(10);
variables.data = { };

public any function init(string filePath = "") output="false" {
	var inFilePath = expandPath("assets/template.ics");
	if(fileExists(arguments.filePath)) { inFilePath = arguments.filePath; }
	var err = _readFile(inFilePath);
	if (err neq "") { variables.data["ERROR"] = err; }
	if (not structKeyExists(variables.data, "VEVENT")) { variables.data["VEVENT"] = []; }
	return this;
} // init

public boolean function writeFile(required string filePath) output="false" {
	var ret = false;
	try {
		var outFile = fileOpen(arguments.filePath, "write");
		_writeBlock(outFile, "VCALENDAR", variables.data);
		ret = true;
	}
	catch(any err) { }
	finally {
		fileClose(outFile);
	}
	return ret;
} // writeFile

public void function addEvent(
	required string summary,
	required date startDate,
	date endDate,
	string uid,
	string location,
	string description,
	string email
) output="false" {
	if (not structKeyExists(arguments, "uid")) { arguments.uid = "CFCFCFCF-CFCF-CFCF-CFCF-" & right(hash(arguments.startDate), 12); }
	if (not structKeyExists(arguments, "endDate")) { arguments.endDate = arguments.startDate; }
	var n = dateConvert("local2Utc", now());
	var dtStamp = dateFormat(n, "yyyymmdd") & "T" & timeFormat(n, "HHmmss") & "Z";
	var dtStart = dateFormat(arguments.startDate, "yyyymmdd") & "T" & timeFormat(arguments.startDate, "HHmmss");
	var dtEnd = dateFormat(arguments.endDate, "yyyymmdd") & "T" & timeFormat(arguments.endDate, "HHmmss");
	var tzid = variables.data.vtimezone.tzid;
	var event = {
		"SUMMARY"             = replaceList(trim(arguments.summary), "#chr(13)#,#chr(10)#", "=0D,=0A"),
		"TRANSP"              = "OPAQUE",
		"UID"                 = arguments.uid,
		"DTSTART;TZID=#tzid#" = dtStart,
		"DTEND;TZID=#tzid#"   = dtEnd,
		"DTSTAMP"             = dtStamp,
		"CREATED"             = dtStamp,
		"SEQUENCE"            = 1 + arrayLen(variables.data.vevent)
	};
	if (structKeyExists(arguments, "description") and (arguments.description neq "")) { event["DESCRIPTION"] = replaceList(trim(arguments.description), "#chr(13)#,#chr(10)#", "=0D,=0A"); }
	if (structKeyExists(arguments, "email") and (arguments.email neq "")) { event["ATTENDEE"] = "MAILTO:" & lcase(arguments.email); }
	if (structKeyExists(arguments, "location") and (arguments.location neq "")) { event["LOCATION"] = replaceList(trim(arguments.location), "#chr(13)#,#chr(10)#", "=0D,=0A"); }
	arrayAppend(variables.data.vevent, event);
} // addEvent

public string function toString() output="false" {
	var fileName = "ram://ical-cfc-" & createUUID() & ".ics";
	writeFile(fileName);
	var ret = fileRead(fileName);
	fileDelete(fileName);
	return ret;
} // toString

public struct function getData() output="false" {
	return duplicate(variables.data);
} // getData

public void function setName(required string newName) output="false" { variables.data["X-WR-CALNAME"] = arguments.newName; }

public void function importEvents(required string filePath, required date startDate, required date endDate) output="false" {
	var otherEvents = createObject("component", "iCal").init(arguments.filePath).getData();
	var events = otherEvents.vevent;
	var eventCount = arrayLen(events);
	var tzid = otherEvents.vtimezone.tzid;
	var startKey = "DTSTART;TZID=" & tzid;
	var endKey = "DTEND;TZID=" & tzid;
	var checkStart = dateFormat(arguments.startDate, "yyyymmdd") & "T" & timeFormat(arguments.startDate, "HHmmss");
	var checkEnd = dateFormat(arguments.endDate, "yyyymmdd") & "T" & timeFormat(arguments.endDate, "HHmmss");
	var fullStart = val(checkStart);
	var fullEnd = val(checkEnd);
	var fullStartKey = "DTSTART;VALUE=DATE";
	var fullEndKey = "DTSTART;VALUE=DATE";
	var n = 0;
	var c = 0;
	var wantEvent = 0;
	for (n = 1; n lte eventCount; n++) {
		event = events[n];
		if (
			(structKeyExists(event, endKey) and (event[endKey] gte checkStart)) or (structKeyExists(event, fullEndKey) and (val(event[fullEndKey]) gte fullStart))
			and
			(structKeyExists(event, startKey) and (event[startKey] lte checkEnd)) or (structKeyExists(event, fullStartKey) and (val(event[fullStartKey]) lte fullEnd))
		) {
			arrayAppend(variables.data.vevent, duplicate(event));
			variables.data.vevent[arrayLen(variables.data.vevent)]["SEQUENCE"] = arrayLen(variables.data.vevent);
		} // if in date range
	} // for n
} // importEvents

public query function getEventsAsQuery(date startDate, date EndDate) output="false" {
	var q = queryNew("");
	var n = 0;
	var k = 0;
	var eventCount = arrayLen(variables.data.vevent);
	var event = 0;
	var keyName = 0;
	var keyNames = 0;
	var keyCount = 0;
	var colNames = {};
	var colName = "";
	var checkStart = false;
	var checkEnd = false;
	var startKey = "DTSTART;TZID=" & variables.data.vtimezone.tzid;
	var endKey = "DTEND;TZID=" & variables.data.vtimezone.tzid;
	var wantEvent = 0;
	if (structKeyExists(arguments, "startDate") and isDate(arguments.startDate)) { checkStart = dateFormat(arguments.startDate, "yyyymmdd") & "T" & timeFormat(arguments.startDate, "HHmmss"); }
	if (structKeyExists(arguments, "endDate") and isDate(arguments.endDate)) { checkEnd = dateFormat(arguments.endDate, "yyyymmdd") & "T" & timeFormat(arguments.endDate, "HHmmss"); }
	for (n = 1; n lte eventCount; n++) {
		event = variables.data.vevent[n];
		keyNames = structKeyArray(event);
		keyCount = arrayLen(keynames);
		wantEvent = true;
		if ((checkStart neq false) and structKeyExists(event, endKey) and (event[endKey] lt checkStart)) { wantEvent = false; }
		if ((checkEnd neq false) and structKeyExists(event, startKey) and (event[startKey] gt checkEnd)) { wantEvent = false; }
		if (wantEvent) {
			queryAddRow(q);
			for (k = 1; k lte keyCount; k++) {
				keyName = keyNames[k];
				if (isSimpleValue(event[keyName])) {
					colName = listFirst(keyName, ";");
					if (not structKeyExists(colNames, colName)) { queryAddColumn(q, colName, "VarChar", []); colNames[colName] = true; }
					querySetCell(q, colName, event[keyName], q.recordCount);
				} // if is simple value
			} // for k
		} // if want event
	} // for n
	return q;
} // getEventsAsQuery

private string function _readFile(required string filePath) output="false" {
	if (not fileExists(arguments.filePath)) { return "The specified filePath does not exist"; }
	var inFile = fileOpen(arguments.filePath, "read");
	var firstLine = trim(fileReadLine(inFile));
	if (firstLine neq "BEGIN:VCALENDAR") { return "The file does not start with BEGIN:VCALENDAR"; }
	variables.data = _readBlock(inFile, "VCALENDAR");
	fileClose(inFile);
	return "";
} // readFile

private struct function _readBlock(required any inFile, required string blockType) output="false" {
	var data = {};
	var line = "";
	var keyName = "";
	var keyValue = "";
	while(not fileIsEOF(arguments.inFile)) {
		line = fileReadLine(arguments.inFile);
		if(left(line,1) eq " ") {
			data[keyName] = data[keyName] & mid(line, 2, len(line));
		}
		else {
			keyName = listFirst(line, ":");
			keyValue = replaceList(listRest(line, ":"),"#chr(13)#,#chr(10)#",",");
			if (keyName eq "BEGIN") {
				if (keyValue eq "VEVENT") {
					if (not structKeyExists(data, "VEVENT")) { data["VEVENT"] = []; }
					arrayAppend(data["VEVENT"], _readBlock(arguments.inFile, blockType));
				} // if vevent
				else { data[keyValue] = _readBlock(arguments.inFile, blockType); }
			} // if starting a block
			else if (keyName eq "END") { return data; }
			else { data[keyName] = keyValue; }
		} // if a continued line
	} // while not eof
	return data;
} // readBlock

private void function _writeBlock(required any outFile, required string blockName, required struct blockData, numeric sequenceId = -1) output="false" {
	var keyName = "";
	var keyNames = structKeyArray(arguments.blockData);
	var i = 0;
	var j = 0;
	var k = 0;
	var keyCount = arrayLen(keyNames);
	var keyValue = 0;
	var valCount = 0;
	var colNames = "";
	fileWrite(arguments.outFile, "BEGIN:" & arguments.blockName & variables.eol);
	if (arguments.sequenceId > -1) { arguments.blockData["SEQUENCE"] = arguments.sequenceId; }
	var sortedKeyNames = [];
	var complexKeyNames = [];
	for (i = 1; i lte keyCount; i++) {
		keyName = keyNames[i];
		// timezone is such a hack ...
		if (isSimpleValue(arguments.blockData[keyName])) { arrayAppend(sortedKeyNames, keyName); }
		else { arrayAppend(complexKeyNames, keyName); }
	} // for i
	arraySort(sortedKeyNames, "text", "asc");
	arraySort(complexKeyNames, "text", "asc");
	for (i = arrayLen(complexKeyNames); i gte 1; i--) {
		arrayAppend(sortedKeyNames, complexKeyNames[i]);
	} // for i
	for (i = 1; i lte keyCount; i++) {
		keyName = sortedKeyNames[i];
		keyValue = arguments.blockData[keyName];
		if (isSimpleValue(keyValue)) { fileWrite(arguments.outFile, keyName & ":" & keyValue & variables.eol);  }
		else if (isStruct(keyValue)) { _writeBlock(arguments.outFile, keyName, keyValue); }
		else if (isArray(keyValue)) {
			valCount = arrayLen(keyValue);
			for (j = 1; j lte valCount; j++) {
				_writeBlock(arguments.outFile, keyName, keyValue[j], j);
			} // for j
		} // if array
		else if (isQuery(keyValue)) {
			colNames = listToArray(keyValue.columnList);
			valCount = arrayLen(colNames);
			for (j = 1; j lte keyValue.recordCount; j++) {
				fileWrite(arguments.outFile, "BEGIN:" & keyName & variables.eol & "SEQUENCE:" & j & variable.eol);
				for (k = 1; k lte valCount; k++) {
					fileWrite(arguments.outFile, colNames[k] & ":" & keyValue[colNames[k]][j] & variables.eol);
				} // for k
				fileWrite(arguments.outFile, "END:" & keyName & variables.eol);
			} // for j
		} // if query
	} // for i
	fileWrite(arguments.outFile, "END:" & arguments.blockName & variables.eol);
} // _writeBlock

// component
}