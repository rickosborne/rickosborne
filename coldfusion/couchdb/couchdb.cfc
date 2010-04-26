<cfcomponent hint="I interface with a CouchDB service">

<cfset Variables.couchHost = "localhost">
<cfset Variables.couchPort = 5984>
<cfset Variables.couchDB = "">
<cfset Variables.couchDBURL = "">
<cfset Variables.activityLog = arrayNew(1)>
<cfset Variables.couchUser = "">
<cfset Variables.couchPassword = "">

<cffunction name="init" access="public" returntype="component">
	<cfargument name="hostName" type="string" required="true" default="localhost">
	<cfargument name="portNumber" type="numeric" required="true" default="5984">
	<cfargument name="userName" type="string" required="true" default="">
	<cfargument name="password" type="string" required="true" default="">
	<cfset Variables.couchHost     = Arguments.hostName>
	<cfset Variables.couchPort     = Arguments.portNumber>
	<cfset Variables.couchUser     = Arguments.userName>
	<cfset Variables.couchPassword = Arguments.password>
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

<cffunction name="attachmentFromName" access="public" returntype="any">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="fileName" type="string" required="true">
	<cfset var attach = $request(
		path = Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "/" & urlEncodedFormat(Arguments.fileName),
		default = ""
	)>
	<cfif isInstanceOf(attach, "java.io.ByteArrayOutputStream")>
		<cfset attach = attach.toByteArray()>
	</cfif>
	<cfreturn attach>
</cffunction>

<cffunction name="docAttachmentsQuery" access="public" returntype="query">
	<cfargument name="doc" type="struct" required="true">
	<cfset var q = queryNew("filename,content_type,length,revpos,stub,data")>
	<cfset var d = Arguments.doc>
	<cfset var f = 0>
	<cfset var col = 0>
	<cfset var s = 0>
	<cfset var a = 0>
	<cfif structKeyExists(d, "_attachments") and isStruct(d._attachments)>
		<cfset a = d._attachments>
		<cfloop collection="#a#" item="f">
			<cfif isStruct(a[f])>
				<cfset s = a[f]>
				<cfset queryAddRow(q)>
				<cfset querySetCell(q, "filename", f, q.recordCount)>
				<cfloop list="#q.columnList#" index="col">
					<cfif structKeyExists(s, col)>
						<cfset querySetCell(q, col, s[col], q.recordCount)>
					</cfif>
				</cfloop>
			</cfif>
		</cfloop>
	</cfif>
	<cfreturn q>
</cffunction>

<cffunction name="attachmentInsert" access="public" returntype="struct">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="fileName" type="string" required="true">
	<cfargument name="contentType" type="string" required="true">
	<cfargument name="data" type="any" required="true">
	<cfargument name="_rev" type="string" required="false" default="">
	<cfset var path = Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "/" & urlEncodedFormat(Arguments.fileName)>
	<cfif structKeyExists(Arguments, "_rev")>
		<cfset path = path & "?rev=" & urlEncodedFormat(Arguments._rev)>
	</cfif>
	<cfreturn $request(
		path = path,
		method = "PUT",
		contentType = Arguments.contentType,
		body = Arguments.data
	)>
</cffunction>

<cffunction name="attachmentUpdate" access="public" returntype="struct">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="fileName" type="string" required="true">
	<cfargument name="contentType" type="string" required="true">
	<cfargument name="data" type="any" required="true">
	<cfargument name="_rev" type="string" required="true">
	<cfreturn $request(
		path = Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "/" & urlEncodedFormat(Arguments.fileName) & "?rev=" & urlEncodedFormat(Arguments._rev),
		method = "PUT",
		contentType = Arguments.contentType,
		body = Arguments.data
	)>
</cffunction>

