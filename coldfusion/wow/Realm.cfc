component extends="SmartObject" persistent="true" table="wow_realm" {

property name="name" type="string" length="32" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="nameEN" type="string" length="32" required="true" notnull="true";
property name="nameUrl" type="string" length="32" required="true" notnull="true";

property name="Battlegroup" fieldtype="many-to-one" fkcolumn="bgName" cfc="Battlegroup" cascade="all" required="true" notnull="true";

}