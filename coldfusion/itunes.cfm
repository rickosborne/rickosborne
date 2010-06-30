<cfsetting enablecfoutputonly="true">

<cffunction name="fixQuotes" output="false" returntype="any">
	<cfargument name="s" type="String" required="true">
	<cfset var r = replace(arguments.s, '"', "'", "ALL")>
	<cfset r = '"' & replace(r, ",", "", "ALL") & '"'>
	<cfreturn r>
</cffunction>

<cfif structKeyExists(Form, "fileData")>
	<cfset tempDir = getTempDirectory()>
	<cffile action="upload" filefield="fileData" nameconflict="makeunique" result="fileUpload" destination="#tempDir#">
	<cfset result = structNew()>
	<cfset crLf = toString(chr(13) & chr(10)).getBytes()>
	<cfset result.cffr = fileUpload>
	<cfset inFile = fileUpload.serverDirectory & "/" & fileUpload.serverFile>
	<cfif (fileUpload.clientFileExt eq "xml")>
		<cfset itml = createObject("component", "iTunesMusicLibrary").queriesFromXMLFile(inFile)>
		<cfset did = createUUID()>
		<cfset didDir = tempDir & "/" & did>
		<cfdirectory action="create" directory="#didDir#">
		<cfset library = createObject("java", "java.io.FileOutputStream").init(createObject("java","java.io.File").init(didDir & "/iTunesLibrary.csv"))>
		<cfset libraryCols = listToArray(itml.library.columnList)>
		<cfloop from="1" to="#arrayLen(libraryCols)#" index="j">
			<cfif j eq 1><cfset v = ""><cfelse><cfset v=","></cfif>
			<cfset v = toString(v & fixQuotes(libraryCols[j])).getBytes()>
			<cfset library.write(v)>
		</cfloop>
		<cfset library.write(crLf)>
		<cfloop from="1" to="#itml.library.recordCount#" index="i">
			<cfloop from="1" to="#arrayLen(libraryCols)#" index="j">
				<cfif j eq 1><cfset v = ""><cfelse><cfset v=","></cfif>
				<cfset v = toString(v & fixQuotes(itml.library[libraryCols[j]][i])).getBytes()>
				<cfset library.write(v)>
			</cfloop>
			<cfset library.write(crlf)>
		</cfloop>
		<cfset library.flush()>
		<cfset library.close()>
		<cfset media = createObject("java", "java.io.FileOutputStream").init(createObject("java","java.io.File").init(didDir & "/iTunesMedia.csv"))>
		<cfset mediaCols = listToArray(itml.tracks.columnList)>
		<cfloop from="1" to="#arrayLen(mediaCols)#" index="j">
			<cfif j eq 1><cfset v = ""><cfelse><cfset v=","></cfif>
			<cfset v = toString(v & fixQuotes(mediaCols[j])).getBytes()>
			<cfset media.write(v)>
		</cfloop>
		<cfset media.write(crlf)>
		<cfloop from="1" to="#itml.tracks.recordCount#" index="i">
			<cfloop from="1" to="#arrayLen(mediaCols)#" index="j">
				<cfif j eq 1><cfset v = ""><cfelse><cfset v=","></cfif>
				<cfset v = toString(v & fixQuotes(itml.tracks[mediaCols[j]][i])).getBytes()>
				<cfset media.write(v)>
			</cfloop>
			<cfset media.write(crlf)>
		</cfloop>
		<cfset media.flush()>
		<cfset media.close()>
		<cfset zipFile = tempDir & "/" & did & ".zip">
		<cfzip action="zip" file="#zipFile#" overwrite="yes" recurse="yes" storepath="no" source="#didDir#">
		<cftry>
			<cffile action="delete" file="#didDir#/iTunesLibrary.csv">
			<cffile action="delete" file="#didDir#/iTunesMedia.csv">
			<cfdirectory action="delete" directory="#didDir#" recurse="true">
			<cffile action="delete" file="#inFile#">
			<cfcatch></cfcatch>
		</cftry>
		<cfheader name="Content-Disposition" value="attachment; filename=iTunesTables.zip">
		<cfcontent deletefile="true" file="#zipFile#" type="application/x-zip-compressed">
	<cfelse>
		<cftry>
			<cffile action="delete" file="#inFile#">
			<cfcatch></cfcatch>
		</cftry>
	</cfif>
	<cfexit>
</cfif>

<cfoutput><!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>iTunes Library-to-Table Converter</title>
</head>
<body>
</cfoutput>

<cfoutput>
<p>Please upload your iTunes Library XML file here.  On a Mac, this is located in:</p>
<blockquote><kbd>~/Music/iTunes/iTunes&nbsp;Music&nbsp;Library.xml</kbd></blockquote>
<form method="post" enctype="multipart/form-data" action="#htmlEditFormat(CGI.SCRIPT_NAME)#" id="uploadForm" name="uploadForm">
<input type="file" name="fileData"/>
<input type="submit"/>
</form>
</body>
</html>
</cfoutput>

<cfsetting enablecfoutputonly="false">