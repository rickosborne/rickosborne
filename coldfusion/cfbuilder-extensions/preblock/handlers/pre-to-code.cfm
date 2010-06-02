<cfheader name="Content-Type" value="text/xml">

<cfparam name="Form.ideEventInfo" default="" type="string">
<cftry>
<cfscript>
ide = Form.ideEventInfo;
data = xmlParse(ide);
selText = trim(data.event.ide.editor.selection.text.xmlText);
newText = reReplaceNoCase(selText, '^<pre[^>]*>|</pre>$', "", "ALL");
newText = replaceList(newText, '&lt;,&gt;,&amp;','<,>,&');
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