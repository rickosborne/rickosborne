package org.rickosborne.java.itunes;

import java.net.URL;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;

import org.codehaus.jackson.map.ObjectMapper;
import org.codehaus.jackson.map.SerializationConfig.Feature;
import org.codehaus.jackson.map.util.StdDateFormat;
import org.ektorp.CouchDbConnector;
import org.ektorp.CouchDbInstance;
import org.ektorp.http.HttpClient;
import org.ektorp.http.StdHttpClient;
import org.ektorp.impl.StdCouchDbConnector;
import org.ektorp.impl.StdCouchDbInstance;
import org.rickosborne.java.itunes.ItunesExporter;

public class CouchDBExporter extends NonRelationalExporter implements ItunesExporter {
	
	private HttpClient httpclient;
	private CouchDbInstance dbInstance;
	private CouchDbConnector db;
	private Class<?> docClass;
	private static StdDateFormat stdDateFormat = new StdDateFormat();
	private static HashSet<String> dateFields = new HashSet<String>( Arrays.asList("DateAdded,SkipDate,DateModified,PlayDateUTC".split(",")) );
	
	public CouchDBExporter(URL couchUrl) {
		super();
		String userName = "";
		String password = "";
		if (couchUrl.getUserInfo() != null) {
			String[] userinfo = couchUrl.getUserInfo().split(":");
			if (userinfo.length > 0)
				userName = userinfo[0];
			if (userinfo.length > 1)
				password = userinfo[2];
		}
		httpclient = new StdHttpClient.Builder()
			.host(couchUrl.getHost())
			.port(couchUrl.getPort())
			.username(userName)
			.password(password)
			.build();
		dbInstance = new StdCouchDbInstance(httpclient);
		String dbName = couchUrl.getPath().split("/")[1];
		ObjectMapper om = new ObjectMapper();
		om.configure(Feature.WRITE_DATES_AS_TIMESTAMPS, false);
		om.getDeserializationConfig().setDateFormat(StdDateFormat.instance);
		db = new StdCouchDbConnector(dbName, dbInstance, om);
		db.createDatabaseIfNotExists();
		docClass = (new HashMap<String,Object>()).getClass();
	}

	protected String buildId(String type, String readable) {
		// System.out.println("CouchDBExporter:buildID: " + type + ", " + readable);
		return (type != null ? type + ":" : "") + readable.replaceAll("[^a-zA-Z0-9]+", "").toLowerCase();
	}
	
	protected Map<String,Object> fetchOrCreateDoc(String docId) {
		if (db.contains(docId))
			return fetchDoc(docId);
		HashMap<String,Object> doc = new HashMap<String,Object>();
		doc.put("_id", docId);
		return doc;
	}
	
	@SuppressWarnings("unchecked")
	protected Map<String,Object> fetchDoc(String docId) {
		Map<String,Object> doc = (Map<String, Object>) db.get(docClass, docId);
		// System.out.println(doc);
		// Holy crap what a hack
		for(String key: doc.keySet()) {
			if (dateFields.contains(key)) {
				Object value = doc.get(key);
				if (value.getClass().equals(String.class)) {
					try {
						doc.put(key, stdDateFormat.parse((String) value));
					} catch(Exception e) {
						e.printStackTrace();
					}
				}
			}
		}
		return doc;
	}
	
	protected void updateIfChanged(Map<String, Object> doc) {
		String docId = (String) doc.get("_id");
		String verb = "Skipping";
		boolean needsUpdate = false;
		if (db.contains(docId)) {
			Map<String, Object> existing = fetchDoc(docId);
			if (docsDiffer(doc, existing)) {
				if (existing.containsKey("_rev"))
					doc.put("_rev", (String) existing.get("_rev"));
				else {
					System.out.println("Missing rev: " + existing.toString());
				}
				needsUpdate = true;
				verb = "Updating";
			}
		} else {
			verb = "Inserting";
			needsUpdate = true;
		}
		System.out.println(verb + ": " + docId);
		if (needsUpdate) {
			db.update(doc);
		}
	} // updateIfChanged

}
