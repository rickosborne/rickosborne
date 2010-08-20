<cfsetting enablecfoutputonly="true">

<cfscript>
writeDump(
	createObject("component", "amfClient")
		.init()
		.callCfcMethod(
			listChangeDelims(getDirectoryFromPath(CGI.SCRIPT_NAME), ".", "/") & ".amftest",
			"echoArgs",
			{ "message" = "I like turtles" }
		)
);
</cfscript>