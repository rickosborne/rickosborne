component persistent="true" table="wow_bot_log" {

public numeric function startLog(required string objName, required string url) {
	local.q = new Query();
	q.setSql("INSERT INTO wow_bot_log (obj, url, started) VALUES (:objName, :url, now())");
	q.addParam(name = "objName", value = arguments.objName);
	q.addParam(name = "url", value = arguments.url);
	local.r = q.execute();
	return r.getPrefix().generatedKey;
}

public void function finishLog(required numeric id, required string status, required string mime, required string data) {
	local.q = new Query();
	q.setSql("UPDATE wow_bot_log SET status = :status, mime = :mime, data = :data, finished = now() WHERE (id = :id)");
	q.addParam(name = "status", value = arguments.status);
	q.addParam(name = "mime", value = arguments.mime);
	q.addParam(name = "data", value = arguments.data);
	q.addParam(name = "id", value = arguments.id);
	q.execute();
}

}