component {

variables.iniPath = "";
variables.comments = "##;";

public any function init(required string iniPath, string comments) {
	if (not fileExists(arguments.iniPath))
		throw(message="INI file does not exist", detail="The INI file (#arguments.iniPath#) provided to the constructor (init) does not exist.");
	if (structKeyExists(arguments, "comments"))
		variables.comments = arguments.comments;
	variables.data = _readIni(arguments.iniPath);
	variables.iniPath = arguments.iniPath;
	return this;
} // init

private query function _readIni(required string iniPath) {
	var infile = fileOpen(arguments.iniPath, "read");
	var section = "";
	var q = _emptyData();
	var lineNum = 0;
	while (not fileIsEOF(infile)) {
		var line = trim(fileReadLine(infile));
		lineNum++;
		if (len(variables.comments) gt 0)
			line = listFirst(line, variables.comments);
		if (len(line) eq 0)
			continue;
		if (left(line,1) eq "[") {
			if ((right(line,1) eq "]") and (len(line) gt 2)) {
				section = trim(mid(line, 2, len(line) - 2));
			} // if section header
			continue;
		} // if starts with [
		if (not (line contains "="))
			continue;
		if (section eq "")
			continue;
		var key = trim(listFirst(line, "="));
		if (len(key) eq 0)
			continue;
		var value = trim(listRest(line, "="));
		_addLine(q, section, key, value, lineNum);
	} // while
	fileClose(infile);
	return q;
} // _readIni

private void function _writeIni(required string iniPath, required query iniData) {
	var tmpPath = getTempFile(getTempDirectory(),"gts");
	var outfile = fileOpen(tmpPath, "write");
	var rn = 0;
	var section = "";
	for (rn = 1; rn lte iniData.recordCount; rn++) {
		if (iniData.section[rn] neq section) {
			if (section neq "")
				fileWriteLine(outfile, "");
			section = iniData.section[rn];
			fileWriteLine(outfile, "[" & section & "]");
		} // if new section
		fileWriteLine(outfile, iniData.key[rn] & " = " & iniData.value[rn]);
	} // for rn 
	fileWrite(outfile, "## Last modified by Gitosis CFAdmin, " & dateFormat(now(), "yyyy-mm-dd") & " " & timeFormat(now(), "HH:mm:ss"));
	fileClose(outfile);
	if (fileExists(arguments.iniPath))
		fileMove(arguments.iniPath, arguments.initPath & "-" & dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss") & ".bak");
	fileMove(tmpPath, arguments.iniPath);
} // _writeIni

public void function save() {
	_writeIni(variables.iniPath, variables.data);
} // save

private query function _emptyData() {
	return queryNew("section,key,value,line","VarChar,VarChar,VarChar,Decimal");
} // _emptyData

public void function removeKey(required string section, required string key) {
	request.d = variables.data;
	var q = new Query(dbtype="Query", sql="SELECT * FROM request.d WHERE ([section] = :section) AND (key = :key)");
	q.addParam(name="section", value=arguments.section);
	q.addParam(name="key", value=arguments.key);
	variables.data = q.execute().getResult();
} // removeKey

public void function removeSection(required string section) {
	request.d = variables.data;
	var q = new Query(dbtype="Query", sql="SELECT * FROM request.d WHERE ([section] = :section)");
	q.addParam(name="section", value=arguments.section);
	variables.data = q.execute().getResult();
} // removeSection

private void function _addLine(required query data, required string section, required string key, required string value, required numeric lineNum) {
	queryAddRow(arguments.data);
	querySetCell(arguments.data, "section", arguments.section, arguments.data.recordCount);
	querySetCell(arguments.data, "key"    , arguments.key    , arguments.data.recordCount);
	querySetCell(arguments.data, "value"  , arguments.value  , arguments.data.recordCount);
	querySetCell(arguments.data, "line"   , arguments.lineNum, arguments.data.recordCount);
} // _addLine

public void function setKey(required string section, required string key, required string value) {
	request.d = variables.data;
	// find existing section
	var q = new Query(dbtype="Query", sql="SELECT line FROM d WHERE ([section] = :section) AND (key = :key)");
	q.addParam("section", arguments.section);
	q.addParam("key", arguments.key);
	q = q.execute().getResult();
	var lineNum = 1;
	request.r = _emptyData();
	if (q.recordCount gt 0) {
		_addLine(request.r, arguments.section, arguments.key, arguments.value, q.line);
		q = new Query(dbtype="query", sql="SELECT * FROM request.d WHERE ([line] < :line1) UNION ALL SELECT * FROM request.r UNION ALL SELECT * FROM request.d WHERE ([line] > :line2)");
		q.addParam(name="line1", value=lineNum);
		q.addParam(name="line2", value=lineNum);
		variables.data = q.execute().getResult();
		return;
	} // if we have a match
	q = new Query(dbtype="Query", sql="SELECT MAX(line) AS lastLine FROM d WHERE ([section] = :section)");
	q.addParam("section", arguments.section);
	q = q.execute().getResult();
	if ((q.recordCount eq 0) or (not isNumeric(q.lastLine))) {
		_addLine(variables.data, arguments.section, arguments.key, arguments.value, _nextLine());
		return; 
	} // if new section
	lineNum = q.lastLine;
	_addLine(request.r, arguments.section, arguments.key, arguments.value, lineNum + 0.01);
	q = new Query(dbtype="query", sql="SELECT * FROM request.d WHERE ([line] <= :line1) UNION ALL SELECT * FROM request.r UNION ALL SELECT * FROM request.d WHERE ([line] > :line2)");
	q.addParam(name="line1", value=lineNum);
	q.addParam(name="line2", value=lineNum);
	variables.data = q.execute().getResult();
} // setKey

private numeric function _nextLine() {
	return (variables.data.recordCount eq 0 ? 1 : int(variables.data.line[variables.data.recordCount] + 1));
} // nextLine

public void function setSection(required string section, required struct values) {
	request.d = variables.data;
	request.r = _emptyData();
	var key = "";
	var lineNum = _nextLine();
	for (key in values) {
		_addLine(r, arguments.section, lcase(key), values[key], lineNum++);
	} // for key
	var q = new Query(dbtype="query", sql="SELECT * FROM request.d WHERE ([section] != :section) UNION ALL SELECT * FROM request.r");
	q.addParam(name="section", value=arguments.section);
	variables.data = q.execute().getResult();	
} // setSection

public query function sectionKeys(required string section) {
	request.d = variables.data;
	var q = new Query(dbtype="query", sql="SELECT * FROM request.d WHERE ([section] = :section)");
	q.addParam(name="section", value=arguments.section);
	return q.execute().getResult();
} // sectionKeys

public query function sectionsLike(required string section) {
	request.d = variables.data;
	var q = new Query(dbtype="query", sql="SELECT DISTINCT [section] FROM request.d WHERE ([section] LIKE :section)");
	q.addParam(name="section", value=arguments.section);
	return q.execute().getResult();
} // sectionsLike

public numeric function sectionKeyCount(required string section) {
	request.d = variables.data;
	var q = new Query(dbtype="query", sql="SELECT COUNT(*) AS keyCount FROM request.d WHERE ([section] = :section)");
	q.addParam(name="section", value=arguments.section);
	return q.execute().getResult().keyCount;
} // sectionKeyCount

public string function keyValue(required string section, required string key) {
	request.d = variables.data;
	var q = new Query(dbtype="query", sql="SELECT [value] FROM request.d WHERE ([section] = :section) AND ([key] = :key)");
	q.addParam(name="section", value=arguments.section);
	q.addParam(name="key", value=arguments.key);
	return q.execute().getResult().value;	
} // keyValue

public void function dump() {
	writeDump(variables);
} // dump

}