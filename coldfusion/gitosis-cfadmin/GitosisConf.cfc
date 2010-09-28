component {

public any function init(required string iniPath) {
	variables.ini = new IniFile(arguments.iniPath);
	return this;
} // init

private string function _repoKey(required string repoName) {
	return "repo " & arguments.repoName;
} // _repoKey

public boolean function repoExists(required string repoName) {
	return (variables.ini.sectionKeyCount(_repoKey(arguments.repoName)) gt 0);
} // repoExists

public struct function repoDetails(required string repoName) {
	var d = {};
	var r = variables.ini.sectionKeys(_repoKey(arguments.repoName));
	var n = 0;
	for (n = 1; n lte r.recordCount; n++)
		d[r.key[n]] = r.value[n];
	return d;
} // repoDetails

public void function repoSet(required string repoName, required string description, required string owner, boolean gitweb) {
	var values = {
		"description" = arguments.description,
		"owner"       = arguments.owner
	};
	if (structKeyExists(arguments, "gitweb"))
		values["gitweb"] = yesNoFormat(arguments.gitweb);
	variables.ini.setSection(_repoKey(arguments.repoName), values);
} // repoAdd

public void function repoRemove(required string repoName) {
	variables.ini.removeSection(_repoKey(arguments.repoName));
} // repoSet

public array function repoNames() {
	return _thingNames(_repoKey("%"));
} // repoNames

private string function _groupKey(required string groupName) {
	return "group " & arguments.groupName;
} // _groupKey

public boolean function groupExists(required string groupName) {
	return (variables.ini.sectionKeyCount(_groupKey(arguments.groupName)) gt 0);
} // groupExists

public struct function groupDetails(required string groupName) {
	var d = {};
	var r = variables.ini.sectionKeys(_groupKey(arguments.groupName));
	var n = 0;
	for (n = 1; n lte r.recordCount; n++) {
		var key = r.key[n];
		if ((key eq "memers") or (key eq "writable") or (key eq "readonly")) 
			d[key] = listToArray(r.value[n]," ");
		else
			d[key] = r.value[n];
	} // for n
	return d;
} // groupDetails

public void function groupSet(required string groupName, string description, array members, array writable, array readonly, boolean gitweb) {
	var values = {};
	if (structKeyExists(arguments, "description"))
		values["description"] = yesNoFormat(arguments.gitweb);
	if (structKeyExists(arguments, "members"))
		values["members"] = arrayToList(arguments.members, " ");
	if (structKeyExists(arguments, "writable"))
		values["writable"] = arrayToList(arguments.writable, " ");
	if (structKeyExists(arguments, "readonly"))
		values["readonly"] = arrayToList(arguments.readonly, " ");
	if (structKeyExists(arguments, "gitweb"))
		values["gitweb"] = yesNoFormat(arguments.gitweb);
	variables.ini.setSection(_groupKey(arguments.groupName), values);
} // groupSet

public void function groupRemove(required string groupName) {
	variables.ini.removeSection(_groupKey(arguments.groupName));
} // groupRemove

private array function _thingNames(required string thingKey) {
	var q = variables.ini.sectionsLike(arguments.thingKey);
	var n = 0;
	var a = [];
	arrayResize(a, q.recordCount);
	for (n = 1; n lte q.recordCount; n++)
		a[n] = mid(q.section[n], 6, len(q.section[n]));
	return a;
}

public array function groupNames() {
	return _thingNames(_groupKey("%"));
} // repoNames



public void function dump() {
	writeDump(variables);
	variables.ini.dump();
} // dump

}