/**
 * I am the controller for a Sudoku game.  I handle the user interface
 * interaction, including keypresses and event handling.  I know nothing
 * about drawing, storage, or game state.
 * 
 * @author Rick Osborne
 */

// Create/use the RICKO namespace, to avoid collisions with any other libraries
if(typeof RICKO == "undefined" || !RICKO) { var RICKO = {}; }

/**
 * I am the primary object definition for the controller.
 * 
 * @param {Object} modelObj
 * @param {Object} viewObj
 * @return The controller object
 * @constructor
 */
RICKO.SudokuBoard = function(modelObj, viewObj) {
	var that = this;
	var model = modelObj;
	var view  = viewObj;
	
	/**
	 * Pass the request to load a board on to the model.
	 * 
	 * @param {String}	boardName	The name of the board, or the literal for the cell data.  (See the model for details on the string format.)
	 * @param {Boolean}	overwrite	Overwrite the board if it has cell data?
	 */
	function loadBoard (boardName, overwrite) {
		model.loadBoard(boardName, overwrite, updateDigits);
	} // loadBoard
	
	/**
	 * Update all of the digits with their latest values from the model.
	 */
	function updateDigits() {
		model.getKnowns(view.setKnowns);
		model.getHints(view.setHints);
		model.getPossible(true, view.setPossible);
	} // updateDigits
	
	/**
	 * Handle keyboard events
	 * 
	 * @param {Object} event	The key press event.
	 */
	function keyBoard (event) {
		if(!event) event = window.event;
		var key = (event.keyCode || event.charCode);
		var cell = view.getSelectedCell();
		var done = false;
		if(key == 72) {
			view.toggleHints();
			done = true;
		} // hints
		else if(key == 67) {
			model.cheatAddHints(updateDigits);
			done = true;
		} // cheat
		else if(key == 82) {
			loadBoard('Wikipedia', true);
			done = true;
		} // reset
		else if(key == 83) {
			model.saveBoard();
			done = true;
		} // save
		else if((key >= 33) && (key <= 36)) {
			if(key == 33)      view.setSelectedCell(0,8);
			else if(key == 34) view.setSelectedCell(8,0);
			else if(key == 35) view.setSelectedCell(8,8);
			else if(key == 36) view.setSelectedCell(0,0);
			done = true;
		} // home, end, etc
		else if((cell.row == -1) || (cell.box == -1) || (cell.col == -1)) return;
		// console.log(key);
		else if((key == 8) || (key == 48) || (key == 96) || (key == 46)) {
			model.deleteCell(cell.row + 1, cell.col + 1, updateDigits);
			done = true;
		} // delete/clear/zero
		else if((key >= 37) && (key <= 40)) {
			var newCell = null;
			if((key == 37) && (cell.col > 0))      newCell = [ cell.row, cell.col - 1 ];
			else if((key == 38) && (cell.row > 0)) newCell = [ cell.row - 1, cell.col ];
			else if((key == 39) && (cell.col < 8)) newCell = [ cell.row, cell.col + 1 ];
			else if((key == 40) && (cell.row < 8)) newCell = [ cell.row + 1, cell.col ];
			if(newCell != null)
				view.setSelectedCell(newCell[0], newCell[1]);
			done = true;
		} // arrows
		else if(((key >= 49) && (key <= 57)) || ((key >= 97) && (key <= 105))) {
			model.updateCell(cell.row + 1, cell.col + 1, cell.box, key - (key > 95 ? 96 : 48), updateDigits, view.setBlocks);
			done = true;
		} // digit
		if (done) {
			event.cancelBubble = true;
			if (event.stopPropagation) 
				event.stopPropagation();
		}
	} // keyBoard
	
	/*
	 * Begin constructor code.
	 */
	window.addEventListener("keydown", keyBoard, true);
	model.getBoards(function(boardNames){
		view.setBoards(boardNames, function(boardName){
			loadBoard(boardName, true)
		});
	});
	
	/*
	 * Return only references to the public methods.
	 */
	return {
		loadBoard: loadBoard
	};
} // SudokuBoard