<cffunction name="attachmentDelete" access="public" returntype="struct">
	<cfargument name="_id" type="string" required="true">
	<cfargument name="fileName" type="string" required="true">
	<cfargument name="_rev" type="string" required="true">
	<cfreturn $request(
		path = Variables.couchDBURL & urlEncodedFormat(Arguments._id) & "/" & urlEncodedFormat(Arguments.fileName) & "?rev=" & urlEncodedFormat(Arguments._rev),
		method = "DELETE"
	)>
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

<cffunction name="viewAllDocs" access="public" returntype="struct">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKey" type="any" required="false">
	<cfargument name="endKey" type="any" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="includeDocs" type="boolean" required="false" default="false">
	<cfset Arguments.viewName = "_all_docs">
	<cfif structKeyExists(Arguments, "startKey")>
		<cfset Arguments.startKeyAny = Arguments.startKey>
	</cfif>
	<cfif structKeyExists(Arguments, "endKey")>
		<cfset Arguments.endKeyAny = Arguments.endKey>
	</cfif>
	<cfreturn $view(argumentCollection = Arguments)>
</cffunction>

<cffunction name="viewAllDocsBySeq" access="public" returntype="struct">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKey" type="numeric" required="false">
	<cfargument name="endKey" type="numeric" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="includeDocs" type="boolean" required="false" default="false">
	<cfset Arguments.viewName = "_all_docs_by_seq">
	<cfif structKeyExists(Arguments, "startKey")>
		<cfset Arguments.startKeyInt = Arguments.startKey>
	</cfif>
	<cfif structKeyExists(Arguments, "endKey")>
		<cfset Arguments.endKeyInt = Arguments.endKey>
	</cfif>
	<cfreturn $view(argumentCollection = Arguments)>
</cffunction>

<cffunction name="viewAllDocsQuery" access="public" returntype="query">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKey" type="any" required="false">
	<cfargument name="endKey" type="any" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="includeDocs" type="boolean" required="false" default="false">
	<cfreturn $viewQuery(viewAllDocs(argumentCollection = Arguments))>
</cffunction>

<cffunction name="viewAllDocsBySeqQuery" access="public" returntype="query">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKey" type="numeric" required="false">
	<cfargument name="endKey" type="numeric" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="includeDocs" type="boolean" required="false" default="false">
	<cfreturn $viewQuery(viewAllDocsBySeq(argumentCollection = Arguments))>
</cffunction>

<cffunction name="viewCleanup" access="public" returntype="struct">
	<cfreturn $request(
		path = Variables.couchDBURL & "_view_cleanup",
		method = "POST"
	)>
</cffunction>

<cffunction name="viewCompact" access="public" returntype="struct">
	<cfargument name="viewName" type="string" required="true">
	<cfreturn $request(
		path = Variables.couchDBURL & "_compact/" & urlEncodedFormat(Arguments.viewName),
		method = "POST"
	)>
</cffunction>

<cffunction name="viewDesign" access="public" returntype="any">
	<cfargument name="viewName" type="string" required="true">
	<cfargument name="functionName" type="string" required="true">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKey" type="any" required="false">
	<cfargument name="endKey" type="any" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="includeDocs" type="boolean" required="false" default="false">
	<cfargument name="keys" type="array" required="false">
	<cfargument name="group" type="boolean" required="false">
	<cfargument name="groupLevel" type="numeric" required="false">
	<cfargument name="reduce" type="boolean" required="false">
	<cfif left(Arguments.viewName,8) neq "_design/">
		<cfset Arguments.viewName = "_design/" & Arguments.viewName>
	</cfif>
	<cfset Arguments.viewName = Arguments.viewName & "/_view/" & urlEncodedFormat(Arguments.functionName)>
	<cfif structKeyExists(Arguments, "keys")>
		<cfset Arguments.method = "POST">
		<cfset Arguments.viewData = structNew()>
		<cfset Arguments.viewData["keys"] = Arguments.keys>
	</cfif>
	<cfif structKeyExists(Arguments, "startKey")>
		<cfset Arguments.startKeyAny = Arguments.startKey>
	</cfif>
	<cfif structKeyExists(Arguments, "endKey")>
		<cfset Arguments.endKeyAny = Arguments.endKey>
	</cfif>
	<cfreturn $view(argumentCollection = Arguments)>
