component {

property name="basehref" type="string" insert="false" update="false";

public any function init() {
	variables.logger = new BotLogger();
	return this;
}

private string function fetchCached(required string url) {
	local.q = new Query();
	q.setSql("SELECT data FROM wow_bot_log WHERE (url = :url) ORDER BY finished DESC LIMIT 1");
	q.addParam(name = "url", value = arguments.url);
	return q.execute().getResult().data;
} // fetchCached

public xml function fetch(required string url) {
	local.c = fetchCached(arguments.url);
	if(local.c neq "") return local.c;
	local.id = logger.startLog(getMetaData(this).name, arguments.url);
	local.agent = new Http(url = arguments.url, method = "GET", timeout = 5);
	agent.addParam(type = "header", name="Accept", value = "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8");
	agent.addParam(type = "header", name="User-Agent", value = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; en-US; rv:1.9.2.10) Gecko/20100914 Firefox/3.6.10");
	local.response = agent.send();
	local.prefix = response.getPrefix();
	logger.finishLog(id, prefix.statusCode, prefix.mimeType, prefix.fileContent);
	if((prefix.statusCode CONTAINS "200") and (prefix.mimeType CONTAINS "xml") and isXml(prefix.fileContent)) {
		return xmlParse(prefix.fileContent);
	}
	return xmlParse("<error/>");
} // fetch

public void function loadProperties(required struct props) {
	for(local.k in arguments.props) {
		if(structKeyExists(variables, k) and (variables[k] neq arguments.props[k])) {
			variables[k] = arguments.props[k];
		}
	} // for k
} // loadProperties

public any function loadOrNew(required string entityName, required string match, required struct params) {
	local.e = entityLoad(arguments.entityName, { "#arguments.match#" = arguments.params[arguments.match] });
	if(arrayLen(local.e) eq 1) {
		local.e = local.e[1];
		local.e.loadProperties(arguments.params);
		return local.e;
	}
	return entityNew(arguments.entityName, arguments.params);
} // loadorNew

}