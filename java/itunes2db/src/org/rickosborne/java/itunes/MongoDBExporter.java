package org.rickosborne.java.itunes;

import java.net.UnknownHostException;
import java.util.Arrays;
import java.util.HashSet;
import java.util.Map;

import org.codehaus.jackson.map.util.StdDateFormat;

import com.mongodb.Mongo;
import com.mongodb.DBCollection;
import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.MongoException;
import com.mongodb.MongoInternalException;


public class MongoDBExporter extends NonRelationalExporter implements ItunesExporter {
	
	private DBCollection coll;
	private static StdDateFormat stdDateFormat = new StdDateFormat();
	private static HashSet<String> dateFields = new HashSet<String>( Arrays.asList("DateAdded,SkipDate,DateModified,PlayDateUTC".split(",")) );
	
	public MongoDBExporter(String db, String host, Integer port) throws Exception {
		System.out.println("Using MongoDB at " + host + ":" + port.toString() + "/" + db);
		typeMap.put("class com.mongodb.BasicDBList", "class [Ljava.lang.Integer;");
		try {
			coll = new Mongo(host, port).getDB(db).getCollection(db);
			// coll.remove(new BasicDBObject());
			coll.createIndex(new BasicDBObject("_id", 1));
			coll.createIndex(new BasicDBObject("type", 1));
			coll.createIndex(new BasicDBObject("artistkey", 1));
			coll.createIndex(new BasicDBObject("albumkey", 1));
		} catch (UnknownHostException e) {
			throw new Exception(String.format("Unknown host or port: %s:%d", host, port));
		} catch (MongoException e) {
			throw new Exception(String.format("Could not connect to mongod at %s:%d", host, port));
		} catch (MongoInternalException e) {
			throw new Exception(String.format("Could not connect to mongod at %s:%d", host, port));
		}
	}
	
	@SuppressWarnings("deprecation")
	@Override
	public boolean addTrack(Map<String, Object> trackInfo) {
		// System.out.println("Mongo:addTrack");
		for(String key: trackInfo.keySet()) {
			if (dateFields.contains(key)) {
				Object value = trackInfo.get(key);
				// System.out.println("Found date " + key + " of " + value.toString() + " (" + value.getClass().toString() + ")");
				java.util.Date d = null;
				if (value.getClass().equals(String.class)) {
					try {
						d = stdDateFormat.parse((String) value);
					} catch(Exception e) {
						e.printStackTrace();
					}
				} else if (value.getClass().equals(java.util.Date.class)) {
					d = (java.util.Date) value;
				}
				if (d != null) {
					// System.out.println("Fixing " + key + " of " + value);
					Integer da[] = new Integer[6];
					da[0] = d.getYear() + 1900;
					da[1] = d.getMonth();
					da[2] = d.getDay();
					da[3] = d.getHours();
					da[4] = d.getMinutes();
					da[5] = d.getSeconds();
					trackInfo.put(key, da);
				}
			}
		}
		return super.addTrack(trackInfo);
	}

	@Override
	protected String buildId(String type, String readable) {
		return (type != null ? type + ":" : "") + readable.replaceAll("[^a-zA-Z0-9]+", "").toLowerCase();
	}

	@SuppressWarnings("unchecked")
	@Override
	protected Map<String, Object> fetchOrCreateDoc(String docId) {
		BasicDBObject m = new BasicDBObject("_id", docId);
		DBObject d = coll.findOne(m);
		return ((d != null) ? d : m).toMap();
	}

	@Override
	protected void updateIfChanged(Map<String, Object> doc) {
		String docId = (String) doc.get("_id");
		String verb = "Skipping";
		boolean needsUpdate = false;
		Map<String, Object> existing = fetchDoc(docId); 
		if (existing != null) {
			if (docsDiffer(doc, existing)) {
				needsUpdate = true;
				verb = "Updating";
			}
		} else {
			verb = "Inserting";
			needsUpdate = true;
		}
		System.out.println(verb + ": " + docId);
		if (needsUpdate) {
			coll.save(new BasicDBObject(doc));
		}
	}

	@SuppressWarnings("unchecked")
	@Override
	protected Map<String, Object> fetchDoc(String docId) {
		BasicDBObject m = new BasicDBObject("_id", docId);
		DBObject d = coll.findOne(m);
		return (d != null) ? d.toMap() : null;
	}

}
