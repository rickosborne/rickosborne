/**
 * @author    Rick Osborne
 * @license   Mozilla Public License 1.1: http://www.mozilla.org/MPL/MPL-1.1.html
 *
 * DO NOT USE THIS CODE IF YOU DO NOT UNDERSTAND THE LICENSE!
 */
component output="false" {

	variables.typeMap = {
		"integer" = "Integer",
		"string"  = "VarChar",
		"date"    = "timestamp",
		"true"    = "VarChar",
		"false"   = "VarChar"
	};

	public struct function queriesFromXmlFile (required string xmlFile) {
		var inputFactory=createObject("java","javax.xml.stream.XMLInputFactory").newInstance();
		var xmlReader = inputFactory.createXMLStreamReader(createObject("java","java.io.FileInputStream").init(javaCast("string",arguments.xmlFile)));
		var result = structNew();
		result.library = getLibraryQuery(xmlReader);
		result.tracks = getTracksQuery(xmlReader);
		xmlReader.close();
		return result;
	} // queriesFromXmlFile

	private query function getLibraryQuery (required any xmlReader) {
		var q = queryNew("MajorVersion,MinorVersion,ApplicationVersion,Features,ShowContentRatings,MusicFolder,LibraryPersistentID","Integer,Integer,VarChar,Integer,VarChar,VarChar,VarChar");
		var x = arguments.xmlReader;
		var notDone = true;
		var tagName = "";
		var value = "";
		var triple = "";
		queryAddRow(q);
		while (x.hasNext() and notDone) {
			triple = getSimpleKeyValue(x);
			if (arrayLen(triple) eq 3) {
				key     = triple[1];
				tagName = triple[2];
				value   = triple[3];
				if (listFindNoCase(q.columnList, key) gt 0) {
					querySetCell(q, key, value, q.recordCount);
				} else if (structKeyExists(variables.typeMap, tagName)) {
					queryAddColumn(q, key, variables.typeMap[tagName], []);
					querySetCell(q, key, value, q.recordCount);
				}
			} else {
				notDone = false;
			} // if triple
		} // while
		return q;
	} // getLibraryQuery

	private query function getTracksQuery (required any xmlReader) {
		var q = queryNew(
		  "TrackID,Name,   Artist, Album,  Genre,  Kind,   Size,   TotalTime,Year,   DateModified,DateAdded,BitRate,SampleRate,PlayCount,PlayDate,PlayDateUTC,Rating, AlbumRating,AlbumRatingComputed,ArtworkCount,PersistentID,TrackType,Location,FileFolderCount,LibraryFolderCount",
		  "Integer,VarChar,VarChar,VarChar,VarChar,VarChar,Integer,Integer,  Integer,Timestamp,   Timestamp,Integer,Integer,   Integer,  BigInt,  Timestamp,  Integer,Integer,    VarChar,            Integer,     VarChar,     VarChar,  VarChar, Integer,        Integer"
		);
		var x = arguments.xmlReader;
		var trackData = "";
		var notDone = true;
		var currentRow = 0;
		while (x.hasNext() and notDone) {
			trackData = getTrackData(x);
			// writeLog(serializeJSON(trackData), "information", false, "itunes");
			if (trackData.recordCount gt 0) {
				queryAddRow(q);
				currentRow = 1;
				while (currentRow lte trackData.recordCount) {
					if (listFindNoCase(q.columnList, trackData.key[currentRow]) gt 0) {
						querySetCell(q, trackData.key[currentRow], trackData.value[currentRow], q.recordCount);
					} else if (structKeyExists(variables.typeMap, trackData.valueType[currentRow])) {
						queryAddColumn(q, trackData.key[currentRow], variables.typeMap[trackData.valueType[currentRow]], []);
						querySetCell(q, trackData.key[currentRow], trackData.value[currentRow], q.recordCount);
					}
					currentRow++;
				} // while
			} else {
				notDone = false;
			}
			if (q.recordCount gte 25000) {
				notDone = false;
			}
		} // while
		return q;
	} // getTracksQuery

	private query function getTrackData (required any xmlReader) {
		var x = arguments.xmlReader;
		var q = queryNew("key,value,valueType","VarChar,VarChar,VarChar");
		var trackKey = getSimpleKeyValue(x);
		var triple = "";
		if (x.hasNext() and (arrayLen(trackKey) eq 2) and (trackKey[2] eq 'dict')) {
			triple = getSimpleKeyValue(x);
			while (x.hasNext() and (arrayLen(triple) eq 3)) {
				queryAddRow(q);
				querySetCell(q, "key", triple[1], q.recordCount);
				querySetCell(q, "value", triple[3], q.recordCount);
				querySetCell(q, "valueType", triple[2], q.recordCount);
				triple = getSimpleKeyValue(x);
			} // while
		} // if
		return q;
	} // getTrackData

	private function getSimpleKeyValue (required any xmlReader) {
		var x = arguments.xmlReader;
		var notDone = true;
		var key = "";
		var lastKey = "";
		var tagName = "";
		var value = "";
		var result = arrayNew(1);
		while (x.hasNext() and notDone) {
			if (x.isStartElement()) {
				tagName = x.getLocalName();
				if (tagName eq "key") {
					lastKey = reReplaceNoCase(x.getElementText(),"[^a-z0-9]","","ALL");
				} else if ((lastKey neq "") and structKeyExists(variables.typeMap,tagName)) {
					value = x.getElementText();
					switch (tagName) {
						case "date":
							value = createObject("java","java.text.SimpleDateFormat").init("yyyy-MM-dd'T'HH:mm:ss'Z'").parse(value);
							break;
						case "integer":
							value = val(value);
							break;
						case "true":
							value = "Y";
							break;
						case "false":
							value = "N";
							break;
					} // switch
					arrayAppend(result, lastKey);
					arrayAppend(result, tagName);
					arrayAppend(result, value);
					return result;
				} else if (lastKey neq "") {
					arrayAppend(result, lastKey);
					arrayAppend(result, tagName);
					return result;
				}
			} else if (x.isEndElement()) {
				if (x.getLocalName() eq "dict")  {
					notDone = false;
				}
			} // if start/end
			e = x.next();
		} // while
		return result;
	} // getSimpleKeyValue

}