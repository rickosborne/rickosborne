<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfscript>
Application.View
	.showHeader("Home", structKeyExists(Session, "user") ? Session.user : {})
	.showHomePage()
	.showFooter();
</cfscript>
