/**
 * Git Watcher Gateway for ColdFusion 9+
 *
 * Requires JGit (org.eclipse.jgit-*.jar) to be installed on the CF Server.
 *
 * @author  Rick Osborne
 * @version 20100827
 */
component initmethod="init" {

variables.appKey = "gitwatch";
variables.chatAppKey = "gitchat";

lock scope="Application" type="exclusive" timeout="5" {
	if (not structKeyExists(application, variables.appKey)) {
		application[variables.appKey] = {};
	}
	appParam("buddies", {});
	appParam("chatGatewayID", "Git - Chat");
	appParam("watchLog", []);
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

public void function fileChanged(required string filename, required date lastmod, required string action) {
	// var repoDir = rereplaceNoCase(arguments.fileName, "([.]git[:\\/]).*$", "\1");
	// var repo = createObject("java", "org.eclipse.jgit.lib.Repository").init(createObject("java", "java.io.File").init(repoDir));
	for (local.buddyID in application[variables.chatAppKey].buddies) {
		var buddy = application[variables.chatAppKey].buddies[buddyID];
		if (structKeyExists(buddy, "status") and ((buddy.status eq "ONLINE") or (buddy.status eq "FREE TO CHAT") or (buddy.status eq "IDLE"))) {
			SendGatewayMessage(application[variables.appKey].chatGatewayID, {
				"command" = "submit",
				"buddyID" = buddyID,
				"message" = "File Changed: " & arguments.filename
			});
		}
	} // for each buddy
	// writeDump(repo.getAllRefs());
	// writeDump(queryFromLog(repo, 25, createDate(2010,07,13)));
} // fileChanged

private query function queryFromLog(required any repo, numeric entryCount = 25, date earliest) {
	var git = createObject("java", "org.eclipse.jgit.api.Git").init(arguments.repo);
	// writeDump(git);
	var iter = git.log().call().iterator();
	// writeDump(iter);
	var commits = queryNew("id,authoremail,authorname,committime,committeremail,committername,fullmessage,parent1,parent2,parentcount,shortmessage,type","varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,varchar,integer,varchar,integer");
	for (var n = 1; n lte arguments.entryCount; n++) {
		if (iter.hasNext()) {
			var commit = iter.next();
			var commitTime = createObject("java", "java.util.Date").init(commit.getCommitTime() * 1000);
			if (structKeyExists(arguments, "earliest") and (earliest gt commitTime)) {
				return commits;
			} // if we've gone back too early
			queryAddRow(commits);
			querySetCell(commits, "id", commit.getName(), commits.recordCount);
			querySetCell(commits, "authorname", commit.getAuthorIdent().getName(), commits.recordCount);
			querySetCell(commits, "authoremail", commit.getAuthorIdent().getEmailAddress(), commits.recordCount);
			querySetCell(commits, "committime", commitTime, commits.recordCount);
			querySetCell(commits, "committername", commit.getCommitterIdent().getName(), commits.recordCount);
			querySetCell(commits, "committeremail", commit.getCommitterIdent().getEmailAddress(), commits.recordCount);
			querySetCell(commits, "fullmessage", commit.getFullMessage(), commits.recordCount);
			for(var p = 1; p lte min(2, commit.getParentCount()); p++) {
				querySetCell(commits, "parent#p#", commit.getParent(javaCast("int", p - 1)).getName(), commits.recordCount);
			} // for p
			querySetCell(commits, "parentcount", commit.getParentCount(), commits.recordCount);
			querySetCell(commits, "shortmessage", commit.getShortMessage(), commits.recordCount);
			querySetCell(commits, "type", commit.getType(), commits.recordCount);
		} // if next
	} // for n
	return commits;
} // queryFromLog

private void function logAny(required any type, required any data) {
	lock scope="Application" type="exclusive" timeout="5" {
		arrayAppend(application[variables.appKey][arguments.type & "Log"], duplicate(arguments.data));
		while (arrayLen(application[variables.appKey][arguments.type & "Log"]) gt 5) {
			arrayDeleteAt(application[variables.appKey][arguments.type & "Log"], 1);
		} // while
	} // lock
} // logThing

private void function logWatch(required struct data) {
	logAny("watch", arguments.data);
} // logChat

private void function logCatch(required any data) {
	logAny("catch", arguments.data);
} // logChat


public void function onAdd(required struct cfEvent) {
	logWatch(arguments.cfEvent);
	fileChanged(arguments.cfEvent.data.fileName, arguments.cfEvent.data.lastModified, arguments.cfEvent.data.type);
} // onAdd

public void function onChange(required struct cfEvent) {
	logWatch(arguments.cfEvent);
	fileChanged(arguments.cfEvent.data.fileName, arguments.cfEvent.data.lastModified, arguments.cfEvent.data.type);
} // onAdd

public void function onDelete(required struct cfEvent) {
	logWatch(arguments.cfEvent);
	fileChanged(arguments.cfEvent.data.fileName, now(), arguments.cfEvent.data.type);
} // onAdd

}
