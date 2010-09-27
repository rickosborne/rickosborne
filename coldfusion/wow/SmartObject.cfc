component {

public void function loadProperties(required struct props) {
	for(local.k in arguments.props) {
		if(structKeyExists(variables, k)) {
			variables[k] = arguments.props[k];
		}
	} // for k
} // loadProperties

public any function loadOrNew(required string entityName, required array match, required struct params) {
	local.m = {};
	for(local.i = 1; i lte arrayLen(arguments.match); i++) {
		m[arguments.match[i]] = arguments.params[arguments.match[i]];
	} // for i
	local.e = entityLoad(arguments.entityName, m);
	if(arrayLen(local.e) eq 1) {
		local.e = local.e[1];
		local.e.loadProperties(arguments.params);
		return local.e;
	}
	return entityNew(arguments.entityName, arguments.params);
} // loadOrNew

}
