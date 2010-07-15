<cfsetting enablecfoutputonly="true" requesttimeout="600">

<cfset thisPage=CGI.SCRIPT_NAME>
<cfparam name="URL.dsn" default="" type="string">
<cfparam name="URL.db" default="" type="string">
<cfparam name="URL.table" default="" type="string">
<cfparam name="URL.couchHost" default="" type="string">
<cfparam name="URL.couchPort" default="" type="string">
<cfparam name="URL.couchUser" default="" type="string">
<cfparam name="URL.couchPass" default="" type="string">
<cfparam name="URL.couchDb" default="" type="string">
<cfparam name="URL.maxRows" default="0" type="string">
<cfset dsn = trim(URL.dsn)>
<cfset dbName = trim(URL.db)>
<cfset tableName = trim(URL.table)>
<cfset couchHost = trim(URL.couchHost)>
<cfset couchPort = trim(URL.couchPort)>
<cfset couchUser = trim(URL.couchUser)>
<cfset couchPass = trim(URL.couchPass)>
<cfset couchDb = trim(URL.couchDb)>
<cfset maxRows = trim(URL.maxRows)>

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Relational Table to Couch Document Converter</title>
</head>
<body></cfoutput>

<cfif (couchHost eq "") or (couchPort eq "")>
	<cfoutput>
<cfform action="#thisPage#" method="get">
	<label for="couchHost">CouchDB Host:</label> <cfinput type="text" size="32" name="couchHost" id="couchHost" required="true" validate="regular_expression" pattern="^([-a-zA-Z0-9]+.)*[-a-zA-Z0-9]+$" message="Please input a valid hostname"> <br />
	<label for="couchPort">CouchDB Port:</label> <cfinput type="text" size="6" name="couchPort" id="couchPort" required="true" validate="integer" message="Please input a valid port number" value="5984"> <br />
	<label for="couchUser">CouchDB User:</label> <cfinput type="text" size="32" name="couchUser" id="couchUser"> <br />
	<label for="couchPass">CouchDB Pass:</label> <cfinput type="password" size="32" name="couchPass" id="couchPass"> <br />
	<input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (couchDb eq "")>
	<cfset dbs = new CouchDB(couchHost, couchPort, couchUser, couchPass).allDbs()>
	<cfoutput>
<p>Choose a target CouchDB database:</p>
<ul>
	<cfloop array="#dbs#" index="couchDb">
	<li><a href="#thisPage#?#CGI.QUERY_STRING#&amp;couchDb=#htmlEditFormat(couchDb)#">#htmlEditFormat(couchDb)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelseif (dsn eq "")>
	<!---<cfset createObject("component","cfide.adminapi.administrator").login("your admin password")>--->
	<cfset sources = CreateObject("component","cfide.adminapi.datasource").getDatasources()>
	<cfoutput>
<p>Choose a datasource:</p>
<ul>
	<cfloop collection="#sources#" item="key">
	<li><a href="#thisPage#?#CGI.QUERY_STRING#&amp;dsn=#htmlEditFormat(sources[key].name)#">#htmlEditFormat(sources[key].name)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelseif (dbName eq "")>
	<cfdbinfo datasource="#dsn#" name="dbNames" type="dbnames">
	<cfoutput>
<p>Choose a database:</p>
<ul>
	<cfloop query="dbNames">
	<li><a href="#thisPage#?#CGI.QUERY_STRING#&amp;db=#htmlEditFormat(dbNames.database_name)#">#htmlEditFormat(dbNames.database_name)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelseif (tableName eq "")>
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" name="tableNames" type="tables">
	<cfquery name="tableNames" dbtype="query">
	SELECT * FROM tableNames WHERE table_type <> 'SYSTEM_TABLE'
	</cfquery>
	<cfoutput>
