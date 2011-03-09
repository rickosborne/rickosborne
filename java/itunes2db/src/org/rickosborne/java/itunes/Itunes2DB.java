package org.rickosborne.java.itunes;

import java.io.File;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Arrays;

import org.rickosborne.java.itunes.CommaDelimitedExporter;
import org.rickosborne.java.itunes.CouchDBExporter;
import org.rickosborne.java.itunes.MongoDBExporter;
import org.rickosborne.java.itunes.ItunesExporter;
import org.rickosborne.java.itunes.LibraryXmlParser;

public class Itunes2DB {
	
	final private static int MAX_LOOKAHEAD = 100;
	private static String userHome = "";
	private static String libPath  = "";

	/**
	 * @param args
	 * @throws MalformedURLException 
	 */
	public static void main(String[] args) throws MalformedURLException {
		userHome = System.getProperty("user.home");
		libPath  = userHome + File.separator + "Music" + File.separator + "iTunes" + File.separator + "iTunes Music Library.xml";
		if (args.length < 1) {
			printUsage("");
		}
		ItunesExporter exporter = null;
		String libraryFile = null;
		Integer libraryArg = 2;
		if ("couchdb".equals(args[0])) {
			String couchUrl = (args.length > 1) ? args[1] : "http://localhost:5984/itunes";
			exporter = new CouchDBExporter(new URL(couchUrl));
		} else if ("csv".equals(args[0])) {
			String tracksCSV = (args.length > 1) ? args[1] : "tracks.csv";
			String libCSV    = (args.length > 2) ? args[2] : "library.csv";
			exporter = new CommaDelimitedExporter(new File(tracksCSV), new File(libCSV));
			libraryArg = 3;
		} else if ("mongodb".equals(args[0])) {
			String dbname = (args.length > 1) ? args[1] : "";
			String host   = (args.length > 2) ? args[2] : "localhost";
			Integer port  = (args.length > 3) ? Integer.valueOf(args[3]) : 27017;
			exporter = new MongoDBExporter(dbname, host, port);
			libraryArg = 4;
		} else {
			printUsage("Unknown argument: " + args[0]);
		}
		libraryFile = (args.length > libraryArg) ? args[libraryArg] : libPath;
		File libFile = new File(libraryFile);
		if (! libFile.canRead())
			printUsage("Can't read library XML file: " + libraryFile);
		LibraryXmlParser parser = new LibraryXmlParser(libFile);
		exporter.addLibraryInfo(parser.getLibraryInfo());
		HashSet<String> columnNames = new HashSet<String>(
			Arrays.asList("TrackID,Name,Artist,Album,Genre,Kind,Size,TotalTime,Year,DateModified,DateAdded,BitRate,SampleRate,PlayCount,PlayDate,PlayDateUTC,Rating,AlbumRating,AlbumRatingComputed,ArtworkCount,PersistentID,TrackType,Location,FileFolderCount,LibraryFolderCount".split(","))
		);
		HashMap<String,Object> track;
		boolean notDone = true;
		ArrayList<HashMap<String,Object>> buffer = new ArrayList<HashMap<String,Object>>();
		while ((buffer.size() < MAX_LOOKAHEAD) && notDone) {
			track = parser.getNextTrack();
			if (track.size() > 0) {
				buffer.add(track);
				columnNames.addAll(track.keySet());
			} else {
				notDone = false;
			}
		} // while
		exporter.addColumns(columnNames);
		columnNames = null;
		for (int i = 0; i < buffer.size(); i++) {
			exporter.addTrack(buffer.get(i));
		}
		buffer = null;
		while (notDone) {
			track = parser.getNextTrack();
			if (track.size() > 0) {
				exporter.addTrack(track);
			} else { 
				notDone = false;
			}
		} // while
		track = null;
		parser = null;
		exporter.close();
	} // main
	
	private static void printUsage(String err) {
		System.err.println("Usage:\n\titunes2db (dbtype) [options] [path/to/itunes/library.xml]\n\nDatabase types and options:\n\tcsv     [path/to/tracks.csv] [path/to/library.csv]\n\tcouchdb [dbName = itunes] [host = localhost] [port =  5984]\n\tmongodb [dbName = itunes] [host = localhost] [port = 27017]\n\nDefaults:\n\tlibrary.xml = " + libPath + "\n");
		if (! err.isEmpty()) {
			System.err.println("!!!\n" + err + "\n!!!\n");
		}
		System.exit(-1);
	} // printUsage

}
