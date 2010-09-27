<cfsetting showdebugoutput="false">
<cfscript>
bgList = new BattlegroupList();
bgList.fetch();
/*
bgs = entityLoad("Battlegroup");
for(b = 1; b lte arrayLen(bgs); b++) {
	bg = bgs[b];
	for(local.p = 1; p lte 5; p++) {
		bg.fetchArena(2, p);
		bg.fetchArena(3, p);
		bg.fetchArena(5, p);
	} // for p
} // for b
*/
// teams = entityLoad("ArenaTeam");
teams = ormExecuteQuery("SELECT t FROM ArenaTeam t LEFT JOIN FETCH t.Members AS m WHERE m.charName IS NULL");
for (t = 1; (t lte arrayLen(teams)) and (t lte 1000); t++) {
	team = teams[t];
	team.fetchMembers();
}
</cfscript>