<p>Choose a table:</p>
<ul>
	<cfloop query="tableNames">
	<li><a href="#thisPage#?#CGI.QUERY_STRING#&amp;table=#htmlEditFormat(tableNames.table_name)#">#htmlEditFormat(tableNames.table_name)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelse>
	<cfset couch = new CouchDB(couchHost, couchPort, couchUser, couchPass)>
	<cfset couch.db(couchDb)>
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#tableName#" name="foreign" type="foreignkeys">
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#tableName#" name="columns" type="columns">
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#tableName#" name="indexes" type="index">
	<cfquery name="primary" dbtype="query">
	SELECT column_name, type_name FROM columns WHERE is_primarykey = 'YES' ORDER BY ordinal_position
	</cfquery>
	<cfquery name="example" datasource="#dsn#" maxrows="#max(1,maxRows)#">
	SELECT * FROM #dbName#.#tableName#
	</cfquery>
	<cffunction name="singularify" returntype="string">
		<cfargument name="word" type="string" required="true">
		<cfreturn lcase(listLast(((right(arguments.word, 1) eq "s") and (right(arguments.word, 2) neq "ss")) ? (right(arguments.word, 3) eq "ies") ? left(arguments.word, len(arguments.word) - 3) & "y" : left(arguments.word, len(arguments.word) - 1) : arguments.word, "_"))>
	</cffunction>
	<cffunction name="prettyDate" returntype="string">
		<cfargument name="d" type="string" required="true">
		<cfreturn dateFormat(d, "yyyy-mm-dd") & "T" & timeFormat(d, "HH:mm:ss") & "Z">
	</cffunction>
	<cffunction name="fieldFromColumn" returntype="string">
		<cfargument name="col" type="string" required="true">
		<cfreturn lcase(replace((right(col, 3) eq "_id") and (len(col) gt 3) ? left(col, len(col) - 3) : col, "_", "", "ALL"))>
	</cffunction>
	<cffunction name="couchSave" returntype="void">
		<cfargument name="data" type="struct" required="true">
		<cfargument name="overwrite" type="boolean" default="false">
		<cfset doc = couch.docFromId(arguments.data["_id"])>
		<cfif structKeyExists(doc, "_id") and (not overwrite)>
			<cfoutput><p>Skipping #htmlEditFormat(data["_id"])#.</p></cfoutput>
		<cfelseif structKeyExists(doc, "_rev")>
			<cfset data["_rev"] = doc["_rev"]>
			<cfset rev = couch.docUpdate(data)>
			<cfif structKeyExists(rev, "rev") and structKeyExists(rev, "id")>
				<cfoutput><p>Updated #rev.id# as #rev.rev#.</p></cfoutput>
			<cfelse>
				<cfdump var="#rev#" label="#data['_id']#">
			</cfif>
		<cfelse>
			<cfset rev = couch.docInsert(data)>
			<cfif structKeyExists(rev, "rev") and structKeyExists(rev, "id")>
				<cfoutput><p>Inserted #rev.id# as #rev.rev#.</p></cfoutput>
			<cfelse>
				<cfdump var="#rev#" label="#data['_id']#">
			</cfif>
		</cfif>
	</cffunction>
	<cfset singleName = singularify(tableName)>
	<cfset colMap = {}>
	<cfset pkMap = {}>
	<cfset rowFromCol = {}>
	<cfset crlf = chr(13) & chr(10)>
	<cfset tab = chr(9)>
	<cfset cfc = 'component extends="CouchDBDocument" accessors="true" {' & crlf>
	<cfset typeFromDB = {
		"BIT"       = "boolean",
		"BIGINT"    = "numeric",
		"CHAR"      = "string",
		"DATETIME"  = "date",
		"DECIMAL"   = "numeric",
		"ENUM"      = "string",
		"INT"       = "numeric",
		"LONGTEXT"  = "string",
		"SMALLINT"  = "numeric",
		"TEXT"      = "string",
		"TIMESTAMP" = "date",
		"TINYINT"   = "numeric",
		"TINYTEXT"  = "string",
		"VARCHAR"   = "string"
	}>
	<cfset colPrefix = " ">
	<cfif (primary.recordCount eq 1) and (right(primary.column_name, 3) eq "_id") and (len(primary.column_name) gt 3)>
		<cfset colPrefix = left(primary.column_name, len(primary.column_name) - 3)>
	</cfif>
	<cfloop query="columns">
		<cfset rowFromCol[column_name] = currentRow>
		<cfif singleName eq left(column_name, len(singleName))>
			<cfset fieldName = fieldFromColumn(mid(column_name, len(singleName) + 1, len(column_name)))>
		<cfelseif (left(column_name, len(colPrefix)) eq colPrefix) and (len(colPrefix) lt len(column_name))>
			<cfset fieldName = fieldFromColumn(mid(column_name, len(colPrefix) + 1, len(column_name)))>
		<cfelse>
			<cfset fieldName = fieldFromColumn(column_name)>
		</cfif>
		<cfset colMap[column_name] = fieldName>
		<cfif (referenced_primarykey_table neq "n/a")>
			<cfset pkMap[column_name] = singularify(listLast(referenced_primarykey_table, "_"))>
		</cfif>
		<cfset cfType = typeFromDB[listFirst(type_name," ")]>
		<cfset prop = tab & 'property name="#fieldName#" type="#cfType#" default="#column_default_value#" notnull="' & (is_nullable eq "yes" ? "false" : "true") & '" required="' & (is_nullable eq "yes" ? "false" : "true") & '"'>
		<cfif (type_name CONTAINS "char")>
			<cfset prop &= ' length="#column_size#"'>
		</cfif>
		<cfif type_name CONTAINS "decimal">
			<cfset prop &= ' precision="#decimal_digits#"'>
		</cfif>
		<cfif (is_primarykey eq "yes")>
			<cfset prop &= ' fieldtype="id"'>
		</cfif>
		<cfset prop &= ";" & crlf>
		<cfset cfc &= prop>
	</cfloop>
	<cffunction name="makeView" returntype="struct">
		<cfargument name="docType" type="string" required="true">
		<cfargument name="viewName" type="string" required="true">
		<cfargument name="colNames" type="string" required="true">
		<cfargument name="dataType" type="string" required="false" default="">
		<cfset var ixColumns = listToArray(arguments.colNames, ", ")>
		<cfset var less = "<">
		<cfset var viewurl = "">
		<cfset var sql = "">
		<cfset var info = "">
		<cfsavecontent variable="local.viewjs"><cfoutput>
