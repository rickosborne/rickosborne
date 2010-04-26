/**
 * I am the model for a Sudoku game (state and rules).
 * I use the HTML5 Web SQL Database Storage API. I do *not*
 * know anything about interacting with the game board.
 * 
 * @author	Rick Osborne
 */

// Create/use the RICKO namespace, to avoid collisions with any other libraries
if(typeof RICKO == "undefined" || !RICKO) { var RICKO = {}; }

/**
 * I am the primary object definition for the model.  With the exception of my
 * constructor, all of my public methods are entirely asynchronous, requiring
 * callback functions.
 * 
 * @param	{String} dbName	The name of the database to use.
 * @return	            	The model object.
 * 
 * @constructor
 */
RICKO.SudokuModelDBStore = function(dbName) {
	var that       = this;
	var db         = null;	
	var DB_VERSION = "1.0";
	var DB_TITLE   = "Sudoku Game by Rick Osborne";
	var DB_BYTES   = 100000;

	/**
	 * @todo	We should add more public domain boards here.
	 * @todo	Do we want to store these in a table instead of as literals?
	 */
	var boards     = {
		"Wikipedia": "53  7    6  195    98    6 8   6   34  8 3  17   2   6 6    28    419  5    8  79"
	};
	
	/**
	 * Private generic error handling function.  No smarts, just logging.
	 * 
	 * @param {Object} tx	The handle to the current transaction.
	 * @param {Object} err	The error thrown by the database.
	 */
	function sqlFailed (tx, err) {
		console.log("Transaction Failed:\n" + err.message);
		alert("Transaction Failed:\n" + err.message);
	} // sqlFailed
	
	/**
	 * Private debugging function to dump out the records in a table to the console.
	 * This is really only useful in browsers that don't have a database UI.
	 * 
	 * @param {Object} n	The name of the table to dump.	
	 */
	function logTable (tableName) {
		db.transaction(function(tx) {
			tx.executeSql("SELECT * FROM " + tableName + ";", [], function(tx, r) {
				console.log("Table " + tableName + " (" + r.rows.length + "):");
				var rows = [];
				for(var i = 0; i < r.rows.length; i++)
					rows.push(r.rows.item(i));
				console.log(rows);
			}, sqlFailed);
		});
	} // logTable
	
	/**
	 * Clear the game board state, loading a new board in its place.
	 * Boards can be loaded by name (such as 'Wikipedia') or by literal.
	 * Board literals are 81-character strings, with 1 character per cell.
	 * Cells are scanned horizontally, from top left to bottom right.
	 * Cell values can be digits (1-9) or spaces for an empty cell.
	 * 
	 * @param {String}  	boardName   	The name of the built-in board (such as 'Wikipedia') or the string literal holding the cell data.
	 * @param {Boolean} 	overwrite   	Overwrite the current board if it's not empty?
	 * @param {Function}	doneCallback	Next step once the board has been loaded
	 */
	function loadBoard (boardName, overwrite, doneCallback) {
		var cells = boards[boardName] || boardName || "";
		if(cells.length != 81) {
			console.log("Board '" + boardName + "' seems to be malformed.");
			return false;
		} // if wrong length
		db.transaction(function(tx) {
			tx.executeSql("SELECT COUNT(*) AS cellCount FROM rs_cells;", [], function(tx, r) {
				if(overwrite || (r.rows.length != 1) || (r.rows.item(0).cellCount == 0)) {
					tx.executeSql("DELETE FROM rs_cells;", [], null, sqlFailed);
					var row = 1;
					var col = 0;
					for (var i = 0; i < 81; i++) {
						var term = cells.charAt(i);
						col++;
						if(col > 9) { col = 1; row++; }
						if(term === " ") continue;
						var box = (Math.floor((row - 1) / 3) * 3) + Math.floor((col - 1) / 3);
						tx.executeSql("INSERT INTO rs_cells (row, col, box, term) VALUES (?, ?, ?, ?);", [ row, col, box, term ], null, sqlFailed);
					} // for i
				} // if overwriting
			}, sqlFailed);
		}, sqlFailed, doneCallback);
	} // loadBoard
	
	/**
	 * Clear (erase) the value in given cell.
	 * 
	 * @param {Integer} 	row         	The 0-based number of the row of the cell.  Zero is the topmost first row.
	 * @param {Integer} 	col         	The 0-based number of the column of the cell.  Zero is the leftmost first column.
	 * @param {Function}	doneCallback	Next step once the cell has been cleared.
	 */
	function deleteCell (row, col, doneCallback) {
		db.transaction(function(tx) {
			tx.executeSql("DELETE FROM rs_cells WHERE (row = ?) AND (col = ?);", [ row, col ], null, sqlFailed);
		}, null, doneCallback);
	} // deleteCell
	
	/**
	 * Change the value in the given cell to a given new value.
	 * If the value cannot be used in the cell, call the given callback for invalid values.
	 * Any cells that are blocking the given value from being used are passed into the
	 * invalidCallback function.  Row and column numbers are converted to 0-base (0-8) from
	 * the 1-base (1-9) used in the database.
	 * 
	 * @param {Integer} 	row         	The 0-based number of the row of the cell.  Zero is the topmost first row. 
	 * @param {Integer} 	col         	The 0-based number of the column of the cell.  Zero is the leftmost first column.
	 * @param {Integer} 	box         	The 0-based number of the box of the cell.  Zero is the leftmost and topmost first box.
	 * @param {Integer} 	term           	The 1-based digit to put in the cell.  Valid digits are (1-9).
	 * @param {Function}	doneCallback   	Next step once the cell has been successfully updated.
	 * @param {Function}	invalidCallback	Next step if the cell cannot be updated with the given digit.
	 */
	function updateCell (row, col, box, term, doneCallback, invalidCallback) {
		db.transaction(function(tx) {
			tx.executeSql("SELECT row, col, box, term AS blocks FROM rs_cells WHERE ((row = ?) OR (col = ?) OR (box = ?)) AND (term = ?);", [ row, col, box, term ], function(tx, res) {
				if(res.rows.length == 0) {
					tx.executeSql("DELETE FROM rs_cells WHERE (row = ?) AND (col = ?);", [ row, col ], function(tx) {
						tx.executeSql("INSERT INTO rs_cells (row, col, box, term) VALUES (?, ?, ?, ?);", [ row, col, box, term ], doneCallback, sqlFailed);
					}, sqlFailed);
				} // if one row back
				else if((res.rows.length == 1) && (res.rows.item(0).row == row) && (res.rows.item(0).col == col)) {
					// it's the same cell ... don't do anything
				}
				else if(invalidCallback) {
					var blocks = [];
					for(var i = 0; i < res.rows.length; i++) {
						var rec = res.rows.item(i);
						blocks.push({ row: rec.row - 1, col: rec.col - 1 });
					}
					invalidCallback(blocks);
				}
			}, sqlFailed);
		});
	} // updateCell
	
	/**
	 * Find any cells that can be immediately deduced and fill them.
	 * 
	 * @param {Function} doneCallback	Next step once the hints have been added.
	 */
	function cheatAddHints (doneCallback) {
		db.transaction(function(tx) {
			tx.executeSql("INSERT INTO rs_cells (row, col, box, term) SELECT row, col, box, term FROM rs_hints;", [], null, sqlFailed);
		}, null, doneCallback);
	} // cheatAddHints
	
	/**
	 * Save the state of the board to a database table, allowing it to be loaded if the browser closes.
	 * 
	 * @param {Function} doneCallback	Next step once the board has been saved.
	 */
	function saveBoard (doneCallback) {
		db.transaction(function(tx) {
			tx.executeSql("DELETE FROM rs_saved;", [], function(tx) {
				tx.executeSql("INSERT INTO rs_saved (row, col, box, term) SELECT row, col, box, term FROM rs_cells;", [], null, sqlFailed);
			}, sqlFailed);
		}, null, doneCallback);
	} // saveBoard
	
	/**
	 * Fetch the cells that can be immediately deduced from the current board state.
	 * Rows and columns are converted into 0-based values (0-8) from the 1-based values (1-9)
	 * stored in the database.
	 * 
	 * @param {Function} doneCallback	Next step once the cells have been fetched.
	 */
	function getHints (doneCallback) {
		db.transaction(function(tx) {
			tx.executeSql("SELECT row, col, box, term FROM rs_hints;", [], function(tx, r) {
				var hints = [];
				for(var i = 0; i < r.rows.length; i++) {
					var rec = r.rows.item(i);
					hints.push({ row: rec.row - 1, col: rec.col - 1, box: rec.box, term: rec.term });
				} // for i
				doneCallback(hints);
			}, sqlFailed);
		});
	} // getHints
	
	/**
	 * Return the values that are written (known) on the game board.
	 * Rows and columns are converted to 0-base (0-8) from the 1-base (1-9) stored in the database.
	 * 
	 * @param {Object} doneCallback	Next step once the values have been fetched.
	 */
	function getKnowns (doneCallback) {
		db.transaction(function(tx) {
			tx.executeSql("SELECT row, col, box, term FROM rs_cells;", [], function(tx, r) {
				var knowns = [];
				for(var i = 0; i < r.rows.length; i++) {
					var rec = r.rows.item(i);
					knowns.push({ row: rec.row - 1, col: rec.col - 1, box: rec.box, term: rec.term });
				} // for i
				doneCallback(knowns);
			}, sqlFailed);
		}); // transaction
	} // getKnowns
	
	/*
	 * Constructor code begins here.
	 */
	if(!window.openDatabase) {
		alert("Your browser does not appear to support the openDatabase call from the HTML5 Database Storage API.");
		return null;
	} // if not openDatabase
	db = openDatabase(dbName, DB_VERSION, DB_TITLE, DB_BYTES);
	if(!db) {
		alert("The browser rejected the request to open the database.");
		return null;
	} // if not opened
	/*
	 * Set up the database.  This can also be done using the "first time" database callback, but
	 * due to the nature of the game, it's just as easy to drop and recreate everything each time.
	 */
	db.transaction(function(tx) {
		tx.executeSql("DROP VIEW IF EXISTS rs_hints;", [], null, sqlFailed);
		var tables = [ "rs_cells", "rs_possible", "rs_board", "rs_boxes", "rs_rows", "rs_cols", "rs_terms" ];
		for(var i = 0; i < tables.length; i++)
			tx.executeSql("DROP TABLE IF EXISTS " + tables[i] + ";", [], null, sqlFailed);
		tx.executeSql("CREATE TABLE rs_terms (term CHAR(1) NOT NULL PRIMARY KEY);", [], null, sqlFailed);
		tx.executeSql("CREATE TABLE rs_rows  (row  INTEGER NOT NULL PRIMARY KEY);", [], null, sqlFailed);
		tx.executeSql("CREATE TABLE rs_cols  (col  INTEGER NOT NULL PRIMARY KEY);", [], null, sqlFailed);
		tx.executeSql("CREATE TABLE rs_boxes (box  INTEGER NOT NULL PRIMARY KEY);", [], null, sqlFailed);
		for(var i = 1; i <= 9; i++) {
			tx.executeSql("INSERT INTO rs_terms (term) VALUES (?);", [ "" + i ], null, sqlFailed);
			tx.executeSql("INSERT INTO rs_rows  (row)  VALUES (?);", [ i ], null, sqlFailed);
			tx.executeSql("INSERT INTO rs_cols  (col)  VALUES (?);", [ i ], null, sqlFailed);
			tx.executeSql("INSERT INTO rs_boxes (box)  VALUES (?);", [ i - 1 ], null, sqlFailed);
		} // for i
		tx.executeSql("CREATE TABLE rs_board (row INTEGER NOT NULL, col INTEGER NOT NULL, box INTEGER NOT NULL, PRIMARY KEY (row, col), FOREIGN KEY (row) REFERENCES rs_rows (row), FOREIGN KEY (col) REFERENCES rs_cols (col), FOREIGN KEY (box) REFERENCES rs_boxes (box));", [], null, sqlFailed);
		tx.executeSql("INSERT INTO rs_board (row, col, box) SELECT row, col, (((row - 1) / 3) * 3) + ((col - 1) / 3) FROM rs_rows, rs_cols", [], null, sqlFailed);
		tx.executeSql("CREATE TABLE rs_possible (row INTEGER NOT NULL, col INTEGER NOT NULL, box INTEGER NOT NULL, term INTEGER NOT NULL, PRIMARY KEY (row, col, term), FOREIGN KEY (row) REFERENCES rs_rows (row), FOREIGN KEY (col) REFERENCES rs_cols (col), FOREIGN KEY (box) REFERENCES rs_boxes (box), FOREIGN KEY (term) REFERENCES rs_terms (term));", [], null, sqlFailed);
		tx.executeSql("INSERT INTO rs_possible (row, col, box, term) SELECT row, col, box, term FROM rs_board, rs_terms;");
		tx.executeSql("CREATE TABLE rs_cells (row INTEGER NOT NULL, col INTEGER NOT NULL, box INTEGER NOT NULL, term INTEGER NOT NULL, PRIMARY KEY (row, col), FOREIGN KEY (row) REFERENCES rs_rows (row), FOREIGN KEY (col) REFERENCES rs_cols (col), FOREIGN KEY (box) REFERENCES rs_boxes (box), FOREIGN KEY (term) REFERENCES rs_terms (term));", [], null, sqlFailed);
		tx.executeSql("CREATE TABLE IF NOT EXISTS rs_saved (row INTEGER NOT NULL, col INTEGER NOT NULL, box INTEGER NOT NULL, term INTEGER NOT NULL, PRIMARY KEY (row, col), FOREIGN KEY (row) REFERENCES rs_rows (row), FOREIGN KEY (col) REFERENCES rs_cols (col), FOREIGN KEY (box) REFERENCES rs_boxes (box), FOREIGN KEY (term) REFERENCES rs_terms (term));", [], null, sqlFailed);
		tx.executeSql("INSERT INTO rs_cells (row, col, box, term) SELECT row, col, box, term FROM rs_saved;", [], null, sqlFailed);
		tx.executeSql("CREATE VIEW rs_hints AS SELECT p.row, p.col, MIN(p.box) AS box, MIN(p.term) AS term FROM rs_possible AS p LEFT JOIN rs_cells AS c ON ((p.row = c.row) AND (p.term = c.term)) OR ((p.col = c.col) AND (p.term = c.term)) OR ((p.box = c.box) AND (p.term = c.term)) OR ((p.row = c.row) AND (p.col = c.col)) WHERE (c.term IS NULL) GROUP BY p.row, p.col HAVING COUNT(*) = 1;", [], null, sqlFailed);
	});
	
	/*
	 * Return only references to public methods.
	 */
	return {
		loadBoard:     loadBoard,
		deleteCell:    deleteCell,
		updateCell:    updateCell,
		cheatAddHints: cheatAddHints,
		saveBoard:     saveBoard,
		getHints:      getHints,
		getKnowns:     getKnowns
	};
}; // SudokuModelDBStore
