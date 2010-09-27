component extends="SmartObject" persistent="true" table="wow_arena_team_member" {

property name="realmName" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="teamName" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="charName" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";

property name="gamesPlayed" type="numeric" ormtype="short" required="false" notnull="false";
property name="gamesWon" type="numeric" ormtype="short" required="false" notnull="false";
property name="seasonGamesPlayed" type="numeric" ormtype="short" required="false" notnull="false";
property name="seasonGamesWon" type="numeric" ormtype="short" required="false" notnull="false";
property name="teamRank" type="numeric" ormtype="short" required="false" notnull="false";
property name="contribution" type="numeric" ormtype="short" required="false" notnull="false";

property name="Realm" fieldtype="many-to-one" fkcolumn="realmName" cfc="Realm" insert="false" update="false" inverse="true";
property name="Team" fieldtype="many-to-one" fkcolumn="realmName,teamName" cfc="ArenaTeam" insert="false" update="false" inverse="true";
property name="Char" fieldtype="many-to-one" fkcolumn="realmName,charName" cfc="Character" insert="false" update="false" inverse="true";

/*
<character battleGroup="Vengeance" charUrl="r=Aegwynn&amp;cn=Vaken" class="Hunter"
 classId="3" contribution="2342" gamesPlayed="0" gamesWon="0" gender="Female" genderId="1"
 guild="Oh YA Prahhlly" guildId="9734230" guildUrl="r=Aegwynn&amp;gn=Oh+YA+Prahhlly"
 name="Vaken" race="Orc" raceId="2" realm="Aegwynn" seasonGamesPlayed="393"
 seasonGamesWon="249" teamRank="0"/>

<arenaTeam battleGroup="Bloodlust" created="1260576000000" faction="Horde" factionId="1"
 gamesPlayed="0" gamesWon="0" lastSeasonRanking="19" name="G O D M O D E" ranking="1"
 rating="2938" realm="Blackrock" realmUrl="b=Bloodlust&amp;r=Blackrock&amp;ts=2&amp;t=G+O+D+M+O+D+E&amp;ff=realm&amp;fv=Blackrock&amp;select=G+O+D+M+O+D+E"
 relevance="0" season="0" seasonGamesPlayed="373" seasonGamesWon="291" size="2"
 teamSize="2" teamUrl="r=Blackrock&amp;ts=2&amp;t=G+O+D+M+O+D+E&amp;select=G+O+D+M+O+D+E"
 url="r=Blackrock&amp;ts=2&amp;t=G+O+D+M+O+D+E&amp;select=G+O+D+M+O+D+E">
	<emblem background="ff000000" borderColor="ffff957a" borderStyle="1" iconColor="fff2fffe" iconStyle="47"/>
</arenaTeam>
*/

}