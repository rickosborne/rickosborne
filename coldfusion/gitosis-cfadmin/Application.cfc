component {

	this.root = getDirectoryFromPath(getCurrentTemplatePath());
	this.name = "Gitosis CFAdmin " & hash(this.root);
	this.sessionManagement = true;
	this.clientManagement  = false;
	this.scriptProtect     = true;

}