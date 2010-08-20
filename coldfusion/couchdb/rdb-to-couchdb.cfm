<cfsetting enablecfoutputonly="true" requesttimeout="600" showdebugoutput="false">

<cfset thisPage=CGI.SCRIPT_NAME>
<cfset pathInfo = lcase(listLast(structKeyExists(URL, "path_info") ? URL.PATH_INFO : CGI.PATH_INFO, "/"))>

<cfparam name="Form.cfPass" default="" type="string">
<cfparam name="Form.dsn" default="" type="string">
<cfparam name="Form.db" default="" type="string">
<cfparam name="Form.table" default="" type="string">
<cfparam name="Form.tablePrefix" default="" type="string">
<cfparam name="Form.colPrefix" default="" type="string">
<cfparam name="Form.doc" default="" type="string">
<cfparam name="Form.couchHost" default="" type="string">
<cfparam name="Form.couchPort" default="" type="string">
<cfparam name="Form.couchUser" default="" type="string">
<cfparam name="Form.couchPass" default="" type="string">
<cfparam name="Form.couchDb" default="" type="string">
<cfparam name="Form.maxRows" default="0" type="string">
<cfset cfPass = trim(Form.cfPass)>
<cfset dsn = trim(Form.dsn)>
<cfset dbName = trim(Form.db)>
<cfset tableName = trim(Form.table)>
<cfset tablePrefix = trim(Form.tablePrefix)>
<cfset colPrefix = trim(Form.colPrefix)>
<cfset docName = trim(Form.doc)>
<cfset couchHost = trim(Form.couchHost)>
<cfset couchPort = trim(Form.couchPort)>
<cfset couchUser = trim(Form.couchUser)>
<cfset couchPass = trim(Form.couchPass)>
<cfset couchDb = trim(Form.couchDb)>
<cfset maxRows = trim(Form.maxRows)>

<cffunction name="makeHidden" returntype="void">
	<cfargument name="ignore" type="string" required="false" default="">
	<cfloop collection="#Form#" item="fieldName">
		<cfif (listFindNoCase("fieldNames,#arguments.ignore#", fieldName) lt 1)>
			<cfoutput><input type="hidden" name="#htmlEditFormat(fieldName)#" value="#htmlEditFormat(Form[fieldName])#" />
			</cfoutput>
		</cfif>
	</cfloop>
</cffunction>

<cfif (pathInfo eq "")>
<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Relational Table to Couch Document Converter</title>
<link href="#thisPage#/style.css" rel="stylesheet" type="text/css" />
</head>
<body>
<div id="title">
	<div class="ribbon">
		<h1>Relational DB to CouchDB Converter</h1>
	</div>
	<div class="triangle-l"></div>
	<div class="triangle-r"></div>
</div>

<div id="content"></cfoutput>

<cfif (couchHost eq "") or (couchPort eq "")>
	<cfoutput>
<h1>CouchDB Connection</h1>
<cfform action="#thisPage#" method="post">
	<label for="couchHost">Host:</label> <cfinput type="text" size="32" name="couchHost" id="couchHost" required="true" validate="regular_expression" pattern="^([-a-zA-Z0-9]+.)*[-a-zA-Z0-9]+$" message="Please input a valid hostname" value="127.0.0.1"> <br />
	<label for="couchPort">Port:</label> <cfinput type="text" size="6" name="couchPort" id="couchPort" required="true" validate="integer" message="Please input a valid port number" value="5984"> <br />
	<label for="couchUser">User:</label> <cfinput type="text" size="32" name="couchUser" id="couchUser" value=""> <br />
	<label for="couchPass">Pass:</label> <cfinput type="password" size="32" name="couchPass" id="couchPass" value=""> <br />
	<input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (couchDb eq "")>
	<cfset dbs = createObject("component", "CouchDB").init(couchHost, couchPort, couchUser, couchPass).allDbs()>
	<cfoutput>
<h1>Target CouchDB Database</h1>
<cfform action="#thisPage#" method="post">#makeHidden("couchDb")#
<label for="couchDb">Database:</label> <cfselect name="couchDb" required="true" message="Please select a target database, or create one if no databases are available.">
	<cfloop array="#dbs#" index="couchDb"><cfif (left(couchDb, 1) neq "_")>
	<option>#htmlEditFormat(couchDb)#</option>
	</cfif></cfloop>
	</cfselect><br />
	<input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (cfPass eq "")>
	<cfoutput>
<h1>ColdFusion Administrator</h1>
<cfform action="#thisPage#" method="post">#makeHidden("cfPass")#
<label for="cfPass">Password:</label> <cfinput type="password" name="cfPass" id="cfPass" required="true" message="Please input your ColdFusion Administrator password.">
<br /><input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (dsn eq "")>
	<cftry>
		<cfset createObject("component","cfide.adminapi.administrator").login(cfPass)>
		<cfset sources = CreateObject("component","cfide.adminapi.datasource").getDatasources()>
		<cfcatch>
			<!--- Uncomment for Railo 3.x
			<cfadmin action="getDatasources" type="web" password="#cfPass#" returnVariable="railosources">
			--->
			<cfset sources = {}>
			<cfloop query="railosources">
				<cfset sources[railosources.name] = { "name" = railosources.name }>
			</cfloop>
		</cfcatch>
	</cftry>
	<cfoutput>
<h1>ColdFusion Datasource</h1>
<cfform action="#thisPage#" method="post">#makeHidden("dsn")#
<label for="dsn">Datasource:</label>
<cfselect name="dsn" id="dsn" required="true" message="Please choose a datasource name.">
	<cfloop collection="#sources#" item="key">
	<option<cfif (sources[key].name eq "asl")> selected="selected"</cfif>>#htmlEditFormat(sources[key].name)#</option>
	</cfloop>
</cfselect>
<br /><input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (dbName eq "")>
	<cfdbinfo datasource="#dsn#" name="dbNames" type="dbnames">
	<cfoutput>
