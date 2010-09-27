component extends="SmartObject" persistent="true" table="wow_guild" {

property name="id" type="numeric" fieldtype="id" generated="never" generator="assigned" required="true" notnull="true";
property name="name" type="string" length="32" required="true" notnull="true";
property name="url" type="string" length="96" required="true" notnull="true";

}