function (doc) {
	if (doc.Type === '#jsStringFormat(arguments.docType)#') {
		<cfif (arguments.colNames eq "")>
			<cfset info = "Get all documents without using a key">
			<cfset sql = "SELECT * FROM #docType#">
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#">
		emit(null, doc);
		<cfelseif (arrayLen(ixColumns) gt 1)>
			<cfset info = "Fetch documents with a composite key">
			<cfset sql = [
				"SELECT * FROM #docType# WHERE (#listChangeDelims(colNames, " = '...') AND ()")# = '...')",
				"SELECT #colNames#, AGG(...) FROM #docType# GROUP BY #colNames#"
			]>
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#?startKey=[val#repeatString(',val',arrayLen(ixColumns)-1)#]&endKey=[#repeatString(',val',arrayLen(ixColumns)-1)#]">
		emit([
			<cfloop from="1" to="#arrayLen(ixColumns)#" index="local.ixColNum">
				<cfif (ixColNum gt 1)>, </cfif>
				doc.#colMap[trim(ixColumns[ixColNum])]#
			</cfloop>
		], doc);
		<cfelseif (not structKeyExists(colMap, ixColumns[1]))>
			<cfset info = "Fetch related documents, as with an inner join">
			<cfset sql = "SELECT #ixColumns[1]#.* FROM #ixColumns[1]# INNER JOIN #docType# ON (...) WHERE (_id = :_id)">
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#?startKey='#docType#:_id'&endKey='#docType#:_id'&include_docs=true">
			<cfif (arguments.dataType eq "array")>
		for (var i = 0; i #less# doc.#ixColumns[1]#.length; i++) {
			emit(doc._id, { '_id': doc.#ixColumns[1]#[i] });
		}
			<cfelse>
		for (var i in doc.#ixColumns[1]#) {
			emit(doc._id, { '_id': i });
		}
			</cfif>
		<!--- <cfelseif structKeyExists(rowFromCol, ixColumns[1]) and (columns.is_foreignkey[rowFromCol[ixColumns[1]]] eq "yes")>
		emit(doc.#colMap[ixColumns[1]]#, { '_id': doc.#colMap[ixColumns[1]]#}); --->
		<cfelse>
			<cfset info = "Get documents by a single field">
			<cfset sql = "SELECT * FROM #docType# WHERE #ixColumns[1]# = :param">
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#?startKey=':param'&endKey=':param'">
		emit(doc.#colMap[ixColumns[1]]#, doc);
		</cfif>
	}
}
		</cfoutput></cfsavecontent>
		<cfset viewjs = reReplace(trim(viewjs), "(#chr(13)##chr(10)#|#chr(13)#|#chr(10)#)[ #chr(9)#]*(#chr(13)##chr(10)#|#chr(13)#|#chr(10)#)", "#chr(13)##chr(10)#", "ALL")> 
		<cfreturn {
			"map"  = viewjs,
			"sql"  = sql,
			"info" = info,
			"url"  = viewurl
		}>
	</cffunction>
	<cfset ixViews = {
		"all" = makeView(singleName, "all", "")
	}>
	<cfloop query="indexes">
		<cfset viewName = lcase(trim(replaceList(indexes.index_name, "IX_,FK_,PK_",",,,")))>
		<cfset ixViews[viewName] = makeView(singleName, viewName, indexes.column_name)>
	</cfloop>
	<cfset fkMap = []>
	<cfset fkFields = { "type" = "type" }>
	<cfloop query="foreign">
		<cfset fieldName = lcase(listLast(foreign.fktable_name, "_"))>
		<cfif structKeyExists(fkFields, fieldName)>
			<cfif isNumeric(fkFields[fieldName])>
				<cfset fkMap[fkFields[fieldName]].field &= "_" & fkMap[fkFields[fieldName]].fcolumn>
				<cfset fkFields[fieldName] = fkMap[fkFields[fieldName]].field>
			</cfif>
			<cfset fieldName &= "_" & foreign.fkcolumn_name>
		</cfif>
		<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#foreign.fktable_name#" name="fkcolumns" type="columns">
		<cfquery name="fkDates" dbtype="query">
		SELECT column_name
		FROM fkcolumns
		WHERE (type_name = 'DATETIME')
		  AND (column_name NOT LIKE '%update%')
		</cfquery>
		<cfquery name="fkPkInfo" dbtype="query">
		SELECT column_name, type_name
		FROM fkcolumns
		WHERE is_primarykey = 'YES'
		ORDER BY ordinal_position
		</cfquery>
		<cfset fkInfo = {
			"table"   = foreign.fktable_name,
			"single"  = singularify(foreign.fktable_name),
			"fcolumn" = foreign.fkcolumn_name,
			"pcolumn" = foreign.pkcolumn_name,
			"field"   = fieldName
		}>
		<cfif (fkDates.recordCount eq 1)>
			<cfset fkInfo["key"] = fkDates.column_name>
		</cfif>
		<!---<cfdump var="#fkPkInfo#" label="fkPkInfo">--->
		<cfif (fkPkInfo.recordCount eq 2) and ((fkPkInfo.column_name[1] eq foreign.fkcolumn_name) or (fkPkInfo.column_name[2] eq foreign.fkcolumn_name))>
			<!--- link table --->
			<cfquery name="fkPkInfo" dbtype="query">
			SELECT *
			FROM fkPkInfo
			WHERE column_name != <cfqueryparam value="#foreign.fkcolumn_name#">
			</cfquery>
			<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#foreign.fktable_name#" name="fkCols" pattern="#foreign.fkcolumn_name#" type="columns">
			<cfset fkInfo["single"] = singularify(fkCols.referenced_primarykey_table)>
		</cfif>
		<cfset fkInfo["pk"] = fkPkInfo>
		<cfset arrayAppend(fkMap, fkInfo)>
		<cfset fkFields[fieldName] = arrayLen(fkMap)>
	</cfloop>
	<cfloop array="#fkMap#" index="fkInfo">
		<cfif not structKeyExists(ixViews, fkInfo.field)>
			<!---<cfdump var="#fkInfo#">--->
			<cfset viewName = fkInfo.field>
			<cfif (left(viewName, len(colPrefix)) eq colPrefix) and (len(viewName) gt len(colPrefix))>
				<cfset viewName = mid(viewName, len(colPrefix) + 1, len(viewName))>
			</cfif>
			<cfset ixViews[viewName] = makeView(singleName, viewName, fkInfo.field, structKeyExists(fkInfo, "key") ? "struct" : "array")>
		</cfif>
	</cfloop>
	<cfset design = {
		"_id"      = "_design/#singleName#",
		"language" = "javascript",
		"views"    = ixViews
	}>
	<cfdump var="#design#">
	<cfset couchSave(design, maxrows gt 0)>
	<cfloop query="example">
		<cfset data = {
			"_id"   = singleName,
			"Type" = singleName
		}>
		<cfloop query="primary">
			<cfset data["_id"] &= ":" & example[primary.column_name][example.currentRow]>
		</cfloop>
		<cfloop query="columns">
			<cfset fieldName = colMap[columns.column_name]>
			<cfset fieldVal = example[columns.column_name][example.currentRow]>
			<cfif fieldVal neq "">
				<cfswitch expression="#columns.type_name#">
					<cfcase value="BIT">
						<cfset fieldVal = (fieldVal neq 0) ? true : false>
					</cfcase>
					<cfcase value="DATETIME">
						<cfset fieldVal = prettyDate(fieldVal)>
					</cfcase>
					<cfcase value="INT,INTEGER,SMALLINT,TINYINT,INT UNSIGNED" delimiters=",">
						<cfset fieldVal = int(fieldVal)>
					</cfcase>
				</cfswitch>
				<cfif structKeyExists(pkMap, columns.column_name)>
					<cfset fieldVal = pkMap[columns.column_name] & ":" & fieldVal>
				</cfif>
			</cfif>
			<cfset data[fieldName] = fieldVal>
		</cfloop>
		<cfloop array="#fkMap#" index="fkInfo">
			<cfif structKeyExists(fkInfo, "key")>
				<cfset fkKeys = {}>
			<cfelse>
				<cfset fkKeys = []>
			</cfif>
			<cfquery name="keys" datasource="#dsn#">
			SELECT DISTINCT #valueList(fkInfo.pk.column_name)#<cfif structKeyExists(fkInfo, "key")>, #fkInfo.key#</cfif>
			FROM #dbName#.#fkInfo.table#
			WHERE (#fkInfo.fcolumn# = <cfqueryparam value="#example[fkInfo.pcolumn][example.currentRow]#">)
			</cfquery>
			<cfloop query="keys">
				<cfset keyVal = fkInfo.single>
				<cfloop query="fkInfo.pk">
					<cfset keyVal &= ":" & keys[column_name][keys.currentRow]>
				</cfloop>
				<cfif structKeyExists(fkInfo, "key")>
					<cfset fkKeys[keyVal] = prettyDate(keys[fkInfo.key][keys.currentRow])>
				<cfelse>
					<cfset arrayAppend(fkKeys, keyVal)>
				</cfif>
			</cfloop>
			<cfset data[fkInfo.field] = fkKeys>
		</cfloop>
		<cfset cfc &= "}">
		<cfif (maxRows eq 0)>
			<cfoutput>
			<p><a href="#thisPage#?#htmlEditFormat(CGI.QUERY_STRING)#&amp;maxRows=99999">Make it happen.</a></p>
			<pre style="overflow:auto">#htmlEditFormat(cfc)#</pre>
			<cfdump var="#data#" top="3">
			<cfdump var="#columns#">
			</cfoutput>
		<cfelse>
			<cfset couchSave(data, true)>
		</cfif>
		<cfflush>
	</cfloop>
</cfif>


<cfoutput></body></html>
</cfoutput>