<h1>Database Schema</h1>
<cfform action="#thisPage#" method="post">#makeHidden("db")#
<label for="db">Schema:</label>
<cfselect name="db" id="db" required="true" message="Please choose a database schema.">
	<cfloop query="dbNames">
	<option<cfif (database_name eq "asl")> selected="selected"</cfif>>#htmlEditFormat(dbNames.database_name)#</option>
	</cfloop>
</cfselect>
<br /><input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (tableName eq "")>
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" name="tableNames" type="tables">
	<cfquery name="tableNames" dbtype="query">
	SELECT * FROM tableNames WHERE table_type <> 'SYSTEM_TABLE'
	</cfquery>
	<cfoutput>
<h1>Source Relational Table</h1>
<cfform action="#thisPage#" method="post">#makeHidden("table")#
<label for="db">Table:</label>
<cfselect name="table" id="table" required="true" message="Please choose a database table.">
	<cfloop query="tableNames">
	<option>#htmlEditFormat(tableNames.table_name)#</option>
	</cfloop>
</cfselect><br/>
<label for="tablePrefix">Table Prefixes:</label> <cfinput type="text" name="tablePrefix" id="tablePrefix" value="" /><br/>
<label for="tablePrefix">Column Prefixes:</label> <cfinput type="text" name="colPrefix" id="colPrefix" value="" /><br/>
<input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelse>
	<cfoutput>
<h1>Data Migration</h1>
	</cfoutput>
	<cfset couch = createObject("component", "CouchDB").init(couchHost, couchPort, couchUser, couchPass)>
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
		<cfargument name="prefixes" type="string" default="">
		<cfset var sing = ((right(arguments.word, 1) eq "s") and (right(arguments.word, 2) neq "ss")) ? (right(arguments.word, 3) eq "ies") ? left(arguments.word, len(arguments.word) - 3) & "y" : left(arguments.word, len(arguments.word) - 1) : arguments.word>
		<cfif (prefixes neq "")>
			<cfloop list="#prefixes#" index="local.prefix">
				<cfif (left(sing, len(prefix)) eq prefix) and (len(sing) gt len(prefix))>
					<cfset sing = mid(sing, len(prefix) + 1, len(sing))>
				</cfif>
			</cfloop>
		<cfelse>
			<cfset sing = listLast(sing, "_")>
		</cfif>
		<cfreturn lcase(replace(sing, "_", "", "ALL"))>
	</cffunction>
	<cffunction name="prettyDate" returntype="string">
		<cfargument name="d" type="string" required="true">
		<cfargument name="hideTime" type="boolean" required="false" default="false">
		<cfreturn dateFormat(d, "yyyy-mm-dd") & (hideTime ? "" : "T" & timeFormat(d, "HH:mm:ss") & "Z")>
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
	<cfset singleName = singularify(tableName, tablePrefix)>
	<cfset docName = (docName eq "") ? singleName : docName>
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
		"DATE"      = "date",
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
	<cfif (colPrefix eq "")>
		<cfset colPrefix = " ">
		<cfif (primary.recordCount eq 1) and (right(primary.column_name, 3) eq "_id") and (len(primary.column_name) gt 3)>
			<cfset colPrefix = left(primary.column_name, len(primary.column_name) - 3)>
		</cfif>
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
			<cfset info = "Fetch all documents without using a key">
			<cfset sql = "SELECT * FROM #tableName#">
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#">
		emit(null, doc);
		<cfelseif (arrayLen(ixColumns) gt 1)>
			<cfset info = "Fetch documents with a composite key">
			<cfset sql = [
				"SELECT * FROM #tableName# WHERE (#listChangeDelims(colNames, " = '...') AND (")# = '...')",
				"SELECT #colNames#, AGG(...) FROM #docType# GROUP BY #colNames#"
			]>
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#?startkey=[val#repeatString(',val',arrayLen(ixColumns)-1)#]&endkey=[val#repeatString(',val',arrayLen(ixColumns)-1)#]">
		emit([
			<cfloop from="1" to="#arrayLen(ixColumns)#" index="local.ixColNum">
				<cfif (ixColNum gt 1)>, </cfif>
				doc.#colMap[trim(ixColumns[ixColNum])]#
			</cfloop>
		], doc);
		<cfelseif (not structKeyExists(colMap, ixColumns[1]))>
			<cfset info = "Fetch related documents, as with an inner join">
			<cfset sql = "SELECT #ixColumns[1]#.* FROM #ixColumns[1]# INNER JOIN #tableName# ON (...) WHERE (_id = :_id)">
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#?startkey=""#docType#:_id""&endkey=""#docType#:_id""&include_docs=true">
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
			<cfset fkPrefix = structKeyExists(rowFromCol, ixColumns[1]) and (columns.is_foreignkey[rowFromCol[ixColumns[1]]] eq "yes") ? singularify(columns.referenced_primarykey_table[rowFromCol[ixColumns[1]]]) & ":" : "">
			<cfset info = "Fetch documents by a single field">
			<cfset sql = "SELECT * FROM #tableName# WHERE #ixColumns[1]# = :param">
			<cfset viewurl = "http://#couchHost#:#couchPort#/#couchDb#/_design/#docType#/_view/#viewName#?startkey=""#fkPrefix#value""&endkey=""#fkPrefix#value""">
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
		"all" = makeView(docName, "all", "")
	}>
	<cfloop query="indexes">
		<cfset viewName = lcase(trim(replaceList(indexes.index_name, "IX_,FK_,PK_",",,,")))>
		<cfset ixViews[viewName] = makeView(docName, viewName, indexes.column_name)>
	</cfloop>
	<cfset fkMap = []>
	<cfset fkFields = { "type" = "type" }>
	<cfloop query="foreign">
		<!---<cfset fieldName = singularify(foreign.fktable_name, tablePrefix)>--->
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
		SELECT column_name, type_name
		FROM fkcolumns
		WHERE (type_name LIKE '%DATE%')
		  AND (column_name NOT LIKE '%update%')
		</cfquery>
		<cfquery name="fkPkInfo" dbtype="query">
		SELECT column_name, type_name, referenced_primarykey_table AS refTable, referenced_primarykey AS refCol
		FROM fkcolumns
		WHERE is_primarykey = 'YES'
		ORDER BY ordinal_position
		</cfquery>
		<cfset fkInfo = {
			"table"   = foreign.fktable_name,
			"single"  = singularify(foreign.fktable_name, tablePrefix),
			"fcolumn" = foreign.fkcolumn_name,
			"pcolumn" = foreign.pkcolumn_name,
			"field"   = fieldName,
			"type"    = fkcolumns.type_name
		}>
		<cfif (fkDates.recordCount eq 1)>
			<cfset fkInfo["key"] = fkDates.column_name>
			<cfset fkInfo["keytype"] = fkDates.type_name>
		</cfif>
		<!---<cfdump var="#foreign#" label="foreign">--->
		<cfif (fkPkInfo.recordCount eq 2) and ((fkPkInfo.column_name[1] eq foreign.fkcolumn_name) or (fkPkInfo.column_name[2] eq foreign.fkcolumn_name))>
			<!--- link table --->
			<cfset isGraph = (fkPkInfo.refTable[1] eq fkPkInfo.refTable[2]) and (fkPkInfo.refCol[1] eq fkPkInfo.refCol[2])>
			<cfquery name="fkPkInfo" dbtype="query">
			SELECT *
			FROM fkPkInfo
			WHERE column_name != <cfqueryparam value="#foreign.fkcolumn_name#">
			</cfquery>
			<!---<cfdump var="#fkPkInfo#" label="fkPkInfo">--->
			<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#foreign.fktable_name#" name="fkCols" pattern="#fkPkInfo.column_name#" type="columns">
			<cfif isGraph>
				<cfset fkInfo["field"] = singularify(foreign.fkcolumn_name, colPrefix)>
			<cfelse>
				<cfset fkInfo["field"] = singularify(fkCols.referenced_primarykey_table, tablePrefix) & "s">
				<!---<cfdump var="#fkcols#" label="fkCols">--->
			</cfif>
			<cfset fieldName = fkInfo["field"]>
			<cfset fkInfo["single"] = singularify(fkCols.referenced_primarykey_table, tablePrefix)>
			<!---<cfdump var="#fkInfo#" label="fkInfo">--->
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
			<cfset ixViews[viewName] = makeView(docName, viewName, fkInfo.field, structKeyExists(fkInfo, "key") ? "struct" : "array")>
		</cfif>
	</cfloop>
	<cfset design = {
		"_id"      = "_design/#docName#",
		"language" = "javascript",
		"views"    = ixViews
	}>
	<cfif (maxrows eq 0)>
		<cfoutput>
