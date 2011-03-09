package org.rickosborne.java.itunes;

import java.net.URL;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

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

public class CouchDBExporter implements ItunesExporter {
	
	private HttpClient httpclient;
	private CouchDbInstance dbInstance;
	private CouchDbConnector db;
	private Class<?> docClass;
	private static StdDateFormat stdDateFormat = new StdDateFormat();
	private static HashSet<String> dateFields = new HashSet<String>( Arrays.asList("DateAdded,SkipDate,DateModified,PlayDateUTC".split(",")) );
	
	public CouchDBExporter(URL couchUrl) {
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

	public boolean addTrack(Map<String, Object> trackInfo) {
		String trackId = buildId("track", (String) trackInfo.get("PersistentID"));
		trackInfo.put("_id", trackId);
		trackInfo.put("type", "track");
		String album = (String) trackInfo.get("Album");
		String artist = (String) trackInfo.get("Artist");
		String albumArtist = (String) trackInfo.get("AlbumArtist");
		String albumId = null;
		if (album != null) {
			albumId = buildId("album", album);
			addItemToSet("album", album, "Album", "tracks", trackId);
			trackInfo.put("albumkey", albumId);
		}
		if (artist != null) {
			trackInfo.put("artistkey", buildId("artist", artist));
			addItemToSet("artist", artist, "Artist", "tracks", trackId);
			if (album != null)
				addItemToSet("artist", artist, "Artist", "albums", albumId);
		}
		if (albumArtist != null) {
			if (artist == null)
				trackInfo.put("artistkey", buildId("artist", artist));
			addItemToSet("artist", albumArtist, "Artist", "tracks", trackId);
			if (album != null)
				addItemToSet("artist", albumArtist, "Artist", "albums", albumId);
		}
		updateIfChanged(trackInfo);
		return true;
	}

	public void addColumns(Set<String> columnNames) {}

	public boolean close() { return true; }

	public boolean addLibraryInfo(Map<String, Object> libraryInfo) {
		if (! libraryInfo.containsKey("LibraryPersistentID")) return false;
		String docId = buildId("library",(String) libraryInfo.get("LibraryPersistentID"));
		libraryInfo.put("_id", docId);
		libraryInfo.put("type", "library");
		updateIfChanged(libraryInfo);
		return false;
	}
	
	private static String buildId(String type, String readable) {
		return (type != null ? type + ":" : "") + readable.replaceAll("[^a-zA-Z0-9]+", "").toLowerCase();
	}
	
	@SuppressWarnings("unchecked")
	private void addItemToSet(String docType, String title, String titleKey, String setKey, String item) {
		Map<String, Object> doc = fetchOrCreateDoc(buildId(docType, title));
		if (! doc.containsKey(titleKey))
			doc.put(titleKey, title);
		if (! doc.containsKey("type"))
			doc.put("type", docType);
		ArrayList<String> set = null;
		try {
			set = (ArrayList<String>) doc.get(setKey);
			if ((set != null) && set.contains(item)) return;
		} catch(Exception e) {
			e.printStackTrace();
		}
		if (set == null) set = new ArrayList<String>();
		set.add(item);
		doc.put(setKey, set);
		updateIfChanged(doc);
	}
	
	private Map<String,Object> fetchOrCreateDoc(String docId) {
		if (db.contains(docId))
			return fetchDoc(docId);
		HashMap<String,Object> doc = new HashMap<String,Object>();
		doc.put("_id", docId);
		return doc;
	}
	
	@SuppressWarnings("unchecked")
	private Map<String,Object> fetchDoc(String docId) {
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
	
	@SuppressWarnings("unused")
	private void updateDoc(Map<String, Object> doc) {
		System.out.println("Updating: " + doc.get("_id"));
		db.update(doc);
	}
	
	private void updateIfChanged(Map<String, Object> doc) {
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
	
	private static boolean docsDiffer(Map<String, Object> a, Map<String, Object> b) {
		TreeSet<String> aKeys = new TreeSet<String>(a.keySet());
		TreeSet<String> bKeys = new TreeSet<String>(b.keySet());
		// We don't care if revisions differ
		if (aKeys.contains("_rev")) aKeys.remove("_rev");
		if (bKeys.contains("_rev")) bKeys.remove("_rev");
		if (! aKeys.equals(bKeys)) {
			System.out.println("Keys differ: " + aKeys.toString() + " :: " + bKeys.toString());
			return true;
		}
		for (String key: aKeys) {
			// if ("_rev".equals(key)) continue;
			Object aVal = a.get(key);
			Object bVal = b.get(key);
			if (! aVal.getClass().equals(bVal.getClass())) {
				System.out.println("Data type change for \"" + key + "\": " + aVal.getClass().toString() + " => " + bVal.getClass().toString());
				return true;
			}
			if (! aVal.equals(bVal)) {
				// System.out.println("Value change for \"" + key + "\": " + aVal.toString() + " => " + bVal.toString());
				return true;
			}
		}
		return false;
	} // docsDiffer

}
