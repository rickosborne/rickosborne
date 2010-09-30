<cfcomponent hint="I contain all of the View functions for the Portal">

<cffunction name="showHeader" access="public" returntype="any">
	<cfargument name="pageTitle" type="string" default="">
	<cfargument name="userInfo" type="struct" default="#structNew()#">
	<cfset local.thisPage = lcase(listFirst(getFileFromPath(getBaseTemplatePath()),"."))>
	<cfif (local.thisPage eq "index") or (local.thisPage eq "gitosis-admin")>
		<cfset local.thisPage = "./">
	</cfif>
	<cfoutput><?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
	<title>#pageTitle# :: WDDBS Git Repositories</title>
	<link rel="stylesheet" type="text/css" href="http://yui.yahooapis.com/combo?3.1.0/build/cssfonts/fonts-min.css&3.1.0/build/cssreset/reset-min.css&3.1.0/build/cssgrids/grids-min.css&3.1.0/build/cssbase/base-min.css&3.1.0/build/widget/assets/skins/sam/widget.css&3.1.0/build/tabview/assets/skins/sam/tabview.css" />
	<link rel="stylesheet" type="text/css" href="gitosis-admin.css" />
	<script language="JavaScript" type="text/javascript" src="yui-min.js"></script>
	<script language="JavaScript" type="text/javascript" src="gitosis-admin.js" defer="defer"></script>
</head>
<body class="asl">

<div id="title" class="no-print">
	<div class="ribbon">
		<h1>WDDBS Git Repositories</h1>
	</div>
	<div class="triangle-l"></div>
	<div class="triangle-r"></div>
</div>

<div id="page" class="yui3-widget yui3-tabview">
<div id="content" class="yui3-widget yui3-tabview yui3-tabview-content">
<ul class="no-print yui3-tabview-list">
	#_makeTabLink("Home",      "./",      local.thisPage)#
<cfif structKeyExists(userInfo, "admin") and (userInfo.admin eq "yes")>
	#_makeTabLink("Mail Test",      "mail-test.cfm",      local.thisPage)#
</cfif>
<cfif structKeyExists(userInfo, "ID")>
	#_makeTabLink("Logout",      "logout.cfm",                   local.thisPage)#
<cfelse>
	#_makeTabLink("Register", "register.cfm", local.thisPage)#
	#_makeTabLink("Log In",   "login.cfm",    local.thisPage)#
</cfif>
</ul>
<div class="yui3-tabview-panel">
	</cfoutput>
	<cfreturn this>
</cffunction>

<cffunction name="_makeTabLink" access="private" returntype="string">
	<cfargument name="title" type="string" default="">
	<cfargument name="href" type="string" default="">
	<cfargument name="thisPage" type="string" default="">
	<cfset local.classNames = "yui3-tab yui3-widget" & ((arguments.href contains arguments.thisPage) or ((arguments.thisPage contains "day") and (arguments.href contains "course_examples")) ? " yui3-tab-selected" : "")>
	<cfreturn '<li class="#local.classNames#" role="presentation"><a href="#arguments.href#" class="yui3-tab-label yui3-tab-content" role="tab">#arguments.title#</a></li>'>
</cffunction>

<cffunction name="showRegistrationForm" access="public" returntype="any">
	<cfargument name="fullname" type="string" required="true">
	<cfargument name="email" type="string" required="true">
	<cfargument name="messages" type="array" required="true">
	<cfoutput>
<h1>Register A New Account</h1>
<p>Faculty and students of Full Sail University may register for access to this system.  Complete and submit this form, and further information will be emailed to you.</p>
<cfform action="#CGI.SCRIPT_NAME#" method="post" name="register" id="register">
<cfif (arrayLen(messages) gt 0)>
<ul class="err">
	<li>#arrayToList(messages,"</li><li>")#</li>
</ul>
</cfif>
<table>
	<tr>
		<td class="label"><label for="name">Full Name:</label></td>
		<td class="data"><cfinput name="name" id="name" type="text" validate="regular_expression" pattern="^[A-Z][-A-Za-z]+( [A-Z][-A-Za-z]+)+$" required="true" title="Full Name" placeholder="Firstname Lastname" autofocus="autofocus" message="Please provide your full name, in Firstname Lastname format." size="24" maxlength="24" value="#xmlFormat(fullname)#"></td>
	</tr>
	<tr>
		<td class="label"><label for="email">Email Address:</label></td>
		<td class="data"><cfinput name="email" id="email" type="text" type5="email" validate="email" required="true" placeholder="yourname@fullsail.edu" title="Email Address" message="Please provide your Full Sail email address." size="24" maxlength="24" value="#xmlFormat(email)#"></td>
	</tr>
	<tr>
		<td class="label"><label for="password1">Password:</label></td>
		<td class="data"><cfinput name="password1" id="password1" type="password" required="true" size="16" message="Please provide your password." maxlength="16" value=""></td>
	</tr>
	<tr>
		<td class="label"><label for="password2">Confirm Password:</label></td>
		<td class="data"><cfinput name="password2" id="password2" type="password" required="true" size="16" message="Please provide your password." maxlength="16" value=""></td>
	</tr>
	<tr>
		<td class="label">&nbsp;</td>
		<td class="data"><input type="submit" value="Continue" /></td>
	</tr>
</table>
	</cfform>
	</cfoutput>
	<cfreturn this>
</cffunction>


<cffunction name="showLoginForm" access="public" returntype="any">
	<cfargument name="email" type="string" required="true">
	<cfargument name="messages" type="array" required="true">
	<cfoutput>
<h1>Log In</h1>
<cfform action="#CGI.SCRIPT_NAME#" method="post" name="register" id="register">
<cfif (arrayLen(messages) gt 0)>
<ul class="err">
	<li>#arrayToList(messages,"</li><li>")#</li>
</ul>
</cfif>
<table>
	<tr>
		<td class="label"><label for="email">Email Address:</label></td>
		<td class="data"><cfinput name="email" id="email" type="text" type5="email" validate="email" required="true" placeholder="yourname@fullsail.edu" title="Email Address" message="Please provide your Full Sail email address." size="24" maxlength="24" value="#xmlFormat(email)#"></td>
	</tr>
	<tr>
		<td class="label"><label for="password">Password:</label></td>
		<td class="data"><cfinput name="password" id="password" type="password" required="true" size="16" message="Please provide your password." maxlength="16" value=""></td>
	</tr>
	<tr>
		<td class="label">&nbsp;</td>
		<td class="data"><input type="submit" value="Continue" /></td>
	</tr>
</table>
	</cfform>
	</cfoutput>
	<cfreturn this>
</cffunction>

<cffunction name="showHomePage" access="public" returntype="any">
	<cfif structKeyExists(Session, "User")>
		<cfoutput>
		<!---<cfdump var="#entityLoadByPk('User', Session.User.ID)#">
		<cfdump var="#entityToQuery(entityLoadByPk('User', Session.User.ID))#">--->
		<cfdump var="#Session.User#">
		</cfoutput>
	</cfif>
	<cfreturn this>
</cffunction>

<cffunction name="showFooter" access="public" returntype="any">
	<cfoutput>
	</div>
</div>
</div>
</body>
</html>
	</cfoutput>
	<cfreturn this>
</cffunction>

</cfcomponent>