<h2>Document Type Name</h2>
<cfform action="#thisPage#" method="post">#makeHidden("doc")#
<p><label>Table Name:</label> <strong>#htmlEditFormat(tableName)#</strong><br/>
<label>Table Prefixes:</label> <strong>#htmlEditFormat(tablePrefix)#</strong><br/>
<label>Column Prefixes:</label> <strong>#htmlEditFormat(colPrefix)#</strong><br/>
<label for="doc">Document Name:</label> <cfinput type="text" size="12" maxlength="12" name="doc" id="doc" value="#htmlEditFormat(docName)#" required="true" message="Please input a new alphanumeric lowercase document type name." validate="regular_expression" pattern="^[a-z0-9_]+$">
<br /><input type="submit" value="Update" />
</p>
</cfform>
		</cfoutput>
	<cfelse>
		<cfset couchSave(design, maxrows gt 0)>
		<cfoutput>
<h2>Design Document</h2>
<p><a href="http://#couchHost#:#couchPort#/_utils/document.html?#htmlEditFormat(couchDb)#/_design/#htmlEditFormat(docName)#" target="_blank">Open Design Document</a></p>
	<cfdump var="#design#" expand="false">
<h2>Views</h2>
<table class="zebra">
<thead>
	<tr>
		<th nowrap="nowrap">View Name</th>
		<th nowrap="nowrap">All Docs</th>
		<th nowrap="nowrap">Include Related</th>
		<th nowrap="nowrap">With Key</th>
		<th nowrap="nowrap">Related With Key</th>
	</tr>
</thead>
<tbody>
		<cfloop list="#listSort(structKeyList(ixViews), 'textnocase')#" index="view">
	<tr>
		<td>#htmlEditFormat(view)#</td>
		<td align="center"><a href="#htmlEditFormat(listFirst(ixViews[view].url,'?'))#" target="_blank">all</a></td>
		<td align="center"><cfif (ixViews[view].url contains "include_docs")><a href="#htmlEditFormat(reReplace(ixViews[view].url,'(start|end)key=[^&]*&?','','ALL'))#" target="_blank">all+include</a></cfif></td>
		<td align="center"><cfif (ixViews[view].url contains "startkey")><a href="#htmlEditFormat(reReplace(ixViews[view].url,'include_docs=[^&]*&?','','ALL'))#" target="_blank">key</a></cfif></td>
		<td align="center"><cfif (ixViews[view].url contains "include_docs") and (ixViews[view].url contains "startkey")><a href="#htmlEditFormat(ixViews[view].url)#" target="_blank">key+include</a></cfif></td>
	</tr>
		</cfloop>
