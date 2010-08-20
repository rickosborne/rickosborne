<cfcomponent>

<cffunction name="echoArgs" access="remote" type="struct">
	<cfif structKeyExists(URL, "returnFormat") and (URL.returnFormat eq "json")>
		<cfcontent type="application/json" reset="true">
	</cfif>
	<cfreturn structCopy(arguments)>
</cffunction>

</cfcomponent>