component extends="ArmoryBot" persistent="true" table="wow_arena_team" {

property name="realmName" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="name" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="created" type="numeric" ormtype="long" required="true" notnull="true";
property name="gamesPlayed" ormtype="int" type="numeric" required="false";
property name="gamesWon" ormtype="int" type="numeric" required="false";
property name="lastSeasonRanking" ormtype="int" type="numeric" required="false";
property name="ranking" ormtype="int" type="numeric" required="false";
property name="rating" ormtype="int" type="numeric" required="false";
property name="season" ormtype="int" type="numeric" required="false";
property name="seasonGamesPlayed" ormtype="int" type="numeric" required="false";
property name="seasonGamesWon" ormtype="int" type="numeric" required="false";
property name="size" ormtype="short" type="numeric" required="false";
property name="teamSize" ormtype="short" type="numeric" required="false";
property name="teamUrl" type="string" length="128" required="false";
property name="tournament" ormtype="short" type="numeric" required="false";
property name="url" type="string" length="128" required="false";

property name="Realm" fieldtype="many-to-one" fkcolumn="realmName" cfc="Realm" cascade="all" required="true" notnull="true" insert="false" update="false";
property name="Faction" fieldtype="many-to-one" fkcolumn="faction_id" cfc="Faction" cascade="all" required="true" notnull="true";
property name="Members" fieldtype="one-to-many" fkcolumn="realmName,teamName" cfc="TeamMember" cascade="all" singularname="Member";

/*
<arenaTeam battleGroup="Bloodlust" created="1260576000000" faction="Horde" factionId="1"
 gamesPlayed="0" gamesWon="0" lastSeasonRanking="19" name="G O D M O D E" ranking="1"
 rating="2938" realm="Blackrock" realmUrl="b=Bloodlust&amp;r=Blackrock&amp;ts=2&amp;t=G+O+D+M+O+D+E&amp;ff=realm&amp;fv=Blackrock&amp;select=G+O+D+M+O+D+E"
 relevance="0" season="0" seasonGamesPlayed="373" seasonGamesWon="291" size="2"
 teamSize="2" teamUrl="r=Blackrock&amp;ts=2&amp;t=G+O+D+M+O+D+E&amp;select=G+O+D+M+O+D+E"
 url="r=Blackrock&amp;ts=2&amp;t=G+O+D+M+O+D+E&amp;select=G+O+D+M+O+D+E">
	<emblem background="ff000000" borderColor="ffff957a" borderStyle="1" iconColor="fff2fffe" iconStyle="47"/>
</arenaTeam>

<character battleGroup="Vengeance" charUrl="r=Aegwynn&amp;cn=Vaken" class="Hunter"
 classId="3" contribution="2342" gamesPlayed="0" gamesWon="0" gender="Female" genderId="1"
 guild="Oh YA Prahhlly" guildId="9734230" guildUrl="r=Aegwynn&amp;gn=Oh+YA+Prahhlly"
 name="Vaken" race="Orc" raceId="2" realm="Aegwynn" seasonGamesPlayed="393"
 seasonGamesWon="249" teamRank="0"/>

*/

public void function fetchMembers() {
	local.xml = super.fetch("http://www.wowarmory.com/team-info.xml?" & getTeamUrl());
	local.chars = xmlSearch(xml, "/page/teamInfo/arenaTeam/members/character");
	for (local.c = 1; c lte arrayLen(chars); c++) {
		local.attrs = duplicate(chars[c].xmlAttributes);
		local.ma = {
			realmName = attrs.realm,
			teamName  = getName(),
			charName  = attrs.name,
			gamesPlayed = attrs.gamesPlayed,
			gamesWon = attrs.gamesWon,
			seasonGamesPlayed = attrs.seasonGamesPlayed,
			seasonGamesWon = attrs.seasonGamesWon,
			teamRank = attrs.teamRank,
			contribution = attrs.contribution
		};
		structDelete(attrs, "battleGroup");
		attrs.charClass = loadOrNew("CharClass", [ "id" ], { id = attrs.classId, name = attrs.class });
		structDelete(attrs, "classId");
		structDelete(attrs, "class");
		attrs.gender = loadOrNew("Gender", [ "id" ], { id = attrs.genderId, name = attrs.gender });
		structDelete(attrs, "genderId");
		if (structKeyExists(attrs, "guild")) {
			attrs.guild = loadOrNew("Guild", [ "id" ], { id = attrs.guildId, name = attrs.guild, url = attrs.guildUrl });
		}
		structDelete(attrs, "guildId");
		structDelete(attrs, "guildUrl");
		attrs.race = loadOrNew("Race", [ "id" ], { id = attrs.raceId, name = attrs.race });
		structDelete(attrs, "raceId");
		structDelete(attrs, "teamRank");
		structDelete(attrs, "gamesPlayed");
		structDelete(attrs, "gamesWon");
		structDelete(attrs, "seasonGamesPlayed");
		structDelete(attrs, "seasonGamesWon");
		structDelete(attrs, "contribution");
		attrs.realmName = attrs.realm;
		attrs.realm = entityLoadByPk("Realm", attrs.realmName);
		local.char = loadOrNew("Character", [ "realmName", "name" ], attrs);
		local.member = loadOrNew("TeamMember", [ "realmName", "teamName", "charName" ], ma);
		entitySave(char);
		entitySave(member);
		ormFlush();
	} // for c
} // fetchDetail

}