</cffunction>

<cffunction name="queryFromResults" access="public" returntype="query">
	<cfargument name="results" type="struct" required="true">
	<cfargument name="followStructs" type="numeric" required="false" default="0">
	<cfargument name="columnTypes" type="struct" required="false" default="#structNew()#">
	<cfset var q = queryNew("")>
	<cfset var cols = structNew()>
	<cfset var key = 0>
	<cfset var row = 0>
	<cfset var depth = 0>
	<cfif structKeyExists(Arguments.results, "rows") and isArray(Arguments.results.rows) and arrayLen(Arguments.results.rows)>
		<cfif structKeyExists(Arguments.results.rows[1], "key")>
			<cfif isArray(Arguments.results.rows[1].key)>
				<cfloop from="1" to="#arrayLen(Arguments.results.rows[1].key)#" index="key">
					<cfset queryAddColumn(q, "key" & key, arrayNew(1))>
					<cfset cols["key" & key] = true>
				</cfloop>
			<cfelse>
				<cfset queryAddColumn(q, "key", arrayNew(1))>
				<cfset cols.key = true>
			</cfif>
		</cfif>
		<cfloop array="#Arguments.results.rows#" index="row">
			<cfif isStruct(row)>
				<cfset queryAddRow(q)>
				<cfif structKeyExists(row, "id")>
					<cfif not structKeyExists(cols, "id")>
						<cfset queryAddColumn(q, "id", arrayNew(1))>
						<cfset cols.id = true>
					</cfif>
					<cfset querySetCell(q, "id", row.id, q.recordCount)>
				</cfif>
				<cfif structKeyExists(row, "key")>
					<cfif isArray(row.key)>
						<cfloop from="1" to="#arrayLen(row.key)#" index="key">
							<cfset querySetCell(q, "key" & key, row.key[key], q.recordCount)>
						</cfloop>
					<cfelse>
						<cfset querySetCell(q, "key", row.key, q.recordCount)>
					</cfif>
				</cfif>
				<cfif structKeyExists(row, "value")>
					<cfif isStruct(row.value)>
						<cfset $queryFollowStruct(q, cols, Arguments.columnTypes, row.value, "", 0, Arguments.followStructs)>
					<cfelse>
						<cfif not structKeyExists(cols, "value")>
							<cfset queryAddColumn(q, "value", arrayNew(1))>
							<cfset cols["value"] = true>
						</cfif>
						<cfset querySetCell(q, "value", row.value, q.recordCount)>
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfreturn q>
</cffunction>

<cffunction name="$queryFollowStruct" access="private" returntype="void">
	<cfargument name="query" type="query" required="true">
	<cfargument name="cols" type="struct" required="true">
	<cfargument name="colTypes" type="struct" required="true">
	<cfargument name="struct" type="struct" required="true">
	<cfargument name="prefix" type="string" required="true">
	<cfargument name="depth" type="numeric" required="true">
	<cfargument name="maxDepth" type="numeric" required="true">
	<cfset var col = 0>
	<cfset var newCol = 0>
	<cfset var s = Arguments.struct>
	<cfset var v = 0>
	<cfloop collection="#s#" item="col">
		<cfset v = s[col]>
		<cfset newCol = Arguments.prefix & col>
		<cfif isStruct(v) and (Arguments.depth lt Arguments.maxDepth)>
			<cfset $queryFollowStruct(Arguments.query, Arguments.cols, Arguments.colTypes, v, newCol, Arguments.depth + 1, Arguments.maxDepth)>
		<cfelseif isSimpleValue(v) or (Arguments.maxDepth gt -1)>
			<cfif not structKeyExists(Arguments.cols, newCol)>
				<cfset Arguments.cols[newCol] = true>
				<cfif structKeyExists(Arguments.colTypes, newCol)>
					<cfset queryAddColumn(Arguments.query, newCol, arrayNew(1), Arguments.colTypes[newCol])>
				<cfelse>
					<cfset queryAddColumn(Arguments.query, newCol, arrayNew(1))>
				</cfif>
			</cfif>
			<cfset querySetCell(Arguments.query, newCol, v, Arguments.query.recordCount)>
		</cfif>
	</cfloop>
