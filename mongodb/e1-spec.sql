SELECT TRIM(c.column_name) AS ColName,
  CASE INT(frowtp) WHEN 1 THEN 'CHAR' WHEN 2 THEN 'VARCHAR' WHEN 9 THEN 'NUMERIC' WHEN 11 THEN 'DATE' END AS ColType,
  CASE WHEN INT(frowtp) = 9 THEN frdtas END AS DecLen,
  CASE WHEN INT(frowtp) = 9 THEN frcdec END AS DecPrec,
  c.is_nullable,
  TRIM(frowdi) AS HumanName,
  CASE INT(frowtp)
    WHEN 1 THEN '  CASE WHEN TRIM(' CONCAT TRIM(c.column_name) CONCAT ') <> '''' THEN TRIM(' CONCAT TRIM(c.column_name) CONCAT ') END'
    WHEN 2 THEN '  CASE WHEN TRIM(' CONCAT TRIM(c.column_name) CONCAT ') <> '''' THEN TRIM(' CONCAT TRIM(c.column_name) CONCAT ') END'
    WHEN 9 THEN
      CASE frcdec
        WHEN '' THEN '  CASE WHEN ' CONCAT TRIM(c.column_name) CONCAT ' <> 0 THEN ' CONCAT TRIM(c.column_name) CONCAT ' END'
        WHEN '0' THEN '  ' CONCAT TRIM(c.column_name)
        ELSE '  ' CONCAT TRIM(c.column_name) CONCAT ' * 0.' CONCAT REPEAT('0',INT(frcdec)-1) CONCAT '1'
      END
    WHEN 11 THEN
      CASE
        WHEN (frdtai = 'UPMJ') AND (COALESCE(tday.column_name,upmt.column_name) IS NOT NULL) THEN '  CASE WHEN ' CONCAT TRIM(c.column_name) CONCAT ' <> 0 THEN TIMESTAMP(REPLACE(CHAR(DATE(CHAR(1900000+' CONCAT TRIM(c.column_name) CONCAT '))),''-'','''') CONCAT (RIGHT(''000000'' CONCAT VARCHAR(' CONCAT COALESCE(tday.column_name,upmt.column_name) CONCAT '),6))) END'
        ELSE '  CASE WHEN ' CONCAT TRIM(c.column_name) CONCAT ' <> 0 THEN DATE(CHAR(1900000+' CONCAT TRIM(c.column_name) CONCAT ')) END'
      END
    ELSE ' ------ ' CONCAT VARCHAR(frowtp) CONCAT ' ------'
  END
  CONCAT ' AS ' CONCAT TRIM(c.column_name) CONCAT CASE WHEN c.ordinal_position = l.LastColNum THEN '' ELSE ', ' END AS Sql2
FROM qsys2.tables AS t
  INNER JOIN qsys2.columns AS c ON (t.table_schema = UPPER(::SchemaName)) AND (t.table_name = UPPER(::TableName)) AND (t.table_name = c.table_name) AND (c.table_schema = t.table_schema)
  LEFT OUTER JOIN dd810.f9210 AS d ON (SUBSTRING(c.column_name,3,12) = frdtai)
  INNER JOIN ( SELECT table_schema, table_name, MAX(ordinal_position) AS LastColNum FROM qsys2.columns WHERE table_schema = UPPER(::SchemaName) AND table_name = UPPER(::TableName) GROUP BY table_schema, table_name ) AS l ON (t.table_name = l.table_name) AND (l.table_schema = t.table_schema)
  LEFT OUTER JOIN qsys2.columns AS tday ON (tday.table_schema = t.table_schema) AND (tday.table_name = t.table_name) AND (SUBSTRING(tday.column_name,3,5) = 'TDAY')
  LEFT OUTER JOIN qsys2.columns AS upmt ON (upmt.table_schema = t.table_schema) AND (upmt.table_name = t.table_name) AND (SUBSTRING(upmt.column_name,3,5) = 'UPMT')



