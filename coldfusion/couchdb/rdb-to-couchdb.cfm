<cfsetting enablecfoutputonly="true">

<cfset thisPage=CGI.SCRIPT_NAME>
<cfparam name="URL.dsn" default="" type="string">
<cfparam name="URL.db" default="" type="string">
<cfparam name="URL.table" default="" type="string">
<cfparam name="URL.couchHost" default="" type="string">
<cfparam name="URL.couchPort" default="" type="string">
<cfparam name="URL.couchDb" default="" type="string">
<cfparam name="URL.couchDb" default="" type="string">
<cfparam name="URL.maxRows" default="0" type="string">
<cfset dsn = trim(URL.dsn)>
<cfset dbName = trim(URL.db)>
<cfset tableName = trim(URL.table)>
<cfset couchHost = trim(URL.couchHost)>
<cfset couchPort = trim(URL.couchPort)>
<cfset couchDb = trim(URL.couchDb)>
<cfset maxRows = trim(URL.maxRows)>

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Relational Table to Couch Document Converter</title>
</head>
<body></cfoutput>

<cfif (dsn eq "")>
	<cfset sources = CreateObject("java","coldfusion.server.ServiceFactory").datasourceService.datasources>
	<cfoutput>
<p>Choose a datasource:</p>
<ul>
	<cfloop collection="#sources#" item="key">
	<li><a href="#thisPage#?dsn=#htmlEditFormat(sources[key].name)#">#htmlEditFormat(sources[key].name)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelseif (dbName eq "")>
	<cfdbinfo datasource="#dsn#" name="dbNames" type="dbnames">
	<cfoutput>
<p>Choose a database:</p>
<ul>
	<cfloop query="dbNames">
	<li><a href="#thisPage#?dsn=#htmlEditFormat(dsn)#&amp;db=#htmlEditFormat(dbNames.database_name)#">#htmlEditFormat(dbNames.database_name)#</a></li>
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
	<li><a href="#thisPage#?dsn=#htmlEditFormat(dsn)#&amp;db=#htmlEditFormat(dbName)#&amp;table=#htmlEditFormat(tableNames.table_name)#">#htmlEditFormat(tableNames.table_name)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelseif (couchHost eq "") or (couchPort eq "")>
	<cfoutput>
<cfform action="#thisPage#" method="get">
	<input type="hidden" name="dsn" value="#htmlEditFormat(dsn)#" />
	<input type="hidden" name="db" value="#htmlEditFormat(dbName)#" />
	<input type="hidden" name="table" value="#htmlEditFormat(tableName)#" />
	<label for="couchHost">CouchDB Host:</label> <cfinput type="text" size="32" name="couchHost" id="couchHost" required="true" validate="regular_expression" pattern="^([-a-zA-Z0-9]+.)*[-a-zA-Z0-9]+$" message="Please input a valid hostname"> <br />
	<label for="couchPort">CouchDB Port:</label> <cfinput type="text" size="6" name="couchPort" id="couchPort" required="true" validate="integer" message="Please input a valid port number" value="5984"> <br />
	<input type="submit" value="Continue" />
</cfform>
	</cfoutput>
<cfelseif (couchDb eq "")>
	<cfset dbs = new CouchDB(couchHost, couchPort).allDbs()>
	<cfoutput>
<p>Choose a target CouchDB database:</p>
<ul>
	<cfloop array="#dbs#" index="couchDb">
	<li><a href="#thisPage#?dsn=#htmlEditFormat(dsn)#&amp;db=#htmlEditFormat(dbName)#&amp;table=#htmlEditFormat(tableName)#&amp;couchHost=#htmlEditFormat(couchHost)#&amp;couchPort=#htmlEditFormat(couchPort)#&amp;couchDb=#htmlEditFormat(couchDb)#">#htmlEditFormat(couchDb)#</a></li>
	</cfloop>
</ul>
	</cfoutput>
<cfelse>
	<cfset couch = new CouchDB(couchHost, couchPort)>
	<cfset couch.db(couchDb)>
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#tableName#" name="foreign" type="foreignkeys">
	<cfdbinfo datasource="#dsn#" dbname="#dbName#" table="#tableName#" name="columns" type="columns">
	<cfquery name="primary" dbtype="query">
	SELECT column_name, type_name FROM columns WHERE is_primarykey = 'YES' ORDER BY ordinal_position
	</cfquery>
	<cfquery name="example" datasource="#dsn#" maxrows="#max(1,maxRows)#">
	SELECT * FROM #tableName#
	</cfquery>
	<cffunction name="singularify" returntype="string">
		<cfargument name="word" type="string" required="true">
		<cfreturn lcase(listLast(((right(arguments.word, 1) eq "s") and (right(arguments.word, 2) neq "ss")) ? (right(arguments.word, 3) eq "ies") ? left(arguments.word, len(arguments.word) - 3) & "y" : left(arguments.word, len(arguments.word) - 1) : arguments.word, "_"))>
	</cffunction>
	<cffunction name="prettyDate" returntype="string">
		<cfargument name="d" type="string" required="true">
		<cfreturn dateFormat(d, "yyyy-mm-dd") & "T" & timeFormat(d, "HH:mm:ss") & "Z">
	</cffunction>
	<cfset singleName = singularify(tableName)>
	<cfset colMap = {}>
	<cfloop query="columns">
		<cfif singleName eq left(column_name, len(singleName))>
			<cfset colMap[column_name] = lcase(replace(mid(column_name, len(singleName) + 1, len(column_name)), "_", "", "ALL"))>
		<cfelse>
			<cfset colMap[column_name] = lcase(replace(column_name, "_", "", "ALL"))>
		</cfif>
	</cfloop>
	<cfset fkMap = []>
	<cfset fkFields = {}>
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
	<cfloop query="example">
		<cfset data = { "_id" = singleName }>
		<cfloop query="primary">
			<cfset data["_id"] &= ":" & example[primary.column_name][example.currentRow]>
		</cfloop>
		<cfloop query="columns">
			<cfset fieldName = colMap[columns.column_name]>
			<cfset fieldVal = example[columns.column_name][example.currentRow]>
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
			FROM #fkInfo.table#
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
		<!---<cfoutput><pre>#serializeJson(data)#</pre></cfoutput>--->
		<cfif (maxRows eq 0)>
			<cfdump var="#data#" top="3">
		<cfelse>
			<cfset doc = couch.docFromId(data["_id"])>
			<cfif not structKeyExists(doc, "_id")>
				<cfset rev = couch.docInsert(data)>
				<cfif structKeyExists(rev, "rev") and structKeyExists(rev, "id")>
					<cfoutput><p>Inserted #rev.id# as #rev.rev#.</p></cfoutput>
				<cfelse>
					<cfdump var="#rev#" label="#data['_id']#">
				</cfif>
			<cfelse>
				<cfoutput><p>Skipping #htmlEditFormat(data["_id"])#.</p></cfoutput>
			</cfif>
		</cfif>
		<cfflush>
	</cfloop>
</cfif>


<cfoutput></body></html>
</cfoutput>