</cffunction>

<cffunction name="viewActiveTasks" access="public" returntype="any">
	<cfreturn $request("_active_tasks")>
</cffunction>

<cffunction name="docViewsQuery" access="public" returntype="query">
	<cfreturn viewAllDocsQuery(
		startKey = "_design",
		endKey = "_design0",
		includeDocs = true
	)>
</cffunction>

<cffunction name="viewTemporary" access="public" returntype="struct">
	<cfargument name="viewData" type="struct" required="true">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKey" type="any" required="false">
	<cfargument name="endKey" type="any" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="includeDocs" type="boolean" required="false" default="false">
	<cfset var ret = structNew()>
	<cfset var args = structCopy(Arguments)>
	<cfif structKeyExists(Arguments.viewData, "map") and isSimpleValue(Arguments.viewData.map)>
		<cfset args.viewName = "_temp_view">
		<cfset args.method = "POST">
		<cfset ret = $view(argumentCollection = args)>
	</cfif>
	<cfreturn ret>
</cffunction>

<cffunction name="$viewQuery" access="private" returntype="query">
	<cfargument name="docs" type="struct" required="true">
	<cfset var q = queryNew("id,key,rev,deleted", "VarChar,VarChar,VarChar,Bit")>
	<cfset var rows = 0>
	<cfset var col = "">
	<cfset queryAddColumn(q, "doc", arrayNew(1))>
	<cfif structKeyExists(Arguments.docs, "rows") and isArray(Arguments.docs.rows)>
		<cfloop array="#Arguments.docs.rows#" index="row">
			<cfif isStruct(row)>
				<cfset queryAddRow(q)>
				<cfloop list="doc,id,key" index="col">
					<cfif structKeyExists(row, col)>
						<cfset querySetCell(q, col, row[col], q.recordCount)>
					</cfif>
				</cfloop>
				<cfif structKeyExists(row, "value") and isStruct(row.value)>
					<cfloop list="deleted,rev" index="col">
						<cfif structKeyExists(row.value, col)>
							<cfset querySetCell(q, col, row.value[col], q.recordCount)>
						</cfif>
					</cfloop>
				</cfif>
			</cfif>
		</cfloop>
	</cfif>
	<cfreturn q>
</cffunction>

<cffunction name="$trueFalseFormat" access="private" returntype="string">
	<cfargument name="bool" type="boolean" required="true">
	<cfif Arguments.bool>
		<cfreturn "true">
	<cfelse>
		<cfreturn "false">
	</cfif>
</cffunction>

