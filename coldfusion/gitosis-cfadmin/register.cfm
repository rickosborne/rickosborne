<cfsetting enablecfoutputonly="true" showdebugoutput="false">

<cfscript>
param name="Form.name" type="string" default="";
param name="Form.email" type="string" default="";
param name="Form.password1" type="string" default="";
param name="Form.password2" type="string" default="";
fullname = trim(Form.name);
email = lcase(trim(Form.email));
password1 = trim(Form.password1);
password2 = trim(Form.password2);
gotAny = false;
userCreated = false;
messages = [];
if (reFind("^[A-Z][-A-Za-z]+( [A-Z][-A-Za-z]+)+$", fullname) eq 1)
	gotAny = true;
else
	arrayAppend(messages, "Please provide your full name in Firstname Lastname format.");
if (isValid("email", email) and (email contains "@fullsail."))
	gotAny = true;
else
	arrayAppend(messages, "Please provide your Full Sail email address.");
if ((password1 neq "") and (password2 eq password1))
	gotAny = true;
else
	arrayAppend(messages, "Please provide and confirm your password.");
if (gotAny and (arrayLen(messages) eq 0)) {
	lock name = "GitosisUser" type="exclusive" timeout="5" {
		user = entityLoad("User", { email = email });
		if (arrayLen(user) eq 0) {
			user = entityNew("User", {
				name = fullname,
				email = email,
				passhash = hash(email & password1)
			});
			entitySave(user);
			ormFlush();
			Session['user'] = user.toStruct();
			location(url = "./", addtoken = false);
			userCreated = true;
		} // if no matching user
		else
			arrayAppend(messages, "That email address is already registered.");
	} // lock
} // if data looks valid

if (not gotAny)
	messages = [];

Application.View
	.showHeader("Register")
	.showRegistrationForm(fullname, email, messages)
	.showFooter();
</cfscript>