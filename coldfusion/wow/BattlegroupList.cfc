component extends="ArmoryBot" {

public any function init() {
	super.init();
	variables.basehref = "http://www.wowarmory.com/battlegroups.xml";
}

public void function fetch() {
	local.xml = super.fetch(variables.basehref);
	local.bgs = xmlSearch(xml, "/page/battlegroups/battlegroup");
	for(local.i = 1; i lte arrayLen(bgs); i++) {
		local.bg = loadOrNew("Battlegroup", [ "name" ], bgs[i].xmlAttributes);
		local.realms = xmlSearch(xml, "/page/battlegroups/battlegroup[@name='#xmlFormat(bg.getName())#']/realms/realm");
		for(local.j = 1; j lte arrayLen(realms); j++) {
			local.realm = loadOrNew("Realm", [ "name" ], realms[j].xmlAttributes);
			realm.setBattlegroup(bg);
			entitySave(realm);
		} // for j
		entitySave(bg);
	} // for i
} // fetch


}