<cffunction name="$view" access="private" returntype="struct">
	<cfargument name="viewName" type="string" required="true">
	<cfargument name="descending" type="boolean" required="false" default="false">
	<cfargument name="startKeyAny" type="any" required="false">
	<cfargument name="endKeyAny" type="any" required="false">
	<cfargument name="startKeyInt" type="numeric" required="false">
	<cfargument name="endKeyInt" type="numeric" required="false">
	<cfargument name="limit" type="numeric" required="false">
	<cfargument name="viewData" type="struct" required="false">
	<cfargument name="method" type="string" required="false" default="GET">
	<cfargument name="group" type="boolean" required="false">
	<cfargument name="groupLevel" type="numeric" required="false">
	<cfargument name="reduce" type="boolean" required="false">
	<cfset var path = Variables.couchDBURL & Arguments.viewName & "?">
	<cfset var args = structNew()>
	<cfif Arguments.descending>
		<cfset path = path & "&descending=true">
	</cfif>
	<cfif structKeyExists(Arguments, "startKeyInt")>
		<cfset path = path & "&startkey=" & int(Arguments.startKey)>
	<cfelseif structKeyExists(Arguments, "startKeyAny")>
		<cfset path = path & "&startkey=" & urlEncodedFormat(serializeJSON(Arguments.startKey))>
	</cfif>
	<cfif structKeyExists(Arguments, "endKeyInt")>
		<cfset path = path & "&endkey=" & int(Arguments.endKey)>
	<cfelseif structKeyExists(Arguments, "endKeyAny")>
		<cfset path = path & "&endkey=" & urlEncodedFormat(serializeJSON(Arguments.endKey))>
	</cfif>
	<cfif structKeyExists(Arguments, "limit") and isNumeric(Arguments.limit)>
		<cfset path = path & "&limit=" & int(Arguments.limit)>
	</cfif>
	<cfif Arguments.includeDocs>
		<cfset path = path & "&include_docs=true">
	</cfif>
	<cfif structKeyExists(Arguments, "group")>
		<cfset path = path & "&group=" & $trueFalseFormat(Arguments.group)>
		<cfif structKeyExists(Arguments, "groupLevel")>
			<cfset path = path & "&group_level=" & int(Arguments.groupLevel)>
		</cfif>
	</cfif>
	<cfif structKeyExists(Arguments, "reduce")>
		<cfset path = path & "&reduce=" & $trueFalseFormat(Arguments.reduce)>
	</cfif>
	<cfif structKeyExists(Arguments, "inclusiveEnd")>
		<cfset path = path & "&inclusive_end=" & $trueFalseFormat(Arguments.inclusiveEnd)>
	</cfif>
	<cfset args.path = path>
	<cfset args.method = Arguments.method>
	<cfif structKeyExists(Arguments, "viewData")>
		<cfset args.body = Arguments.viewData>
	</cfif>
	<cfreturn $request(argumentCollection = args)>
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
	<cfargument name="contentType" type="string" required="false" default="application/json">
	<cfset var ret = Arguments.default>
	<cfset var fetch = 0>
	<cfset var args = structNew()>
	<cfset args.method = Arguments.method>
	<cfset args.url = "http://#Variables.couchHost#:#Variables.couchPort#/#Arguments.Path#">
	<cfset args.timeout = Arguments.timeout>
	<cfset args.result = "fetch">
	<cfif (Variables.couchUser neq "")>
		<cfset args.username = Variables.couchUser>
		<cfset args.password = Variables.couchPassword>
	</cfif>
	<cfset arrayAppend(Variables.activityLog, args.method & " " & args.url)>
	<!---<cfif structKeyExists(Arguments, "body") and isBinary(Arguments.body)>
		<cfset args.charSet = "us-ascii">
	</cfif>--->
	<cftry>
		<cfhttp attributeCollection="#args#">
			<cfif (Arguments.method eq "POST") or (Arguments.method eq "PUT")>
				<cfhttpparam type="header" name="Content-Type" value="#Arguments.contentType#">
				<cfif (not isSimpleValue(Arguments.body)) or (Arguments.body neq "")>
					<cfif Arguments.contentType eq "application/json">
						<cfhttpparam type="body" value="#serializeJSON(Arguments.body)#">
					<cfelseif isBinary(Arguments.body)>
						<cfhttpparam type="body" value="#Arguments.body#">
					</cfif>
				</cfif>
			<cfelseif (Arguments.method eq "COPY")>
				<cfif structKeyExists(Arguments.body, "_rev")>
					<cfhttpparam type="header" name="Destination" value="#Arguments.body._id#?rev=#Arguments.body._rev#">
				<cfelse>
					<cfhttpparam type="header" name="Destination" value="#Arguments.body._id#">
				</cfif>
			</cfif>
		</cfhttp>
		<cfif isSimpleValue(Arguments.default)>
			<cfset ret = fetch.fileContent>
		<cfelseif isJson(fetch.fileContent)>
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