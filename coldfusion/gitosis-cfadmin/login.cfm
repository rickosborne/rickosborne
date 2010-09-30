<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfscript>
if (structKeyExists(Session, "user"))
	location(url = "./", addtoken = false);
param name="Form.email" type="string" default="";
param name="Form.password" type="string" default="";
email = lcase(trim(Form.email));
password = trim(Form.password);
messages = [];
if (isValid("email", email) and (password neq "")) {
	lock name="GitosisUser" type="exclusive" timeout="5" {
		user = entityLoad("User", {
			email = email,
			passhash = hash(email & password)
		});
		if (arrayLen(user) eq 1) {
			Session.user = user[1].toStruct();
			location(url = "./", addtoken = false);
		}
		else
			arrayAppend(messages, "Unknown email address or bad password.");
	} // lock
}

Application.View
	.showHeader("Login")
	.showLoginForm(email, messages)
	.showFooter();
</cfscript>