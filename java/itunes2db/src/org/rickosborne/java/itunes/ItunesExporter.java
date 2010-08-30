package org.rickosborne.java.itunes;

import java.util.Map;
import java.util.Set;

public interface ItunesExporter {
	
	public boolean addTrack(Map<String,Object> trackInfo);
	public boolean addLibraryInfo(Map<String,Object> libraryInfo);
	public void    addColumns(Set<String> columnNames);
	public boolean close();

}
