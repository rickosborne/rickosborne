<cfsetting enablecfoutputonly="true">

<cfscript>
writeDump(
	createObject("component", "amfClient")
		.init("https://www.adidas.com/com/micoach/Gateway.aspx", "fluorine", "38cf965d-ae8f-4a81-9540-1edcfdb35d63")
		.callCfcMethod(
			"Molecular.AdidasCoach.Web.Services.UserProfileWS",
			"Login",
			[ "email", "password" ]
		)
		.toString()
);
</cfscript>