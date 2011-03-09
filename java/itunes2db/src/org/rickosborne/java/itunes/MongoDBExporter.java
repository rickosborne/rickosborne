package org.rickosborne.java.itunes;

import java.net.UnknownHostException;
import java.util.Map;
import java.util.Set;

import com.mongodb.Mongo;
import com.mongodb.DB;
import com.mongodb.DBCollection;
import com.mongodb.BasicDBObject;
import com.mongodb.DBObject;
import com.mongodb.DBCursor;
import com.mongodb.MongoException;


public class MongoDBExporter implements ItunesExporter {
	
	private com.mongodb.DB db;
	
	public MongoDBExporter(String db, String host, Integer port) {
		Mongo m;
		try {
			m = new Mongo(host, port);
			this.db = m.getDB(db);
		} catch (UnknownHostException e) {
			// TODO Auto-generated catch block
			System.err.println(String.format("Unknown host or port: %s:%d", host, port));
		} catch (MongoException e) {
			System.err.println(e.getMessage());
		}
	}

	public boolean addTrack(Map<String, Object> trackInfo) {
		// TODO Auto-generated method stub
		return false;
	}

	public boolean addLibraryInfo(Map<String, Object> libraryInfo) {
		// TODO Auto-generated method stub
		return false;
	}

	public void addColumns(Set<String> columnNames) {
		// TODO Auto-generated method stub

	}

	public boolean close() {
		// TODO Auto-generated method stub
		return false;
	}

}
