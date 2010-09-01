package org.rickosborne.java.itunes;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.math.BigInteger;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.HashMap;

import javax.xml.stream.XMLStreamException;
import javax.xml.stream.XMLStreamReader;
import javax.xml.stream.XMLInputFactory;

public class LibraryXmlParser {
	
	private XMLInputFactory xmlinf;
	private XMLStreamReader reader;
	private HashMap<String,Integer> typeMap;
	private static SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'");
	final private static Integer TYPE_NUMERIC = 1;
	final private static Integer TYPE_STRING  = 2;
	final private static Integer TYPE_DATE    = 3;
	final private static Integer TYPE_BOOLEAN = 4;
	
	private class LibraryStreamFilter implements javax.xml.stream.StreamFilter {

		@Override
		public boolean accept(XMLStreamReader reader) {
			if (reader.isStartElement() || reader.isEndElement()) return true;
			return false;
		}
		
	}
	
	public LibraryXmlParser(File xmlFile) {
		xmlinf = XMLInputFactory.newInstance();
		xmlinf.setProperty(XMLInputFactory.IS_REPLACING_ENTITY_REFERENCES,Boolean.TRUE);
		xmlinf.setProperty(XMLInputFactory.IS_SUPPORTING_EXTERNAL_ENTITIES,Boolean.FALSE);
		xmlinf.setProperty(XMLInputFactory.IS_NAMESPACE_AWARE,Boolean.FALSE);
		xmlinf.setProperty(XMLInputFactory.IS_VALIDATING,Boolean.FALSE);
		xmlinf.setProperty(XMLInputFactory.IS_COALESCING , Boolean.TRUE);
		try {
			reader = xmlinf.createFilteredReader(
					xmlinf.createXMLStreamReader(xmlFile.getName(), new FileInputStream(xmlFile)),
					new LibraryStreamFilter()
				);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (XMLStreamException e) {
			e.printStackTrace();
		}
		typeMap = new HashMap<String,Integer>();
		typeMap.put("integer", TYPE_NUMERIC);
		typeMap.put("string", TYPE_STRING);
		typeMap.put("date", TYPE_DATE);
		typeMap.put("true", TYPE_BOOLEAN);
		typeMap.put("false", TYPE_BOOLEAN);
	}
	
	private ArrayList<Object> getSimpleKeyValue() {
		boolean notDone = true;
		String lastKey = "";
		String tagName = "";
		Object value;
		Integer type;
		ArrayList<Object> result = new ArrayList<Object>();
		try {
			while (reader.hasNext() && notDone) {
				if (reader.isStartElement()) {
					tagName = reader.getLocalName();
					if ("key".equals(tagName)) {
						lastKey = reader.getElementText().replaceAll("[^a-zA-Z0-9]+", "");
					} else if (!lastKey.isEmpty() && typeMap.containsKey(tagName)) {
						value = (String) reader.getElementText();
						type = typeMap.get(tagName);
						if (TYPE_DATE.equals(type)) {
							try {
								value = dateFormat.parse((String) value);
							} catch (ParseException e) {
								e.printStackTrace();
							}
						} else if (TYPE_NUMERIC.equals(type)) {
							try {
								value = Integer.parseInt((String) value);
							} catch (NumberFormatException ei) {
								try {
									value = Long.parseLong((String) value);
								} catch (NumberFormatException el) {
									value = new BigInteger((String) value);
								}
							}
						} else if (TYPE_BOOLEAN.equals(type)) {
							value = (Boolean) "true".equals((String) value);
						}
						result.add(lastKey);
						result.add(tagName);
						result.add(value);
						return result;
					} else if (!lastKey.isEmpty()) {
						result.add(lastKey);
						result.add(tagName);
						return result;
					}
				} else if (reader.isEndElement()) {
					if ("dict".equals(reader.getLocalName())) {
						notDone = false;
					}
				}
				reader.next();
			} // while
			return result;
		} catch (XMLStreamException e) {
			e.printStackTrace();
		}
		return null;
	}
	
	public HashMap<String, Object> getLibraryInfo() {
		HashMap<String, Object> info = new HashMap<String, Object>();
		boolean notDone = true;
		ArrayList<Object> obj;
		try {
			while (reader.hasNext() && notDone) {
				obj = getSimpleKeyValue();
				if (3 == obj.size()) {
					info.put((String) obj.get(0), obj.get(2)); 
				} else {
					notDone = false;
				}
			} // while
		} catch (XMLStreamException e) {
			e.printStackTrace();
		}
		return info;
	}
	
	public HashMap<String, Object> getNextTrack() {
		ArrayList<Object> trackKey = getSimpleKeyValue();
		ArrayList<Object> keyValue;
		HashMap<String, Object> track = new HashMap<String,Object>();
		try {
			if (reader.hasNext() && (2 == trackKey.size()) && ("dict".equals(trackKey.get(1)))) {
				keyValue = getSimpleKeyValue();
				while (reader.hasNext() && (3 == keyValue.size())) {
					track.put((String) keyValue.get(0), keyValue.get(2));
					keyValue = getSimpleKeyValue();
				}
			}
		} catch (XMLStreamException e) {
			e.printStackTrace();
		}
		return track;
	}
	
}
