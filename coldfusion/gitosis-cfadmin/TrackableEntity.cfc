component {

public any function init() {
	if (hasProperty("ID") and ((not structKeyExists(Variables, "ID")) or (Variables.id eq "")))
		setID(makeID());
	return this;
} // init

private string function base62(required string hexValue) {
	var num = createObject("java", "java.math.BigInteger").init(arguments.hexValue, javaCast("int", 16));
	var zero = createObject("java", "java.math.BigInteger").ZERO;
	var ret = "";
	var chars = "0123456789bcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
	var charLen = createObject("java", "java.math.BigInteger").valueOf(javaCast("int", len(chars)));
	while (num.compareTo(zero) gt 0) {
		var pair = num.divideAndRemainder(charLen);
		num = pair[1];
		ret = mid(chars, 1 + pair[2].intValue(), 1) & ret;
	} // while
	return ret;
} // makeIDfromHex

private string function makeID() {
	return right(base62(replace(createUUID(), "-", "", "all")), 16);
} // makeID

private boolean function hasProperty(required string propName) {
	var i = 1;
	var meta = getMetadata(this);
	if (structKeyExists(meta, "properties")) {
		var props = meta.properties;
		for (i = 1; i lte arrayLen(props); i++)
			if (structKeyExists(props[i], "name") and (props[i].name eq arguments.propName))
				return true;
	}
	return false;
} // hasProperty

public struct function toStruct() {
	var q = entityToQuery(this);
	var c = listToArray(q.columnList);
	var s = {};
	for (var i = 1; i lte arrayLen(c); i++)
		s[c[i]] = q[c[i]][1];
	return s;
} // toStruct

public void function preInsert() hint="I am called by the ORM just before a record is inserted" {
	// if (hasProperty("ID"))
		// setID(makeID());
		// Variables.id = makeID();
	if (hasProperty("Created"))
		Variables.Created = now();
	preUpdate();
	writeDump(this);
} // preInsert

public void function preUpdate() hint="I am called by the ORM just before a record is updated" {
	if (hasProperty("Updated"))
		Variables.Updated = now();
	if (hasProperty("Updater") and structKeyExists(Session, "user") and structKeyExists(Session.user, "id"))
		Variables.Updated = Session.user.id;
} // preUpdate

}