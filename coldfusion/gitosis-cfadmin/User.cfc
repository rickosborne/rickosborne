component persistent="true" table="gitosis_users" extends="TrackableEntity"  {

property name="ID" type="string" column="user_id" fieldtype="id" generated="insert" generator="assigned" required="true" notnull="true" insert="true";
property name="Email" type="string" column="user_email" required="true" notnull="true";
property name="PassHash" type="string" column="user_passhash" required="true" notnull="true";
property name="Name" type="string" column="user_name" required="true" notnull="true";
property name="Created" type="date" column="user_created" setter="false" required="false" notnull="false";
property name="Updated" type="date" column="user_updated" setter="false" required="false" notnull="false";
property name="Updater" type="string" column="user_updater" setter="false" required="false" notnull="false";
property name="Confirm" type="string" column="user_confirm" required="false" notnull="false";

property name="UpdatedBy" fieldtype="many-to-one" cfc="User" fkcolumn="user_updater" update="false" insert="false" lazy="true";

}