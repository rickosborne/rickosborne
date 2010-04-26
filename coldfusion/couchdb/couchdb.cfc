<cfcomponent hint="I interface with a CouchDB service">

<cfset Variables.couchHost = "localhost">
<cfset Variables.couchPort = 5984>
<cfset Variables.couchDB = "">
<cfset Variables.couchDBURL = "">

<cffunction name="init" access="public" returntype="component">
	<cfargument name="hostName" type="string" required="true" default="localhost">
	<cfargument name="portNumber" type="numeric" required="true" default="5984">
	<cfset Variables.couchHost  = Arguments.hostName>
	<cfset Variables.couchPort  = Arguments.portNumber>
	<cfreturn this>
</cffunction>

<cffunction name="db" access="public" returntype="struct">
	<cfargument name="database" type="string" required="true">
	<cfset var dbInfo = $request(urlEncodedFormat(Arguments.database))>
	<cfif isStruct(dbInfo) and structKeyExists(dbInfo, "db_name")>
		<cfset Variables.couchDB    = Arguments.database>
		<cfset Variables.couchDBURL = urlEncodedFormat(Arguments.database) & "/">
	</cfif>
	<cfreturn dbInfo>
</cffunction>

<cffunction name="welcome" access="public" returntype="struct">
	<cfreturn $request("", structNew(), "GET")>
</cffunction>

<cffunction name="version" access="public" returntype="string">
	<cfset var wel = welcome()>
	<cfif structKeyExists(wel, "version") and isSimpleValue(wel.version)>
		<cfreturn wel.version>
	</cfif>
	<cfreturn "">
</cffunction>

<cffunction name="docFromId" access="public" returntype="struct">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="_rev" type="string" required="false" default="">
	<cfset var path = Variables.couchDBURL & urlEncodedFormat(arguments._id)>
	<cfif Arguments._rev neq "">
		<cfset path = path & "?rev=" & urlEncodedFormat(arguments._rev)>
	</cfif>
	<cfreturn $request(path)>
</cffunction>

<cffunction name="docRevsInfo" access="public" returntype="struct">
	<cfargument name="_id" type="string" required="true">
	<cfreturn $request(Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "?revs_info=true")>
</cffunction>

<cffunction name="docRevsInfoQuery" access="public" returntype="query">
	<cfargument name="_id" type="string" required="true">
	<cfset var doc = docRevsInfo(Arguments._id)>
	<cfset var history = queryNew("rev,status", "VarChar,VarChar")>
	<cfset var rev = 0>
	<cfif structKeyExists(doc, "_revs_info") and isArray(doc._revs_info)>
		<cfloop array="#doc._revs_info#" index="rev">
			<cfset queryAddRow(history)>
			<cfset querySetCell(history, "rev", rev.rev, history.recordCount)>
			<cfset querySetCell(history, "status", rev.status, history.recordCount)>
		</cfloop>
	</cfif>
	<cfreturn history>
</cffunction>

<cffunction name="docRevs" access="public" returntype="any">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="_revs" type="array" required="false">
	<cfset var openRevs = "all">
	<cfif structKeyExists(Arguments, "_revs") and isArray(Arguments._revs)>
		<cfset openRevs = urlEncodedFormat(serializeJSON(Arguments._revs))>
	</cfif>
	<cfreturn $request(Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "?open_revs=" & openRevs)>
</cffunction>

<cffunction name="docInsert" access="public" returntype="struct">
	<cfargument name="doc" type="struct" required="true">
	<cfargument name="_id" type="string" required="false" default="">
	<cfargument name="batch" type="boolean" required="false" default="false">
	<cfset var path = Variables.couchDBURL>
	<cfset var id = Arguments._id>
	<cfset var method = "POST">
	<cfif (id eq "") and structKeyExists(Arguments.doc, "_id")>
		<cfset id = Arguments.doc._id>
	</cfif>
	<cfif id neq "">
		<cfset Arguments.doc["_id"] = id>
		<cfset path = path & urlEncodedFormat(id)>
		<cfset method = "PUT">
	</cfif>
	<cfif Arguments.batch>
		<cfset path = path & "?batch=ok">
	</cfif>
	<cfreturn $request(
		path   = path,
		body   = Arguments.doc,
		method = method
	)>
