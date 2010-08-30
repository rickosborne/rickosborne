package org.rickosborne.java.itunes;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.TreeSet;
import java.util.Map;
import java.util.Set;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.io.PrintWriter;
import java.io.Writer;
import java.math.BigInteger;

public class CommaDelimitedExporter implements ItunesExporter {
	
	private Writer outTracks;
	private Writer outLibrary;
	private TreeSet<String> columns;
	// private HashMap<String, Integer> missingColumns;
	final private static String columnDelimiter = ",";
	final private static String lineDelimiter = "\r\n";
	final private static Class<?> bigintClass  = BigInteger.class;
	final private static Class<?> booleanClass = Boolean.class;
	final private static Class<?> dateClass    = Date.class;
	final private static SimpleDateFormat dateFormat = new SimpleDateFormat("'{ts '''yyyy-MM-dd HH:mm:ss'''}'");
	
	public CommaDelimitedExporter(File tracksFile, File libraryFile) {
		super();
		try {
			outTracks = new PrintWriter(new BufferedWriter(new FileWriter(tracksFile)));
			outLibrary = new PrintWriter(new BufferedWriter(new FileWriter(libraryFile)));
		}
		catch(IOException ex) {
			System.err.print(ex);
		}
		columns = new TreeSet<String>();
		// missingColumns = new HashMap<String,Integer>();
	}
	
	@Override
	public boolean addTrack(Map<String, Object> trackInfo) {
		try {
			int columnCount = columns.size();
			int columnsDone = 0;
			for (String colName: columns) {
				if (trackInfo.containsKey(colName)) {
					writeObject(outTracks, trackInfo.get(colName));
				}
				++columnsDone;
				if (columnsDone < columnCount) {
					outTracks.write(columnDelimiter);
				}
			}
			outTracks.write(lineDelimiter);
		}
		catch(IOException ex) {
			ex.printStackTrace();
			return false;
		}
		return true;
	}
	
	/*
	private void onMissingColumn (String columnName) {
		if (missingColumns.containsKey(columnName)) {
			missingColumns.put(columnName, 1 + ((Integer) missingColumns.get(columnName)));
		} else {
			missingColumns.put(columnName, 1);
			System.err.println("Missing output column: " + columnName);
		}
	} // onMissingColumn
	*/
	
	private static String escapeString(String s) {
		return "\"" + s.replace("\\","\\\\").replace("\"", "\\\"") + "\"";
	} // escapeString
	
	private static void writeObject(Writer writer, Object colValue) {
		Class<?> colClass = colValue.getClass();
		try {
			if (colClass.equals(bigintClass))
				writer.write(((BigInteger) colValue).toString());
			else if (colClass.equals(booleanClass))
				writer.write(colValue.equals(Boolean.TRUE) ? "Y" : "N");
			else if (colClass.equals(dateClass))
				writer.write(dateFormat.format((Date) colValue));
			else
				writer.write(escapeString((String) colValue));		
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

	@Override
	public boolean close() {
		try {
			outTracks.close();
			outLibrary.close();
		} catch (IOException ex) {
			ex.printStackTrace();
			return false;
		}
		return true;
	}

	@Override
	public boolean addLibraryInfo(Map<String, Object> libraryInfo) {
		int columnCount = libraryInfo.size();
		int columnsDone = 0;
		TreeSet<String> colNames = new TreeSet<String>(libraryInfo.keySet());
		try {
			for(String columnName: colNames) {
				outLibrary.write(escapeString(columnName));
				++columnsDone;
				if (columnsDone < columnCount)
					outLibrary.write(columnDelimiter);
			}
			outLibrary.write(lineDelimiter);
			columnsDone = 0;
			for(String columnName: colNames) {
				writeObject(outLibrary, libraryInfo.get(columnName));
				++columnsDone;
				if (columnsDone < columnCount)
					outLibrary.write(columnDelimiter);
			}
			outLibrary.write(lineDelimiter);
		} catch (IOException e) {
			e.printStackTrace();
		}
		return true;
	}

	@Override
	public void addColumns(Set<String> columnNames) {
		columns.addAll(columnNames);
		int columnCount = columns.size();
		int columnsDone = 0;
		try {
			for(String columnName: columns) {
				outTracks.write(escapeString(columnName));
				++columnsDone;
				if (columnsDone < columnCount)
					outTracks.write(columnDelimiter);
			}
			outTracks.write(lineDelimiter);
		} catch (IOException e) {
			e.printStackTrace();
		}
	}

}
