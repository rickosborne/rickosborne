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
import org.rickosborne.java.itunes.ItunesExporter;
import org.rickosborne.java.itunes.LibraryXmlParser;

public class Itunes2DB {
	
	final private static int MAX_LOOKAHEAD = 100;

	/**
	 * @param args
	 * @throws MalformedURLException 
	 */
	public static void main(String[] args) throws MalformedURLException {
		if (args.length < 3) {
			printUsage("");
		}
		ItunesExporter exporter = null;
		String libraryFile = null;
		if ("couchdb".equals(args[0])) {
			exporter = new CouchDBExporter(new URL(args[1]));
			libraryFile = args[2];
		} else if ("csv".equals(args[0])) {
			if (args.length < 4)
				printUsage("Too few arguments for CSV");
			exporter = new CommaDelimitedExporter(new File(args[1]), new File(args[2]));
			libraryFile = args[3];
		} else {
			printUsage("Unknown argument: " + args[0]);
		}
		LibraryXmlParser parser = new LibraryXmlParser(new File(libraryFile));
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
		if (! err.isEmpty()) {
			System.err.println(err);
		}
		System.err.println("Usage:\n\titunes2db couchdb http://couchhost:5984/dbName path/to/library.xml\n\titunes2db csv path/to/tracks.csv path/to/library.csv path/to/library.xml");
		System.exit(-1);
	} // printUsage

}
