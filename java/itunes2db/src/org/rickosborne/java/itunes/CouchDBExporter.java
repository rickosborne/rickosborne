package org.rickosborne.java.itunes;

import java.util.List;
import java.math.BigInteger;
import java.net.URL;
import java.util.ArrayList;
import java.util.Map;
import java.util.Set;

import org.codehaus.jackson.annotate.*;
import org.codehaus.jackson.map.ObjectMapper;
import org.ektorp.CouchDbConnector;
import org.ektorp.CouchDbInstance;
import org.ektorp.http.HttpClient;
import org.ektorp.Revision;
import org.ektorp.http.StdHttpClient;
import org.ektorp.impl.StdCouchDbConnector;
import org.ektorp.impl.StdCouchDbInstance;
import org.ektorp.impl.JsonSerializer;
import org.ektorp.support.CouchDbDocument;

public class CouchDBExporter implements ItunesExporter {
	
	private HttpClient httpclient;
	private CouchDbInstance dbInstance;
	private CouchDbConnector db;
	final private String colMap = "TrackID,Name,Artist,Album,Genre,Kind,Size,TotalTime,Year,DateModified,DateAdded,BitRate,SampleRate,PlayCount,PlayDate,PlayDateUTC,Rating,AlbumRating,AlbumRatingComputed,ArtworkCount,PersistentID,TrackType,Location,FileFolderCount,LibraryFolderCount"; 
	
	@SuppressWarnings("unused")
	@JsonWriteNullProperties(false)
	private class CouchLibrary extends CouchDbDocument {
		
		private static final long serialVersionUID = -5583820047934106165L;
		@JsonProperty("appver")
		public String applicationVersion;
		public int features;
		@JsonProperty("verminor")
		public int minorVersion;
		@JsonProperty("vermajor")
		public int majorVersion;
		@JsonProperty("musicfolder")
		public String musicFolder;
		@JsonProperty("showratings")
		public boolean showContentRatings;
		private String id;
		
		@JsonProperty("_id")
		@Override
		public String getId() { return "library:" + id; }
		
		@JsonProperty("_id")
		@Override
		public void setId(String id) { this.id = id; }
		
	}
	
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
		db = new StdCouchDbConnector(dbName, dbInstance);
		db.createDatabaseIfNotExists();
	}

	@Override
	public boolean addTrack(Map<String, Object> trackInfo) {
		String docId = "track:" + ((String) trackInfo.get("PersistentID"));
		if (db.contains(docId)) {
			System.out.println("Skipping " + docId);
			return false;
		}
		trackInfo.put("_id", docId);
		trackInfo.put("type", "track");
		db.update(trackInfo);
		return true;
	}

	@Override
	public void addColumns(Set<String> columnNames) {
		// TODO Auto-generated method stub
		
	}

	@Override
	public boolean close() {
		// TODO Auto-generated method stub
		return false;
	}

	@Override
	public boolean addLibraryInfo(Map<String, Object> libraryInfo) {
		String docId = "library:" + ((String) libraryInfo.get("LibraryPersistentID"));
		libraryInfo.put("_id", docId);
		List<Revision> revs = db.getRevisions(docId);
		libraryInfo.put("type", "library");
		if (revs.size() == 0)
			db.update(libraryInfo);
		// libraryInfo.put("_rev", revs.get(0).getRev());
		// System.out.println( new JsonSerializer(new ObjectMapper()).toJson(libraryInfo));
		return false;
	}

}
