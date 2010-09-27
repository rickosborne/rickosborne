component extends="ArmoryBot" persistent="true" table="wow_battlegroup" {

property name="name" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="display" type="string" length="32" required="true" notnull="true";
property name="ladderUrl" type="string" length="32" required="true" notnull="true";
property name="sortPosition" type="numeric" ormtype="short" required="true" notnull="true";
property name="tournamentBattleGroup" type="numeric" ormtype="short" required="false" notnull="false";

public any function fetchArena(required numeric teamSize, numeric pageNum = 1) {
	local.u = "http://www.wowarmory.com/arena-ladder.xml?ts=" & int(arguments.teamSize) & (arguments.pageNum gt 1 ? "&p=" & int(arguments.pageNum) : "" ) & "&" & getLadderUrl();
	local.xml = super.fetch(local.u);
	local.teams = xmlSearch(xml, "/page/arenaLadderPagedResult/arenaTeams/arenaTeam");
	for(local.i = 1; i lte arrayLen(teams); i++) {
		local.attrs = duplicate(teams[i].xmlAttributes);
		// local.realm = entityLoad("Realm", { name = attrs.realm });
		attrs["realmName"] = attrs.realm;
		structDelete(attrs, "realm");
		attrs.faction = loadOrNew("Faction", [ "name" ], { id = attrs.factionId, name = attrs.faction });
		structDelete(attrs, "factionId");
		// structDelete(attrs, "faction");
		structDelete(attrs, "battlegroup");
		structDelete(attrs, "relevance");
		structDelete(attrs, "realmUrl");
		local.t = loadOrNew("ArenaTeam", [ "name", "realmName" ], attrs);
		// t.setBattlegroup(this);
		// t.setRealm(realm);
		entitySave(t);
		ormFlush();
	} // for i
} // fetchArena

}