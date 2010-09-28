<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfset conf = new GitosisConf(expandPath("../../../alfalfa-gitosis/gitosis.conf"))>
<!---<cfcontent type="application/xhtml+xml">--->

<cfoutput><?xml version="1.0" encoding="utf-8" ?>
<!DOCTYPE html>
<html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Gitosis Admin</title>
</head>
<body>
<h1>Gitosis Admin</h1>
<p>Repositories: <cfloop array="#conf.repoNames()#" index="repoName"> #xmlFormat(repoName)# </cfloop></p>
<p>Groups: <cfloop array="#conf.groupNames()#" index="groupName"> #xmlFormat(groupName)# </cfloop></p>
</cfoutput>


<cfoutput>
</body>
</html>
</cfoutput>