component extends="User" persistent="true" table="gitosis_system_admins" joincolumn="user_id" {

property name="Admin" type="boolean" default="true" insert="false" update="false" formula="1";

public boolean function isAdmin() { return true; }

}