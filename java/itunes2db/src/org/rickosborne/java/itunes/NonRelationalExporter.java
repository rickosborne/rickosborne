package org.rickosborne.java.itunes;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;

public abstract class NonRelationalExporter {
	
	protected static Map<String,String> typeMap = new HashMap<String,String>();

	public NonRelationalExporter() {
		super();
	}
	
	abstract protected String buildId(String type, String readable);
	abstract protected Map<String,Object> fetchOrCreateDoc(String docId);	
	abstract protected Map<String,Object> fetchDoc(String docId);
	abstract protected void updateIfChanged(Map<String, Object> doc);
	
	@SuppressWarnings("unchecked")
	protected void addItemToSet(String docType, String title, String titleKey, String setKey, String item) {
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
	
	protected static boolean docsDiffer(Map<String, Object> a, Map<String, Object> b) {
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
			String aClass = aVal.getClass().toString();
			String bClass = bVal.getClass().toString();
			if (! aClass.equals(bClass)) {
				if (typeMap.containsKey(bClass) && typeMap.get(bClass).equals(aClass)) {
					// we're cool
				} else {
					System.out.println("Data type change for \"" + key + "\": " + aVal.getClass().toString() + " => " + bVal.getClass().toString());
					return true;
				}
			} else if (! aVal.equals(bVal)) {
				System.out.println("Value change for \"" + key + "\": " + aVal.toString() + " => " + bVal.toString());
				return true;
			}
		}
		return false;
	} // docsDiffer

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

	public boolean addLibraryInfo(Map<String, Object> libraryInfo) {
		if (! libraryInfo.containsKey("LibraryPersistentID")) return false;
		String docId = this.buildId("library",(String) libraryInfo.get("LibraryPersistentID"));
		libraryInfo.put("_id", docId);
		libraryInfo.put("type", "library");
		updateIfChanged(libraryInfo);
		return false;
	}

	public void addColumns(Set<String> columnNames) {}
	public boolean close() { return true; }

}