</cffunction>

<cffunction name="docUpdate" access="public" returntype="struct">
	<cfargument name="doc" type="struct" required="true">
	<cfargument name="_id" type="string" required="false" default="#Arguments.doc._id#">
	<cfargument name="_rev" type="string" required="false" default="#Arguments.doc._rev#">
	<cfargument name="batch" type="boolean" required="false" default="false">
	<cfif not structKeyExists(Arguments.doc, "_rev")>
		<cfset Arguments.doc["_rev"] = Arguments._rev>
	</cfif>
	<cfreturn docInsert(argumentCollection = Arguments)>
</cffunction>

<cffunction name="docDelete" access="public" returntype="struct">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="_rev" type="string" required="true">
	<cfreturn $request(
		path = Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "?rev=" & urlEncodedFormat(Arguments._rev),
		method = "DELETE"
	)>
</cffunction>

<cffunction name="docCopy" access="public" returntype="struct">
	<cfargument name="sourceId" type="string" required="true">
	<cfargument name="destinationId" type="string" required="true">
	<cfargument name="destinationRev" type="string" required="false">
	<cfset var body = structNew()>
	<cfset body["_id"] = Arguments.sourceId>
	<cfif structKeyExists(Arguments, "destinationRev") and (Arguments.destinationRev neq "")>
		<cfset body["_rev"] = Arguments.destinationRev>
	</cfif>
	<!---
	cfhttp doesn't support using the COPY method
	<cfreturn $request (
		path = Variables.couchDBURL & urlEncodedFormat(Arguments.sourceId),
		method = "COPY",
		body = body
	)>
	--->
	<cfreturn structNew()>
</cffunction>

<cffunction name="vars" access="public" returntype="Struct">
	<cfreturn variables>
</cffunction>

<cffunction name="$request" access="private" returntype="Any">
	<cfargument name="path" type="string" required="true">
	<cfargument name="default" type="any" required="false" default="#structNew()#">
	<cfargument name="body" type="any" required="false" default="">
	<cfargument name="method" type="string" required="false" default="GET">
	<cfargument name="timeout" type="numeric" required="false" default="5">
	<cfset var ret = Arguments.default>
	<cfset var fetch = 0>
	<cfset var httpURL = "http://#Variables.couchHost#:#Variables.couchPort#/#Arguments.Path#">
	<cfset Variables.lastHttpUrl = httpUrl>
	<cftry>
		<cfhttp method="#Arguments.Method#" url="#httpUrl#" timeout="#Arguments.timeout#" result="fetch">
			<cfif (Arguments.method eq "POST") or (Arguments.method eq "PUT")>
				<cfhttpparam type="header" name="Content-Type" value="application/json">
				<cfif (not isSimpleValue(Arguments.body)) or (Arguments.body neq "")>
					<cfhttpparam type="body" value="#serializeJSON(Arguments.body)#">
				</cfif>
			<cfelseif (Arguments.method eq "COPY")>
				<cfif structKeyExists(Arguments.body, "_rev")>
					<cfhttpparam type="header" name="Destination" value="#Arguments.body._id#?rev=#Arguments.body._rev#">
				<cfelse>
					<cfhttpparam type="header" name="Destination" value="#Arguments.body._id#">
				</cfif>
			</cfif>
		</cfhttp>
		<cfif isJson(fetch.fileContent)>
			<cfset ret = deserializeJSON(fetch.fileContent)>
		<cfelseif isStruct(ret)>
			<cfset ret["cferror"] = "Not JSON">
			<cfset ret["cfhttpstatus"] = fetch.statusCode>
			<cfset ret["cfhttpcontent"] = fetch.fileContent>
		</cfif>
	<cfcatch>
		<cfif isStruct(ret)>
			<cfset ret["cferror"] = cfcatch.message>
			<cfset ret["cfdetail"] = cfcatch.detail>
		</cfif>
	</cfcatch>
	</cftry>
	<cfreturn ret>
</cffunction>

</cfcomponent>