/**
 * Git Gateway Chat Bot for ColdFusion 9+
 *
 * @author  Rick Osborne
 * @version 20100827
 */
component initmethod="init" {

variables.appKey = "gitchat";

lock scope="Application" type="exclusive" timeout="5" {
	if (not structKeyExists(application, variables.appKey)) {
		application[variables.appKey] = {};
	}
	appParam("buddies", {});
	appParam("chatGatewayID", "Git - Chat");
	appParam("chatLog", []);
	appParam("catchLog", []);
} // lock

private function appParam(required string name, required any value) {
	if (not structKeyExists(application[variables.appKey], arguments.name)) {
		application[variables.appKey][arguments.name] = arguments.value;
	} // if not exists
} // appParam

public any function init() output="false" {
	return this;
} // init

public void function setChatGatewayID(required string gatewayID) {
	if (application[variables.appKey].chatGatewayID neq arguments.gatewayID) {
		lock scope="Application" type="exclusive" timeout="5" {
			application[variables.appKey].chatGatewayID = arguments.gatewayID;
		} // lock
	} // if not the same
} // setChatGatewayID

private void function logAny(required any type, required any data) {
	lock scope="Application" type="exclusive" timeout="5" {
		arrayAppend(application[variables.appKey][arguments.type & "Log"], duplicate(arguments.data));
		while (arrayLen(application[variables.appKey][arguments.type & "Log"]) gt 5) {
			arrayDeleteAt(application[variables.appKey][arguments.type & "Log"], 1);
		} // while
	} // lock
} // logThing

private void function logChat(required struct data) {
	logAny("chat", arguments.data);
} // logChat

private void function logCatch(required any data) {
	logAny("catch", arguments.data);
} // logChat

public any function onIncomingMessage(required struct cfEvent) {
	try {
		setChatGatewayID(arguments.cfEvent.gatewayID);
		logChat(arguments.cfEvent.data);
		/*
		var ret = {
			"command" = "submit",
			"buddyID" = arguments.cfEvent.originatorID,
			"message" = "echo: " & arguments.cfEvent.data.MESSAGE
		};
		return ret;
		*/
	}
	catch(any e) {
		logCatch(e);
	}
} // onIncomingMessage

public void function onBuddyStatus(required struct cfEvent) {
	try {
		setChatGatewayID(arguments.cfEvent.gatewayID);
		logChat(arguments.cfEvent.data);
		lock scope="Application" type="exclusive" timeout="5" {
			buddies = application[variables.appKey].buddies;
			var buddyName = arguments.cfEvent.originatorID;
			if (not structKeyExists(variables.buddies, buddyName)) {
				buddies[buddyName] = {};
			}
			buddies[buddyName].status = arguments.cfEvent.data.BUDDYSTATUS;
			buddies[buddyName].seen   = arguments.cfEvent.data.TIMESTAMP;
			buddies[buddyName].group  = arguments.cfEvent.data.BUDDYGROUP;
			buddies[buddyName].nick   = arguments.cfEvent.data.BUDDYNICKNAME;
			application[variables.appKey].buddies = variables.buddies;
		} // lock
		/*
		SendGatewayMessage(arguments.cfEvent.gatewayID, {
			"command" = "submit",
			"buddyID" = arguments.cfEvent.originatorID,
			"message" = "status: " & arguments.cfEvent.data.BUDDYSTATUS
		});
		*/
	}
	catch (any e) {
		logCatch(e);
	}
} // onBuddyStatus

}
