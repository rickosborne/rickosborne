<!DOCTYPE html>
<html>
<head><title>Git Gateway Test Harness</title></head>
<body>
<cfscript>
// gg = new GitChat();
// gg.onBuddyStatus({ gatewayID = "Git - Chat", originatorID = "rick@sparrow", data = { buddynickname = "Rick O", buddystatus = "ONLINE", buddygroup = "Git Followers", timestamp = now() } });
gg = new GitWatch();
gg.onChange({ data = { "filename" = "K:\Rick\Source\rickosborne-github\.git\refs\heads\master", type = "CHANGE", "lastmodified" = now() }, "gatewayID" = "Git - Watch" });
writeDump(Application);
</cfscript>
</body>