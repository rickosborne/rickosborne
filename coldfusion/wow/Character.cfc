component extends="SmartObject" persistent="true" table="wow_char" {

property name="realmName" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="name" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="charUrl" type="string" length="96" required="true" notnull="true";

property name="Realm" fieldtype="many-to-one" fkcolumn="realmName" cfc="Realm" cascade="all" required="true" notnull="true" insert="false" update="false";
property name="Gender" fieldtype="many-to-one" fkcolumn="gender_id" cfc="Gender" cascade="all" required="true" notnull="true";
property name="Race" fieldtype="many-to-one" fkcolumn="race_id" cfc="Race" cascade="all" required="true" notnull="true";
property name="Guild" fieldtype="many-to-one" fkcolumn="guild_id" cfc="Guild" cascade="all" required="false" notnull="false";
property name="CharClass" fieldtype="many-to-one" fkcolumn="class_id" cfc="CharClass" cascade="all" required="true" notnull="true";

/*
<character battleGroup="Vengeance" charUrl="r=Aegwynn&amp;cn=Vaken" class="Hunter"
 classId="3" contribution="2342" gamesPlayed="0" gamesWon="0" gender="Female" genderId="1"
 guild="Oh YA Prahhlly" guildId="9734230" guildUrl="r=Aegwynn&amp;gn=Oh+YA+Prahhlly"
 name="Vaken" race="Orc" raceId="2" realm="Aegwynn" seasonGamesPlayed="393"
 seasonGamesWon="249" teamRank="0"/>
*/

}