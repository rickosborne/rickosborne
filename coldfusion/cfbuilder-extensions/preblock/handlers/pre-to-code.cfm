<cfheader name="Content-Type" value="text/xml">

<cfparam name="Form.ideEventInfo" default="" type="string">
<cftry>
<cfscript>
ide = Form.ideEventInfo;
data = xmlParse(ide);
selText = trim(data.event.ide.editor.selection.text.xmlText);
className = "";
if (selText contains '<cf') { className = "coldfusion"; }
else if(reFindNoCase(selText, '(SELECT|DELETE)[[:space:]].*[[:space:]]FROM[[:space:]]|INSERT[[:space:]]+INTO|UPDATE[[:space:]].*[[:space:]]SET[[:space:]]') gt 0) { className = "sql"; }
else if(reFindNoCase(selText, '<[a-z]+[ >]') gt 0) { className = "html"; }
newText = '<pre';
if (className neq '') { newText = newText & ' class="#className#"'; }
newText = newText & '>' & replaceList(selText,"&,<,>","&amp;,&lt;,&gt;") & '</pre>';
</cfscript>
<cfcatch>
	<cfset newText = "Error: " & cfcatch.message>
</cfcatch>
</cftry>

<cfoutput><?xml version="1.0" encoding="utf-8"?>
<response status="success" showresponse="true">
	<ide>
		<commands>
			<command type="inserttext">
				<params>
					<param key="text"><![CDATA[ #newText# ]]></param>
				</params>
			</command>
		</commands>
	</ide>
</response></cfoutput>