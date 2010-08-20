component {

variables.gateway     = "http://127.0.0.1:80/flex2gateway";
variables.destination = "ColdFusion";
variables.clientId    = createUUID();

public any function init(string gateway, string destination, string clientId) {
	if (structKeyExists(arguments, "gateway") and (arguments.gateway neq "")) variables.gateway = arguments.gateway;
	if (structKeyExists(arguments, "destination") and (arguments.destination neq "")) variables.destination = arguments.destination;
	if (structKeyExists(arguments, "clientId") and (arguments.clientId neq "")) variables.clientId = arguments.clientId;
	return this;
} // init

public any function callCfcMethod(required string cfcPath, required string method, any body) {
	var amfConnection = createObject("java", "flex.messaging.io.amf.client.AMFConnection").init();
	amfConnection.connect(variables.gateway);
	var message = createObject("java", "flex.messaging.messages.RemotingMessage").init();
	message.setMessageId(createUUID());
	message.setSource(arguments.cfcPath);
	message.setOperation(arguments.method);
	message.setDestination(variables.destination);
	message.setClientId(variables.clientId);
	if (structKeyExists(arguments, "body")) { message.setBody(arguments.body); }
	var ret = "";
	try {
		ret = amfConnection.call(javaCast("null", 0), [message]);
	} catch (flex.messaging.io.amf.client.exceptions.ClientStatusException cse) {
		writeDump(var = cse, label = "ClientStatusException");
		writeDump(cse.HttpResponseInfo.toString());
	}
	amfConnection.close();
	return ret;
} // callCfcMethod

}