</tbody>
</table>
<h2>Data</h2>
<p>Migrating #numberFormat(example.recordCount)# record<cfif (example.recordCount neq 1)>s</cfif> ...</p>
		</cfoutput>
	</cfif>
	<cfloop query="example">
		<cfset data = {
			"_id"   = docName,
			"Type" = docName
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
					<cfcase value="DATE">
						<cfset fieldVal = prettyDate(fieldVal,true)>
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
			<cfif (fkInfo.pk.column_name neq "")>
				<cfif structKeyExists(fkInfo, "key")>
					<cfset fkKeys = {}>
				<cfelse>
					<cfset fkKeys = []>
				</cfif>
				<!---<cfdump var="#fkinfo#">--->
				<cfquery name="keys" datasource="#dsn#">
				SELECT DISTINCT #valueList(fkInfo.pk.column_name)#<cfif structKeyExists(fkInfo, "key")>, #fkInfo.key#</cfif>
				FROM #dbName#.#fkInfo.table#
				WHERE (#fkInfo.fcolumn# = <cfqueryparam value="#example[fkInfo.pcolumn][example.currentRow]#">)
				</cfquery>
				<!---<cfdump var="#fkInfo#">--->
				<cfloop query="keys">
					<cfset keyVal = fkInfo.single>
					<cfloop query="fkInfo.pk">
						<cfset keyVal &= ":" & keys[column_name][keys.currentRow]>
					</cfloop>
					<cfif structKeyExists(fkInfo, "key")>
						<cfset fkKeys[keyVal] = prettyDate(keys[fkInfo.key][keys.currentRow], fkInfo.keytype eq "DATE")>
					<cfelse>
						<cfset arrayAppend(fkKeys, keyVal)>
					</cfif>
				</cfloop>
				<cfset data[fkInfo.field] = fkKeys>
			</cfif>
		</cfloop>
		<cfset cfc &= "}">
		<cfif (maxRows eq 0)>
			<cfoutput>
<h2>Example Record</h2>
<cfdump var="#data#" top="3" label="Example Record">
<!---
<h2>Data Access Object</h2>
<pre style="overflow:auto; max-height: 8em;">#htmlEditFormat(cfc)#</pre>
--->
<h2>Data Migration</h2>
<cfform action="#thisPage#" method="post">#makeHidden("maxrows")#
<input type="hidden" name="maxRows" value="99999" />
<input type="submit" value="Migrate Table Data" />
</cfform>
			<!---<cfdump var="#columns#">--->
			</cfoutput>
		<cfelse>
			<cfset couchSave(data, true)>
		</cfif>
		<cfflush>
	</cfloop>
	<cfif (maxRows gt 0)>
		<cfoutput>
<p>Done.</p>
		</cfoutput>
	</cfif>
</cfif>

<cfoutput></div>
</body>
</html>
</cfoutput>
<cfexit method="exittemplate">
</cfif>

<cfcontent reset="true">
<cfswitch expression="#pathInfo#">
	<cfcase value="style.css">
		<cfcontent type="text/css">
		<cfoutput>/* Relational-to-Couch Converter, by Rick Osborne */
html {
	background: ##292813 url(back-stripes.png) top left repeat-x;
}

body {
	margin: 1.5em auto;
	border: 0.25em solid white;
	border-radius: 1em;
	-moz-border-radius: 1em;
	-webkit-border-radius: 1em;
	max-width: 45em;
	min-height: 10em;
	padding: 1em;
	background: ##f6f0e2 url(back-stripes.png) top left repeat-x;
	text-align: left;
	font-family: Cambria, "Hoefler Text", Utopia, "Liberation Serif", "Nimbus Roman No9 L", "Lucida Bright", Times, "Times New Roman", serif;
	font-size: 100%;
}

pre, kbd, tt {
	font-family: Inconsolata, "Andale Mono", "Lucida Sans Mono", "Lucida Typewriter", "Lucida Console", fixed-width;
}

h1, h2, h3, h4, h5, h6 {
	font-family: "Gill Sans MT", "Gill Sans", Calibri, Verdana, Tahoma, Helvetica, Arial, sans-serif;
	font-weight: normal;
	letter-spacing: 0.1em;
	margin: 0.5em 0;
	text-shadow: 1px 1px 0.0625em rgba(0,0,0,0.25);
}

h1 {
	color: ##a84d10;
	font-size: 200%;
}

##title {
	position: relative;
	height: 6em;
}

.ribbon {
	background: ##5d87a1;
	position: absolute;
	right: -2em;
	left: -2em;
	float: left;
	z-index: 2; /* the stack order: foreground */
	-moz-box-shadow: 0px 0px 0.5em rgba(0,0,0,0.5);
	-khtml-box-shadow: 0px 0px 0.5em rgba(0,0,0,0.5);
	-webkit-box-shadow: 0px 0px 0.5em rgba(0,0,0,0.5);
	border: 1px solid ##2f4451;
}

.ribbon h1 {
	color: ##fff;
	text-align: center;
}

.triangle-l, .triangle-r {
	border-style:solid;
	border-width: 0.5em 0.75em;
	position: absolute;
	bottom: 1em;
	z-index: 1;
}

.triangle-l {
	border-color: transparent ##2f4451 transparent transparent;
	left: -2.75em;
}

.triangle-r {
	border-color: transparent transparent transparent ##2f4451;
	right: -2.75em;
}


h2 {
	color: ##eb6e1f;
	font-size: 175%;
}

##content {
	border-color: ##576423 ##888 ##888 ##888;
	border-radius: 1em;
	-moz-border-radius: 1em;
	-webkit-brder-radius: 1em;
	background: white url(couchdb-watermark.png) top right no-repeat;
	border-right:1px solid ##888;
	border-style:solid;
	border-width:1px;
	padding:0.25em 0.5em;
}

##content, ##title {
clear: both;
}

dl {
	margin-left: 0;
	padding-left: 0;
}

dt {
	color: ##a84d10;
	font-weight: bolder;
	font-size: 125%;
}

dd {
	margin: 0.5em 0;
}

.col2 {
	-moz-column-count: 2;
	-moz-column-gap: 1.5em;
	-moz-column-fill: balance;
	-webkit-column-count: 2;
	-webkit-column-gap: 1.5em;
	-webkit-column-fill: balance;
}

h3 {
	color: ##2f4451;
	font-size: 150%;
}

.col2 h3 {
	break-before: column;
	text-align: center;
}

kbd {
	color: ##2c3212;
	background-color: ##bbd097;
	padding: 0 0.5em;
	border: 1px solid ##576423;
}

label {
	display: inline-block;
	min-width: 8em;
	text-align: right;
	padding-right: 1em;
	height: 2em;
}

input[type=submit] {
	margin-left: 10em;
}

a {
	color: blue;
}

table.zebra, .zebra td {
	border: 1px solid ##ccc;
	border-collapse: collapse;
	padding: 0.1em 0.15em;
}

