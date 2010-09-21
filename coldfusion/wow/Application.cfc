component {

this.root = getDirectoryFromPath(getCurrentTemplatePath());
this.name = "wow-armory " & hash(this.root);
this.datasource = "ricko";
this.sessionManagement = false;
this.clientManagement = false;
this.ormEnabled = true;
this.ormSettings = {
	"dialect"  = "MySQLwithInnoDB",
	"dbcreate" = "update"
};

public boolean function onRequestStart(required string pageName) {
	if (structKeyExists(URL, "reload")) {
		applicationStop();
		ormFlush();
		location(url = arguments.pageName, addtoken = false);
	}
	return true;
}

}