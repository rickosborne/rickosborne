component extends="ArmoryBot" persistent="true" table="wow_battlegroup" {

property name="name" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="display" type="string" length="32" required="true" notnull="true";
property name="ladderUrl" type="string" length="32" required="true" notnull="true";
property name="sortPosition" type="numeric" ormtype="short" required="true" notnull="true";
property name="tournamentBattleGroup" type="numeric" ormtype="short" required="false" notnull="false";

public any function fetchArena(required numeric teamSize) {
	local.u = "http://www.wowarmory.com/arena-ladder.xml?ts=" & int(arguments.teamSize) & "&" & getLadderUrl();
	local.xml = super.fetch(local.u);
	local.teams = xmlSearch(xml, "/page/arenaLadderPagedResult/arenaTeams/arenaTeam");
	for(local.i = 1; i lte arrayLen(teams); i++) {
		local.t = loadOrNew("ArenaTeam", "name", teams[i].xmlAttributes);
	} // for i
} // fetchArena

}