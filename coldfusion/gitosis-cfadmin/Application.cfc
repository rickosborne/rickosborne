component {

	this.root = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = "Gitosis CFAdmin " & hash(this.root);
	this.sessionManagement = true;
	this.clientManagement  = false;
	this.scriptProtect     = true;
	this.datasource        = "gitosis-admin";
	this.ormEnabled        = true;
	this.ormSettings = {
		dialect = "MySqlWithInnoDB",
		eventHandling = true
	};

	public boolean function onRequestStart(required string pageName) {
		if (structKeyExists(URL, "reload")) {
			applicationStop();
			location(url=arguments.pageName, addtoken=false);
		}
		Application.conf = new GitosisConf("/Users/rosborne/Source/gitosis-admin/gitosis.conf");
		Application.view = new View();
		return true;
	} // onRequestStart

}