.zebra th {
	padding: 0 1em;
	color: ##2f4451;
	background-color: ##ddd;
}

.zebra tr:nth-child(2n) {
	background-color: ##eee;
}


		</cfoutput>
	</cfcase>
	<cfcase value="couchdb-watermark.png">
		<cfcontent type="image/png; charset=ISO-8859-1">
		<cfsavecontent variable="png">
		<cfoutput>
iVBORw0KGgoAAAANSUhEUgAAAKUAAACWCAYAAAC/xUjZAAAcNUlEQVR42u2dB7AURdeGr58555xz
1irHnHOZc8KcMSvmHBEVBRQUQUDMCUwIKCIIAiqKKKCiCIIRRTBgwvzX0/WfW01v94Tdmd2Z3abq
1AXu7kxP9zunz3lP6Kb//vsv8OIlT9LkJ8GLB6UXLx6UXjwovXipNihnzZoVjBs3Lhg9enTw7rvv
WoXfffrpp6kNknt++OGHofeMkvfeey8YNWqUkpkzZ9Z00n/77bfg22+/VXM0duzY4I033ij7uYog
rNvUqVOzA+X06dODa6+9NrjggguCiy66yCr87v77709tEb/77rvglltuCc4991znPcOkVatW6rs3
3HBDMGTIkNyB8pVXXgkuvPBCJeU8X94FPAwYMCA7UM6YMUMB5MorrwyuueYaq/C7Rx99NLVF5EW4
8847g8svv9x5T5fwnauvvjp44okngu+//z63W9aDDz4YXHbZZYmfrwgCHgYPHuxBCRAvueQS9T22
7rzbUYzxiiuuUOP2oKwzULKoLC4mRv/+/YMffvihEMb9r7/+GnTu3LkutWVDg5L7sqj33HNPMGHC
hMJ5nYMGDapLbVlTUKKdkKuuuip47LHHUgcl95R76HLdddcpMLZu3Vot7O+//15IKuSPP/4I2rVr
p0Bpe84iSK5AKeBAmNTHH388tcXinnfddZcCu9xDvxdjeeihh4LPP/88VZBMnDgx6NWrV/D0008H
zzzzTKTwuWeffTb46quvZrvOL7/8orxPrhX2/eeeey649dZbZ5vLookNmA0DSu7JVnfbbbcFI0aM
CP76669UAfnJJ58EN998c3DxxRcHl156aWzBubr99tsVoHVNzzihfKK+z3MVFZANDUrRjk899VTw
zTffpL6NwiGisWyaOY7wvRtvvDF488031fVwtlyavt6k4UCJZkSwu4gS/Pvvv6kDksiD2K+VLI7M
y6uvvqpenE6dOnlQ1hso2RJZVGyvn376KRNHAw2ZBiBNYHbr1i1o3769mhcPyhqC8sknn0wVlERk
iLln5fmmDUh9kcSbrndA5h6Ud999t4rxpkWVIFkBUrZsTINGAE5DghKB6O7Tp0/uucGsNKQHZQ5B
KdTGmDFjPCA9KPMBStnG4edIPcsbIP2W3aCgRFj07t27p2Zfeg3pQVkRKPl/YtLYl0RdPCA9KKsO
SqE/EDhFSG7Sx8aPH5+LBFu/ZTcIKAEgmhCNeP311wcdOnRQBPekSZNUIkJetmzGfccdd+RKQ/Li
Sv6kB2UKoASIJB9wQ0JoZLhAbv/555+59LRJimDceYiqCBiJ8hAUIPGjXkKQNQEli3vTTTcpr7pf
v35qa/7xxx8Lka8IPaXTVdVcKDFp+NmjRw9VwYh9KxlJmDr1YFbUBJRsyZMnT87V1pxEXnzxxaot
PgBEI7JQmDV9+/ZVuZa26BQAJUYun/egbCDBvHj44YczBaZsz+wmJKa88847scKkZMz37t1bfb+o
dqYHZQX2JdtlWnacvj3z9/vuu09RYGYGehwhWZl0N5zGItqZHpQVCB03WPhKHB9hHph4UutgHSjJ
oKNHpePDaSTRuGh2pgdlCtWDUoyWFIyULgAaCuRGjhyZSbEaAKfstkjAdIES7Z8IlGRw08qEbQ3K
B+HvtW5vUo3qQQrOorhL03umhHfo0KHBl19+mfkYYTYYI8Asgp3pAiVMDWUhgi+bCOYUKP/++29V
aUddCVweQrnqa6+9VvfakkWHL7TZb9L2hZ9t27ZVc0RQoNpxfOxMFpVx5N3OdJXZ6thyCeYUjl4z
KHkbhQyXon62t0bYxuEJmTSxL2V75sWkxw+c4s8//1zzcVKXxJjyHLd3gVKK/cKEZlgwI82gfOSR
R2brQJHUOC260I1NJociNWwg+Nh//vknV+NkTDAHeQWmC5RxBEVAZxUPyv8XwEdLPiJU9PXJO6X1
wAMPNK+XB6WXXAjePvkG1SbasfsQD0ovTu0+fPhwlYuQtQMkQMTv4F5RwCyn71DqoPzss8/U57HF
dMFZykuCb73KBx98oNiBLPhM0YzggW7Ip59+usJJGCiT1sVnBkp4OyZFuDwRrnPOOeeo+K8HUHZC
SLNLly5qDdMEJBoN7XjGGWcEp512WtCyZUu1zoUA5bBhw6xF9wyeBwGsGOgeQNkJxDP5mWk4QKZ2
FMk1KM0+PmGgPO+884LjjjtO3cODJ3s78+WXXy6baBftCGcIANGOhQElITqSZiWvMgqUPNwpp5yi
CGAPnuyFo0KIkiSxM1krPo+5ZYKxEKAk9EWKVteuXVXDKaIeUaA8+eST1dtblEz1ogvOZ8eOHZt7
wEdpR/pn2rRjoUDZs2dPdUbKvffeq1L8XQ8soOShjj/+eBXSzKKNX1Hko48+UjROksyZcoUqUkKl
Uuhn86wB2dlnn63WKAyQhQClRBWkcXwcUJ566qnq743ojUv3ODxZXk7mgXbUWRfbYWqR0CH5n2hF
DrqKqx1zBUriwXFAGWWn6KBETjrpJLWN13tqnJlMAQgEjMyDmDR0EMmyq5x+Vg+LTh6ogJG1YAyi
LKoJSpNAjwVK0ohcceBKQCnbONt/vYMRe5vMFxbzhBNOKFlkwHDssceqmnSpbsxSWGsynsiMev75
5xXpjqd91llnKXAylhNPPFGNK3egFEqBKjy2cbPepFJQykPXszeO80cKYNgii8YEsMx3mgetJqlQ
hUl54YUXlH/AmmFiHHPMMWpcsCa5AaX+YSrzqEHBSNfPEywXlAiLhZ1Tb6Q6z8OBqQCR7TGOrSbz
wbb69ttv13T8OEeELsmakrJfgJl2RKdsUOplo/weAxlPm4njZ1ReXxgoZRuvF1KdecQO55gTnitM
O4YBk7miPj0PuZyMAdt/4MCBzVo9N6DUPSaJa8cpuIoCZb2Q6pg31O6I45AUjKZpwzWgztKojEzr
7Ehi4Iwtd6AsJ2wVBkqkyKQ6c8c2x4KhHSsBo83OBOh5OfSUxgqsVV2AkqB+1FZWRFL9iy++UPXe
LFQS2zEpMFkH7lXr56V6s+aaMo2eNgxeKAedPLdtWUUh1fFWsfmIEYsNmDYgdQHwLNjYsWOtbWiq
2fKG+iCcsUKD0uwmAUBZTNEEemirCKQ6nTUgn9HsOlWStTA3hAKl7BlOkwNKKXLL4ihAl3C0H6ZK
FvU8VQelxFkl+A/4eDjszTPPPLMZpKS4ceZi3sBIrTchQTQ+W2rW2tEFTCgZOXyUcbRo0ULxi+U+
F+YSnDMOFc4MCgEb9uuvv1a0ENlGxOhfeukldWAXVJcAqvCgjAIpA2rVqpVadEBq26pqJe+//76q
CwcU1dSOum0pwv0xGRgLJg8am6gMa2hSOYQuARinc0yZMkUR88wrQIO6Iu+S4jOAAB+J1iXdzawe
0CXNIrXcgdIFUkkwZYJq3QAAzUGvIIkRpw2wKOG+vKBs2+wo559/vtKQzI95HDPakq2dLZ3wMIEN
eGROfqPPO92CyUyCCGeHkgMScFrgmgWI1Vzz3IPSBCf3p+aENxoOsJpNWtnSRo0apcZjhtmiQIb2
EqdNtnjAhRC6QwAaOwJAQ3SgsQaARNdMUv2nzw9BDBGdPxag2gCX9xrx3ILSdI5kQvH6pNVeloCc
Nm2aiukDRNkiTcAJvSWaDIDhvEF9iUbDFAFoRHcEIAI03XSJI3EXuGgdgAsJSjOSxEKneTqubbtG
82CnodFs2yZbn66JdC3EfJlaLCm4Gvl4k8KBUk4vo/wiq7YqdJ3AltXnwbVtlqvRvNQZKBkTBju1
J1lpS6iPtIrtvTQAKBG8RiiNrEAJZeJPJPOgTCSMkRBfVqCENIb3y8MhUB6UBQElYMGuzKqmhesS
tUiz/Um9SNr2c67CjJU8lHi4WR5ASjgRM6FRABYl0vNdOjyn1bC1pllC0CjQKtK+2qRPkoIUGibL
MCS1NUXk/WyA0pkCGxgEbKw9oID2gnqDCoN7hYdFhPiHn2UtCx37ltQ1nYTmISGa+X/ePDkUKa4m
ZSIrSUKIk0Xepk2b3EVATLDp9JQssIAMZ02AhjKAZwVsAEoHW9yQpx7BArB1AUozq0YiJDpIdW1q
glQHKhNP1V2W2eTEi7N0dsrdPuX0YOYUoDFngIT5A2xEl9BoRJskT1VXCHG6YETF7usWlK74sR6+
4+H5rrnl85P0rSzLBEhsSApK29Zpbp96F1u9h6ckSujbJxElc/sUsLli7ZWCzoMyQTYNC4I2QDtI
i2M6PmQFSqo1TVC6tk99gvXtE6Ax0cS/GTd9l3RbTdqlJNk+ay01B2Va21Q5oIwCKtk79OXJCpRT
p05t7u0tYBM7TddobJ+8LAiaTd8+a6HJPCirDEpdyFCn1UlWfCWZ5kwa99K3Ttv2mWfN5kHpACVb
V9oLRQUh4y3n+OK4Rfg0ntIbUnmpI1BG1X2XW7BPzmOWfCW1KUcffbQHowdlfKEBU9++fTMD5ccf
f6xsxFrU5XhQFhSUFFDRPplqvKxOuKVgjPt4QHpQxt7C8X7pAZmVtqRtCj0bPSA9KBPVQuvtCdMW
SlC5h3d2PCgTeeFZ5lfiSME/ltPWz4OygUFJnDrLYjIiMpW29/OgbCBQ4hkTYYHszgqY7du396D0
oEzm7LC90vcmK1D26dPHg9KDMrmzk2V+5bhx4zLpP+lBWceghLLhSL6sQAlfCfXkPXAPykQkOs2b
suIraRaKM+W1pQdlImcHu5IDi7K0Kz2J7kGZ2OEh35FTtOhsm3bvdBog4Ow0+hbuQVmGxiT5l8xu
GmGl2Q+cJvRkkjf6Fp6LcogkUmtQmufQpHnWIcnEnASR5rEkRQUlWfZVASXHhfCflACkKZQRyGGU
aLJqCZnpr7/+eqpbOC8u+ZXVfpY8Cc/Oekoz1jSFyBmHqzaDkoN7AJBeEJWGkPolzQgonKqWyBae
9skIXLvaz5InkTJos3guDQHo1F01STtlnIOJEyeqZu1py6RJk6ouPAvNqtKu2+F5uHYtnilPkgVO
mFdw2NQoh8B7KY54UHrxoPTixYMyRwJFte+++wYHHnigkv3220/Vk2dZztFQoISY5nBPqgmhk8g5
xKXH2+bID7woWupl2UeyaIIx39TUNJusvPLK6kSwtA4yJdTKugwePFgd+QwDwfqIQGsNGDBAHQRF
GUm5B2jhHE+fPl1VfA4dOlTdr1+/ftZ78fsJEyZkB0o8JCIbu+++e7DccsuVTLIuiy++eLD11lsr
sjXL5vlFkcmTJ5fM0ZprrpkKKGEa0Lxrr712sOyyywbzzTdfMO+881rXZc455wwWWmihYI011gh2
2GEHFWwAvOZRemEyYsSIYMstt1TjX3DBBdX9XPfi92uttVaw//77q0K8qK4msUFJbx0Y/aWWWioU
iDaZZ555cnFedT2DEk3kAkYcmXvuuYN11lkn6Ny5c6wjYXr16lX2vTbaaCOVo1ARKDlYkreq3EHs
uOOOfvvOGJTsYOUoDJvsscce6gjpqBbcldyDF4gtvixQkjy7yCKLOC++6KKLBjvttJMKQREqYqs+
6KCDgk022US9fXyGk1E9KKsPSrbNXXbZRa2J3jHukEMOUesTBprVV1899GgYGyh5FiIzYlNyoAER
oC222MJ6jyWWWEKNOxEoOehorrnmsl5w0003VSelymGeeqqYHOmL0c2B7UmMXA/K9EDJtTkW2pZc
wvpQ14RzCjhsa8zu6Fo7GygPOOAA62dhFzjJTZSULrwssUHJBK600kolF5l//vlVdkdWR9F5UKYH
SpwLQoJxats333xzKzABms0xcYEyzIkh4cf8znbbbRcPlLTBI8vGZgxzfrQHWHFAGXeXIl902223
tQKTM8/jgBLvetasWc57DBo0qERbrrjiivFAyVnXNpVOLUwWizVjxgyVZkYdDEm6EMwHH3yw6pTL
hLCYcfpJDhs2TPUqZ8I4hhkPD9YgKvOHz/IdBK8y7vHNcLAjR44MOnTooLKS0BQIf4e3HTNmjOLy
okApn6FRF9wueZtHHXWUmoPWrVurloRhi50GKOWolsUWW6xkjFBNZhOxckAJN2oyBBtuuGE8UJJC
ZN4QTnLKlCmpgnHmzJnqlIf11lsv1OjGYIdLo9Q17ATa7bffvuS7TF7YGPbZZ5+S70D+h32HTBYO
AmBCo7xMrh8FSmxynu3II490XocIUJhHnAYoEXqxm/cGqLx8lYISjtL8Di9wJCgBCn/ML5NxnXaP
HjzDJDTCKqus4syRBJTm9SCPw/gwhMU27+OiKhCiE5tttlnsMWMGhYFy/fXXV9qZyE7UtfCIXcBM
C5RoswUWWKDk3ua8u2xKV1tGxrHaaquV+CejR4+OBiUPN8ccc5TcMGpxkxb3r7vuutaJJ9Kw9NJL
q2iQi+S1gaYaoKSR1pJLLhkaJGB7+t///tf8f4TawkDJsy6zzDKxQc5Waqs9SguUXNvm4OLcRoES
swtPG22J4AwTaerZs6eV58ZMicVTQgPZQkUYwmkd9L7bbruV3IO3kzR73lRCkmhSzvZeYYUVrNuJ
uZVnDUo4O4xyF9nMWLFn6dTBIuBp8py6PWwDpQiKYO+991bZ/9SrMC5XmJA4c1agRLbZZpuSexLN
08OQNlAS3gSYYlvz/DbfZOGFFw7atWsXP6LTpUuXkovw5qRVhMWC2SbapZ1wXmwx9sMPP7xqoER7
HHbYYdaXg+dxbVloC30hXaDkpWeRzLJg6lWwp+M4nGmCEnLdZhszx5VGdPgzfPjwZLFv1LR5IR4u
DdqCBdp4442tb2HY93CGTJOCbV7XllmCEg/dvD//pq6pUkoIwbF0fYeTNczPb7DBBpmC0jYngFJ3
YsoFJRHAPffcM+jfv7+zNr8ElGwf5oXIPNGpjXIFrYdxaw7S9OxsySAE8c1xcY5ONUBpI33R1Emy
alygZCsLy6Ai9cuMqrFz0N8oK1AeeuihJeOkO4i+I9hAiVaHTQAvSFS+BOW6thaOTXHcdgzxNLZv
Qk2mxoHGweOP+i68nTkuyj2rAUqbdsd+TIM8JzMHntb1HcKEpmeOs2WCLU1Q2tgFMxxoA+Wuu+6q
xkt4GSFfE40I18pYbMBkJ4gEJYa67cthHGFcoUTTvO4RRxwR67s2DY4hLVtKVqBEI2HA67/H+Spn
PsqJ6LC4aB39O4DPTGRIC5R4z+bzImYkzwZKEnHC8j35vS1sTW5mKCh5CJ3SEEmjhTNbQLn8J4kd
5nd33nnnZvWfFSgBhbnYgMSW3ZIFKFkPU8tkCUo0mxl1gYaDlamUPIfBsQVKCIyEgpLQmY1DtAXO
qwlKIijmd8l+FzvHBUq6pVUKSpObhAQeP358XYISWs4cI5Er87jBckDp2i3Bll6n1GSrvSAHzkYM
Ry1wlGCX2IAV9SAI+ZrmdzlxTG8UgOY0xxwVZrTRHzooGZvJT7LlDBkypO5AyYtmI84JPaaRkIFA
mNtS5Kj1CY19kwBgS60nJFaJwwOnZ5oGhA6jzsHBEbIRunqUAS4REtv8DNt+2LVNINscHVtaF21L
6gmUKCMYBZtHzdnnaYGSebNRXDoD0eQ6psNmlEr0Ik7Wjk24sS182LVr18iGpWZ0g3+b2sqW0KBr
U9uCQ0lFgZJsbVuCStJDpfIKStab46+jYveVgpLdzKY44C11uqkprEloWEYyLdvCqAyRadOmzTZQ
0rFstIgrjEkJKFSD+R00J+lq+mcpxzA/hz1IEoWtHNX14pmgJORpc/6o5ouqZaklKHHIwtLw2F3Q
grawr5T/utbFlZARBsq2bduq6JX5PXjg2OUQJBOYZLe5ndNrvHfv3kprEZNl66f+l/QvWj6zPeuc
3ltvvWUNnVHqaZLo2Bm2LYUHM71BhPvb4sWAnkwcbCYEzWt7Y12g5C0mz9P22eWXX17xcITOAAaO
EeOm2K5NmzazgafaoFx11VWDgQMHqt9xHcbGTyiYHj16qLm1gUTKo20x9jBQ6ml6OsXE/Wx+inDg
1MMnKhxja41TuklCBZ+zgdi0v1hE2zXQakwUWwZ9IFkw2+d4s2whKsCz1VZbOceIhjejDIAqThye
sgIXASyRKcCPduJzEoXR+b1qgxIqB2DCpnANGZvNZDHniSzxpNWMrB9BDtYPgYMmOBJ2P+L7ZZXY
wvXxcOWWU2IzmFniNDQo51okhYbVgaChbFut6yXgQFBTW9gmSnIp0fxJxouGqBUokwqKpUWLFrHq
eiotscU0dPkSsZsR4HVTnhCVJe4qPjftP8lIsoXwbMLn+HycsfKwLntYhBJTTA48e3Ia9d+x7bqu
zYJhF9tyTm2Cdx/WtoXoEHa3636YAiYlhfljnoTBv0lSKQcggB4Nx1YfFw+YbOXcCweRjCtbcm/Z
bVuYWOpm4K7YKm0Z03BdtGsh+6dbt26qt40NlAidM+jKgJFs5k6Sac02jv2TtMMG9SYE/NmyRBMC
VHhR0sTEgMfmadmypcoDxHvca6+9VL1yVLYTCb8QwcyBCQbIdXYHzBZsbLPBFfdB+DtzFNbgivAc
n8Fek+/AKJgNYSnRYA6Zs7AsdtYGX4BkYRxDMspdHjoBCZxZPWVNBPufF475RdvbXgh2Fe6F/U7t
uWAh065rTCZvOduSCLQPkx8nycLMPeR7fF+uw7aWNBPHFLKb8EC5JgtplgZjm2IOMPGMAdrClR/p
mgOiHfL81DExJ7bsF+4l90H4O/cOO17FHJ/8NL/Dv2EUmDPuzzj0dRFhjl1As73Y2P/8tBXqcT/m
l3vqcyDrxzi4V9JybN8K0EtoPRK2v41S8/0pvdREKE0hAZmfHpRePCi9FF/I+yTHEzsPGw47kGiN
zcHEWYUYp+EtwQxXY9swUGLX4iBRTUAgg8YLrggf4Vi8bdO2JFrH/5v0lgdlnQiAxNsHQPCspKBR
26Q7bYQViWZx2hekPgkydEmjrMTWaCIMlHDX3A/mpHv37qoCk64gtuvAQMDX6rmtvCzQSmSem93d
PCjrRNBG8Ku0XYR6wQM2W0cDDhwXtCgePcwGHjIJ3MSlTcYgDJRcH68boHMd+Ftai3fq1MmqnQk1
E4mTLnBoSBJdbJEjD8o6AiWpfGg92zbKFg0/a+swAndIuQlbeSU2JdWdaEwzIVgykei5hDYFwLxA
5EfYKD8PyjoCJQBytbXh95DlAIdIli6ixcyE6ChQoinRdBy6gClAdQBbuitzCjCSwAP3CThd4VUP
yjoDpavKEruNBqlkfqMx0agIf0fY9olSxQUlYAZgaD9eBE6i6Nixo7JXXXmmEPxE57B3sSe9990g
oHQtNo4QoKR7b6WUEHF2tmlyavX8SVoq8nkXKGED+B45DJgaLo3qQdkgoCTWj2azNUBNCkoyqzAF
zKQQtnEXKHGo2NoxH2htjcZmC7eFID0oGwSUeMRiO5JMoWs4aCNbrN4FSspw8ZxJbJYYPJwlTb4A
nglK7o3Nye/ECcL7RnOjXT0o61TYCuH8wvobQbCTAQWgoG4AF80noJAQM8kDgp1rmhnotNHBHsVj
J6Mf7QsnyrbM/+mNGrgmrWdIe9SvA5UEn8r1zTQ2D8o6EbZHFj+qcwcaEaeHkhUAil2IB412M0EJ
F8k1bYWCAJPfcUII4ObfZGGRk6nX9aCR0bQ4QqY2Zsw4V9iaOjXkQdnAwrbtynNN0kkvqnQ3bomv
B6WX3IoHpRcPSi9ePCi9FE7+D7WFh8zSgpXnAAAAAElFTkSuQmCC
		</cfoutput>
		</cfsavecontent>
		<cfoutput>#toString(toBinary(trim(png)), "ISO-8859-1")#</cfoutput>
	</cfcase>
	<cfcase value="back-stripes.png">
		<cfcontent type="image/png; charset=ISO-8859-1">
		<cfsavecontent variable="png">
		<cfoutput>
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
		</cfoutput>
		</cfsavecontent>
		<cfoutput>#toString(toBinary(trim(png)), "ISO-8859-1")#</cfoutput>
	</cfcase>
	<cfdefaultcase>
		<cfheader statuscode="404" statustext="Not Found">
		<cfcontent type="text/plain">
		<cfoutput>404 Not Found</cfoutput>
	</cfdefaultcase>
</cfswitch>