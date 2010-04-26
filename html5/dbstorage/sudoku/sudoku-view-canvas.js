/**
 * I am the view for a Sudoku game, drawing the board with a Canvas element.
 * I don't know anything about the state of the game, nor about interacting
 * with the user.
 * 
 * @author Rick Osborne
 */

// Create/use the RICKO namespace, to avoid collisions with any other libraries
if(typeof RICKO == "undefined" || !RICKO) { var RICKO = {}; }

/**
 * I am the primary object definition for the view.  As the Canvas is
 * synchronous, as are my methods.
 * 
 * @param {String} containerId   	The HTML ID of the Canvas to use.
 * @param {String} parentId      	The HTML ID of the constraining element.  (Body?)
 * @param {String} instructionsId	The HTML ID of the accompanying instructions.
 * @return The view object.
 * @constructor
 * 
 * @todo	The instructions element management is a bit of a hack.
 */
RICKO.SudokuViewCanvas = function(containerId, parentId, instructionsId, boardsId) {
	var that = this;
	function getEl(n) { return window.document.getElementById(n); };
	var body       = getEl(parentId);
	var inst       = getEl(instructionsId);
	var container  = getEl(containerId);
	var boards     = getEl(boardsId);
	// Canvas elements
	var board      = null;
	var grid       = null;
	var light      = null;
	// Drawing contexts
	var bctx       = null;
	var lctx       = null;
	var gctx       = null;
	var pad        = 20;
	var backGrad   = null;
	var touchGrad  = null;
	var badGrad    = null;
	var showHints  = false;
	var empty      = { "row": -1, "col": -1, "box": -1  };
	var cell       = empty;
	var badCommand = false;
	var badTimeout = null;
	var showHints  = false;
	var blocks     = [];
	var knowns     = [];
	var hints      = [];
	var possible   = [];
	var gridSize   = 0;
	var cellSize   = 0;
	var getHints   = null;
	var getKnowns  = null;
	
	/**
	 * Turn on/off hint visibility.
	 */
	function toggleHints () { showHints = !showHints; drawDigits(); };
	
	/**
	 * Make the given cell the "cursor", highlighting it.
	 * 
	 * @param {Integer} row	Number of the row, in 0-base, with 0 being the topmost row.
	 * @param {Integer} col	Number of the column, in 0-base, with 0 being the leftmost row.
	 */
	function setSelectedCell(row, col) {
		if((row == -1) || (col == -1))
			cell = empty;
		else
			cell = makeCell(row, col);
		drawLights();
	} // setSelectedCell
	
	/**
	 * Return the position data for the cursor cell.
	 */
	function getSelectedCell () { return { row: cell.row, col: cell.col, box: cell.box }; }
	
	/**
	 * Mark the given cells as blocking the current cell update.  These cells
	 * are highlighted briefly with a different color by the buzzCell() method.
	 * 
	 * @param {Array} blockers	The cells to be blocked.  Each cell is in the form { row: Integer, col: Integer }.
	 */
	function setBlocks (blockers) {
		blocks = [];
		for(var i = 0; i < blockers.length; i++)
			blocks.push(makeCell(blockers[i].row, blockers[i].col));
		badCommand = true;
		badTimeout = setTimeout(function() {
			badCommand = false;
			blocks = [];
			badTimeout = null;
			drawLights();
		}, 500);
		drawLights();
	} // setBlocks
	
	/**
	 * Set the cells that have known values.
	 * 
	 * @param {Array} knownCells	The cells that have known values.  Each cell is in the format { row: Integer, col: Integer, term: Integer }.
	 */
	function setKnowns (knownCells) {
		knowns = knownCells;
		drawDigits();
	} // setKnowns
	
	/**
	 * Set the cells that have hinted values.
	 * 
	 * @param {Array} hintCells	The cells that have hinted values.  Each cell is in the format { row: Integer, col: Integer, term: Integer }.
	 */
	function setHints (hintCells) {
		hints = hintCells;
		if (showHints)
			drawDigits();
	} // setKnowns
	
	/**
	 * Set the cells that have possible values.
	 * 
	 * @param {Array} possibleCells	The cells that have possible values.  Each cell is in the format { row: Integer, col: Integer, term: Integer }.
	 */
	function setPossible (possibleCells) {
		possible = possibleCells;
		if (showHints)
			drawDigits();
	} // setKnowns
	
	function setBoards (boardNames, onClick) {
		while(boards.lastChild)
			boards.removeChild(boards.lastChild);
		for(var i = 0; i < boardNames.length; i++) {
			var li = document.createElement("li");
			var a = document.createElement("a");
			li.appendChild(a);
			a.href = '#' + boardNames[i];
			a.appendChild(document.createTextNode(boardNames[i]));
			boards.appendChild(li);
			a.addEventListener('click', function(event) { if(!event) event = window.event; var boardName = unescape(event.target.hash.substring(1,this.href.length)); onClick(boardName); return false; } );
		} // for i
	} // setBoards
	
	/**
	 * Detect the new size of the canvas element, making adjustment to the
	 * drawing and graphics elements as needed.
	 */
	function resizeBoard () {
		var bh = body.innerHeight || body.clientHeight || body.offsetHeight || body.scrollHeight;
		var bw = body.innerWidth  || body.clientWidth  || body.offsetWidth  || body.scrollWidth;
		var w = Math.floor(((bw > bh) ? bh : bw) - (pad * 2));
		var iw = bw - w - (pad * 3.5);
		if (iw < 200) {
			w -= (200 - iw); 
			iw = 200;
		}
		if (board.width != w) { // try to avoid resizes if we can
			inst.style.width = iw + "px";
			board.width = w;
			board.height = w;
			grid.height = w;
			grid.width = w;
			light.height = w;
			light.width = w;
			gridSize = (board.width > board.height) ? board.height : board.width;
			cellSize = gridSize / 9.0;
			backGrad = bctx.createLinearGradient(0,0,gridSize,gridSize);
				backGrad.addColorStop(0, "#eeeed0");
				backGrad.addColorStop(1.0, "#ffffff");
			touchGrad = bctx.createLinearGradient(0,0,0,cellSize);
				touchGrad.addColorStop(0, "rgba(63,127,255,0.2)");
				touchGrad.addColorStop(1, "rgba(63,127,255,0.5)");
			badGrad = bctx.createLinearGradient(0,0,0,cellSize);
				badGrad.addColorStop(0, "rgba(255,127,63,0.2)");
				badGrad.addColorStop(1, "rgba(255,127,63,0.5)");
			cell = makeCell(cell.row, cell.col);
			// redraw everything at the new size
			drawLights();
			drawGrid();
			drawDigits();
		} // if resized
	} // resizeBoard
	
	/**
	 * Draw the digit in at the given coordinates.  We could also do this with
	 * the new canvas text-drawing routines, but this is more reliable.  (And I
	 * get to show off my mad fontography skillz, yo.)
	 * 
	 * @param {Integer}	x    	The x-coordinate of the top-left of the box.
	 * @param {Integer}	y    	The y-coordinate of the top-left of the box.
	 * @param {Integer}	s    	The width and height of the box.
	 * @param {Integer}	t    	The digit to draw.
	 * @param {String}	color	The color to draw the digit with.
	 */
	function drawTerm (x, y, s, t, color) {
		x += (s * 0.1);
		y += (s * 0.1);
		s *= 0.8;
		bctx.save();
			if (t == 9) { // cheat by drawing a rotated 6
				t = 6;
				bctx.translate(x + s, y + s);
				bctx.scale(s / -16, s / -16);
			} else {
				bctx.translate(x, y);
				bctx.scale(s / 16, s / 16);
			}
			bctx.strokeStyle = color;
			bctx.lineCap     = "round";
			bctx.lineJoin    = "miter";
			bctx.lineWidth   = 1.15;
			bctx.beginPath();
			switch(t) {
				case 1: bctx.moveTo(6, 3); bctx.lineTo(8, 2); bctx.lineTo(8, 14); break;
				case 2: bctx.moveTo(5, 5); bctx.arc(8, 5, 3, Math.PI, Math.PI / 5, false); bctx.lineTo(5, 14); bctx.lineTo(11, 14);  break;
				case 3: bctx.moveTo(5.25, 5.25); bctx.arc(8, 5, 2.75, Math.PI, Math.PI * 7 / 16, false); bctx.arc(8, 11, 3, Math.PI * -7 / 16, Math.PI, false); break;
				case 4: bctx.moveTo(13, 9); bctx.lineTo(3, 9); bctx.lineTo(9, 2); bctx.lineTo(9, 14); break;
				case 5: bctx.moveTo(12, 2); bctx.lineTo(6, 2); bctx.lineTo(4.5, 6); bctx.arc(8, 9.5, 4.5, Math.PI * -3 / 4, Math.PI * 3 / 4, false); break;
				case 6: bctx.moveTo(10, 2); bctx.lineTo(5.5, 8); bctx.arc(8, 10.5, 3.5, Math.PI * -4 / 5, Math.PI * -2.5 / 5, true); break;
				case 7: bctx.moveTo(5, 2); bctx.lineTo(11, 2); bctx.lineTo(5, 14); bctx.moveTo(7, 7.5); bctx.lineTo(9, 8); break;
				case 8: bctx.arc(8, 4.6, 2.6, Math.PI * 5 / 8, Math.PI * 3 / 8, false); bctx.arc(8, 10, 3.4, Math.PI * 2 / -8, Math.PI * 10 / 8, false); bctx.closePath(); break;
			}; // switch t
			bctx.stroke();
		bctx.restore();
	} // drawTerm
	
	/**
	 * Handle the user clicking on the board, by selecting the appropriate cell.
	 *  
	 * @param	{Object}	event
	 * @todo	Should this be in the controller?  Or maybe just have the controller pass in the (x,y)?
	 */
	function clickBoard (event) {
		if(!event) event = window.event;
		var target = event.target || event.toElement || event.srcElement;
		// if(target.tagName.toLowerCase() != "canvas") return;
		var x = event.clientX - target.offsetLeft;
		var y = event.clientY - target.offsetTop;
		var row = Math.floor(y / cellSize);
		var col = Math.floor(x / cellSize);
		var box = (Math.floor(row / 3) * 3) + Math.floor(col / 3);
		if ((col >= 0) && (col <= 8) && (row >= 0) && (row <= 8) && (box >= 0) && (box <= 8) && ((row != cell.row) || (col != cell.col)))
			cell = makeCell(row, col);
		else
			cell = makeCell(-1, -1);
		event.cancelBubble = true;
		if(event.stopPropagation) event.stopPropagation();
		drawLights();
	} // clickBoard
	
	/**
	 * Private method to calculate all of the extra drawing information
	 * for the cell at the given row and column.
	 * 
	 * @param {Integer} row	The number of the row, with 0 being the topmost row.
	 * @param {Integer} col	The number of the column, with 0 being the leftmost column.
	 */
	function makeCell (row, col) {
		var ell = {
			"row": row,
			"col": col,
			"box": row == -1 ? -1 : (Math.floor(row / 3) * 3) + Math.floor(col / 3),
			"size": cellSize
		};
		if ((row != -1) && (col != -1)) {
			ell.x1 = Math.round(col * cellSize);
			ell.y1 = Math.round(row * cellSize);
			ell.w = Math.round(cellSize);
			ell.h = Math.round(cellSize);
		}
		return ell;
	} // makeCell
	
	/**
	 * Private method to calculate all of the extra drawing information
	 * for the possibile digit in the cell at the given row and column.
	 * 
	 * @param {Integer} row 	The number of the row, with 0 being the topmost row.
	 * @param {Integer} col 	The number of the column, with 0 being the leftmost column.
	 * @param {Integer} term	The number of the digit, in the range 1..9
	 */
	function makePossible (row, col, term) {
		var ell = {
			"row": row,
			"col": col,
			"box": row == -1 ? -1 : (Math.floor(row / 3) * 3) + Math.floor(col / 3),
			"size": cellSize / 3.0
		};
		if ((row != -1) && (col != -1)) {
			ell.x1 = Math.round((col * cellSize) + (ell.size * ((term - 1) % 3)));
			ell.y1 = Math.round((row * cellSize) + (ell.size * Math.floor((term - 1) / 3.0)));
			ell.w = Math.round(cellSize / 3.0);
			ell.h = Math.round(cellSize / 3.0);
		}
		return ell;
	} // makeCell
	
	/**
	 * Redraw the only the cursor and other highlight effects.
	 */
	function drawGrid() {
		grid.width = grid.width;  // magic incantation that clears the canvas
		gctx.save();
			// lines
			gctx.strokeStyle = "#000000";
			gctx.lineCap     = "butt";
			gctx.lineJoin    = "miter";
			gctx.save();
				// cell lines
				gctx.linewidth = 2;
				gctx.beginPath();
				for(var i = 1; i < 9; i++) {
					gctx.moveTo(i * cellSize, 0);
					gctx.lineTo(i * cellSize, gridSize);
					gctx.moveTo(0, i * cellSize);
					gctx.lineTo(gridSize, i * cellSize);
				} // for i
				gctx.closePath();
				gctx.stroke();
			gctx.restore();
			gctx.save();
				// box lines
				gctx.lineWidth = 4;
				gctx.beginPath();
				gctx.moveTo(gridSize / 3, 0);
				gctx.lineTo(gridSize / 3, gridSize);
				gctx.moveTo(gridSize * 2 / 3, 0);
				gctx.lineTo(gridSize * 2 / 3, gridSize);
				gctx.moveTo(0, gridSize / 3);
				gctx.lineTo(gridSize, gridSize / 3);
				gctx.moveTo(0, gridSize * 2 / 3, 0);
				gctx.lineTo(gridSize, gridSize * 2 / 3);
				gctx.closePath();
				gctx.stroke();
			gctx.restore();
			gctx.save();
				// heavy border
				gctx.lineWidth = 4;
				gctx.strokeRect(2,2,gridSize-4,gridSize-4);
			gctx.restore();
		gctx.restore();
	} // drawGrid
	
	/**
	 * Redraw only the light effects.  Happens when the cursor moves,
	 * or when blocking effects are needed.
	 */
	function drawLights() {
		light.width = light.width;  // magic incantation that clears the canvas
		lctx.save();
			// background gradient
			lctx.fillStyle = backGrad;
			lctx.fillRect(0,0,gridSize,gridSize);
		lctx.restore();
		if(blocks.length > 0) {
			// cells blocking the current action, highlighted
			lctx.save();
			lctx.fillStyle = badGrad;
				for(var i = 0; i < blocks.length; i++) {
					lctx.save();
					lctx.translate(blocks[i].x1, blocks[i].y1);
					lctx.fillRect(0, 0, blocks[i].w, blocks[i].h);	
					lctx.restore();
				} // for i
			lctx.restore();
		} // if blockers
		if (cell.box != -1) {
			// selected cell
			lctx.save();
			lctx.fillStyle = badCommand ? badGrad : touchGrad;
			lctx.translate(cell.x1, cell.y1);
			lctx.fillRect(0, 0, cell.w, cell.h);
			lctx.restore();
		} // if selected cell
	} // drawLights
	
	/**
	 * Redraw the digits on the board.
	 */
	function drawDigits () {
		// resizeBoard();
		board.width = board.width;  // magic incantation that clears the canvas
		if (showHints) {
			// cells with hint values in a lighter color
			for (var i = 0; i < hints.length; i++) {
				var c = makeCell(hints[i].row, hints[i].col);
				drawTerm(c.x1, c.y1, c.w, hints[i].term, "#cccccc");
			} // for i
			// cells with possible values
			for (var i = 0; i < possible.length; i++) {
				var c = makePossible(possible[i].row, possible[i].col, possible[i].term);
				drawTerm(c.x1, c.y1, c.w, possible[i].term, "#cccccc");
			} // for i
		}
		// cells with known values
		for(var i = 0; i < knowns.length; i++) {
			var c = makeCell(knowns[i].row, knowns[i].col);
			drawTerm(c.x1, c.y1, c.w, knowns[i].term, knowns.length == 81 ? "#33ff33" : "#000000");
		} // for i
	}; // drawDigits
	
	/*
	 * Begin constructor code.
	 */
	while(container.lastChild)
		container.removeChild(container.lastChild);
	light = document.createElement("canvas");
	grid  = document.createElement("canvas");
	board = document.createElement("canvas");
	container.appendChild(light);
	container.appendChild(grid);
	container.appendChild(board);
	lctx  = light.getContext("2d");
	gctx  = grid.getContext("2d");
	bctx  = board.getContext("2d");
	container.addEventListener("click", clickBoard, true);
	window.addEventListener("resize", drawDigits, true);
	resizeBoard();
		
	/*
	 * Return only references to the public methods.
	 */
	return {
		toggleHints:       toggleHints,
		setSelectedCell:   setSelectedCell,
		getSelectedCell:   getSelectedCell,
		clickBoard:        clickBoard,
		setHints:          setHints,
		setKnowns:         setKnowns,
		setBlocks:         setBlocks,
		setPossible:       setPossible,
		setBoards:         setBoards
	};
}; // SudokuViewCanvas
