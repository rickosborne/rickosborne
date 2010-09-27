<cfheader name="Content-Type" value="text/xml">

<cfparam name="Form.ideEventInfo" default="" type="string">
<cftry>
<cfscript>
ide = Form.ideEventInfo;
data = xmlParse(ide);
selText = data.event.ide.editor.selection.text.xmlText;
selLen = len(selText);
start = 1;
lastEnd = 1;
newText = "";
while(start gt 0) {
	matches = reFindNoCase("[##]([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])([0-9a-f][0-9a-f])\b", selText, start, true);
	if(arrayLen(matches.pos) gt 1) {
		if(matches.pos[1] gt lastEnd) {
			newText = newText & mid(selText, lastEnd, matches.pos[1] - lastEnd);
		}
		r = inputBaseN(mid(selText, matches.pos[2], matches.len[2]), 16);
		g = inputBaseN(mid(selText, matches.pos[3], matches.len[3]), 16);
		b = inputBaseN(mid(selText, matches.pos[4], matches.len[4]), 16);
		newText = newText & "rgba(#r#,#g#,#b#,1.0)";
		lastEnd = matches.pos[1] + matches.len[1];
		if (lastEnd gt selLen)
			start = 0;
		else
			start = lastEnd;
	} else {
		start = 0;
	}
} // while
if (lastEnd lte selLen)
	newText = newText & mid(selText, lastEnd, selLen);
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