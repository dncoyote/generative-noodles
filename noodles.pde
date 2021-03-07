import controlP5.*;
import processing.svg.*;


String SETTINGS_PATH = "config/settings.json";
String configPath = "config/config.json";

float MAX_SCREEN_SCALE = 0.182 * 2; // % - (0.2456 == macbook 1:1) (0.182 == LG Screen)
float SCREEN_SCALE = 0.182 * 2; 
float PRINT_W_INCHES = 11;
float PRINT_H_INCHES = 14;
int PRINT_RESOLUTION = 300;
float MARGIN_INCHES = 0.5;

float MAT_W_INCHES = 10.75;
float MAT_H_INCHES = 13.75;

int TILE_SIZE = 50;
int GRID_W = 11;
int GRID_H = 11;

int PRINT_X = 0;
int PRINT_Y = 0;

int canvasW = int(PRINT_W_INCHES * PRINT_RESOLUTION * SCREEN_SCALE);
int canvasH = int(PRINT_H_INCHES * PRINT_RESOLUTION * SCREEN_SCALE);

int canvasX = 0;
int canvasY = 0;

boolean EDIT_MODE = false;
boolean BLACKOUT_MODE = false;
boolean PATH_EDIT_MODE = false;
int editingNoodle = 0;
int[][] blackoutCells;

boolean saveFile = false;

Noodle noodle; 
Noodle noodle2;

int numNoodles = 3;
Noodle[] noodles;

Point[][] paths;
int[][] cells;

// SETTINGS
boolean showGrid = false;
boolean useTwists = false;
boolean useJoiners = true;
boolean useCurves = true;
float penSizeMM = 0.35;
float strokeSize = calculateStrokeSize();
float noodleThicknessPct = 0.5;



ImageSaver imgSaver = new ImageSaver();
String fileNameToSave = "";

Editor editor;

boolean shiftIsDown = false;
GraphicSet[] graphicSets;


void settings() {
	
	size(displayWidth, displayHeight - 45);
	// fullScreen();
	pixelDensity(displayDensity());
	
}

void setup() {
	editor = new Editor(this);
	// ends = new PShape[4];
	// ends[0] = loadShape("hand.svg");
	// ends[1] = loadShape("hand2.svg");
	// ends[2] = loadShape("ghostHead.svg");
	// ends[3] = loadShape("ghostTail.svg");

	// joiners = new PShape[1];
	// joiners[0] = loadShape("join.svg");
	// joiners[0].disableStyle();
	
	frameRate(12);

	loadSettings(SETTINGS_PATH);
	loadConfigFile(configPath, "");
	reset();
}


float calculateStrokeSize() {
	return (penSizeMM * 0.03937008) * PRINT_RESOLUTION * SCREEN_SCALE;
}

void calculateScreenScale() {
	float maxW = width - 100;
	float maxH = height - 100;
	
	float printW = PRINT_W_INCHES * PRINT_RESOLUTION;
	float printH = PRINT_H_INCHES * PRINT_RESOLUTION;
	SCREEN_SCALE = maxW / printW;
	
	if(printH * SCREEN_SCALE > maxH){
		SCREEN_SCALE = maxH / printH;
	}
	
	if(SCREEN_SCALE > MAX_SCREEN_SCALE){
		SCREEN_SCALE = MAX_SCREEN_SCALE;
	}
	
	canvasW = int(PRINT_W_INCHES * PRINT_RESOLUTION * SCREEN_SCALE);
	canvasH = int(PRINT_H_INCHES * PRINT_RESOLUTION * SCREEN_SCALE);
	
	canvasX = (width - canvasW) /2;
	canvasY = (height - canvasH) /2;
}

void calculateTileSize() {
	int marginPx = int(MARGIN_INCHES * PRINT_RESOLUTION * SCREEN_SCALE);
	int printAreaW = canvasW - marginPx * 2;
	int printAreaH = canvasH - marginPx * 2;
	TILE_SIZE = printAreaW / GRID_W;
	
	if(GRID_H * TILE_SIZE > printAreaH){
		TILE_SIZE = printAreaH / GRID_H;
	}
	
	// tile size must be even
	TILE_SIZE = (TILE_SIZE / 2) * 2;
	
	PRINT_X =  (canvasW - (TILE_SIZE * GRID_W)) / 2;
	PRINT_Y = (canvasH - (TILE_SIZE * GRID_H)) / 2;
		
}

void drawPaperBG() {
	fill(255);
	stroke(80);
	strokeWeight(1);
	rect(canvasX, canvasY, canvasW, canvasH);
}

void drawBG() {
	background(100);
	if(imgSaver.isBusy()){ drawSaveIndicator();}
	drawPaperBG();
	translate(canvasX, canvasY);
}

void draw() {
	
	pushMatrix();
		drawBG();
		if(imgSaver.state == SaveState.SAVING){
			beginRecord(SVG, "output/" + fileNameToSave + ".svg");
			rect(0, 0, canvasW, canvasH);
		}

		// float matW = MAT_W_INCHES * PRINT_RESOLUTION * SCREEN_SCALE;
		// float matH = MAT_H_INCHES * PRINT_RESOLUTION * SCREEN_SCALE;
		// rect((canvasW - matW) / 2, (canvasH - matH) / 2, matW, matH);
		translate(PRINT_X, PRINT_Y);
		if(showGrid){ drawGrid();}
		
		for(int i=0; i < noodles.length; i++){
			noodles[i].draw(TILE_SIZE, noodleThicknessPct, useTwists);
		}	
		
		if(imgSaver.state == SaveState.SAVING) { endRecord(); }
		imgSaver.update();
	popMatrix();
	if(EDIT_MODE) {
		editor.draw();
	} 
}

int[][] copyBlackoutCells() {
	int[][] cells = new int[GRID_W][GRID_H];
	for(int col = 0; col < GRID_W; col++){
		cells[col] = new int[GRID_H];
		for(int row = 0; row < GRID_H; row++){
			if(blackoutCells[col][row] > 0){
				cells[col][row] = blackoutCells[col][row];
			}
		}
	}
	return cells;
}

void updateBlackoutCells() {
	if(blackoutCells == null || GRID_W != blackoutCells.length || GRID_H != blackoutCells[0].length){
		blackoutCells = new int[GRID_W][GRID_H];
	}
}

void updateKeyDimensions() {
	updateBlackoutCells();
	calculateScreenScale();
	calculateTileSize();
}

void reset() {
	updateKeyDimensions();

	cells = copyBlackoutCells();
	noodles = new Noodle[numNoodles];
	
	int noodleCount = 0;
	for(int i=0; i < numNoodles; i++){
		Point[] p = createNoodlePath(cells);
		
		if(p != null){
			int graphicIndex = floor(random(0, graphicSets.length));
			GraphicSet gfx = graphicSets[graphicIndex];
			noodles[noodleCount] = new Noodle(p, TILE_SIZE, gfx.head, gfx.tail, gfx.joiners);
			noodleCount++;
		}
	}
	
	noodles = (Noodle[]) subset(noodles, 0, noodleCount);
}

void deleteNoodle(int indexToDelete) {
	if(noodles.length <= 1) return; // don't delete all the noodles

	Noodle[] updatedNoodles = new Noodle[noodles.length - 1];
	int fillIndex = 0;
	for(int i = 0; i < noodles.length; i++){
		if(i != indexToDelete){
			updatedNoodles[fillIndex] = noodles[i];
			fillIndex++;
		}
	}
	noodles = updatedNoodles;
	editingNoodle = min(editingNoodle, noodles.length - 1);
	
}

void keyReleased() {
	if(keyCode == SHIFT){
		shiftIsDown = false;
	}
}

void keyPressed() {
	switch(keyCode){
		case SHIFT:
			shiftIsDown = true;
		break;
		case BACKSPACE:
			if(PATH_EDIT_MODE){
				deleteNoodle(editingNoodle);
			}
		break;
	}
	switch(key) {
		case 's' :
			fileNameToSave = getFileName();
			imgSaver.begin(fileNameToSave);
		break;
		case 'g':
			showGrid = !showGrid;
			if(!showGrid){
				BLACKOUT_MODE = false;
				PATH_EDIT_MODE = false;
			}
		break;
		case 'r':
			reset();
		break;
		case 't':
			TILE_SIZE++;
		break;
		case 'e':
			EDIT_MODE = !EDIT_MODE;
			if(EDIT_MODE){
				editor.show();
			} else {
				editor.hide();
				
				// reset();
			}
		break;
		case 'x':
			BLACKOUT_MODE = !BLACKOUT_MODE;
			if(BLACKOUT_MODE){
				showGrid = true;
			}
		break;
		case 'p' :
			PATH_EDIT_MODE = !PATH_EDIT_MODE;
			if(PATH_EDIT_MODE){
				showGrid = true;
			}
		break;
	}
}

void mousePressed() {
	Point cell = getCellForMouse(mouseX, mouseY);

	if(BLACKOUT_MODE){
		if(cell.x >= 0 && cell.y >= 0 && cell.x < blackoutCells.length && cell.y < blackoutCells[0].length){
			if(blackoutCells[cell.x][cell.y] > 0){
				blackoutCells[cell.x][cell.y] = 0;
			} else {
				blackoutCells[cell.x][cell.y] = 1;
			}
		} 
	} else if(PATH_EDIT_MODE){
		if(shiftIsDown){
			editingNoodle = findNoodleWithCell(cell.x, cell.y);
		} else {
			if(pathContainsCell(noodles[editingNoodle].path, cell.x, cell.y)){
				if(cellIsEndOfPath(cell.x, cell.y, noodles[editingNoodle].path)){
					Point[] newPath = removeCellFromPath(cell.x, cell.y, noodles[editingNoodle].path);
					noodles[editingNoodle].path = newPath;
				} else {
					Point[] newPath = cycleCellType(cell.x, cell.y, noodles[editingNoodle].path);
					noodles[editingNoodle].path = newPath;
				}
			} else {
				Point[] newPath = addCellToPath(cell.x, cell.y, noodles[editingNoodle].path);
				noodles[editingNoodle].path = newPath;
			}
		}
	}
}

void drawSaveIndicator() {
	pushMatrix();
		fill(color(200, 0, 0));
		noStroke();
		rect(0,0,width, 4);
	popMatrix();
}

boolean pathContainsCell(Point[] path, int col, int row) {
	for(Point p : path){

		if(p != null && p.x == col && p.y == row){
			return true;
		}
	}

	return false;
}

void drawGrid() {
	pushMatrix();
	stroke(200);
	noFill();
	strokeWeight(1);
	for(int row = 0; row < GRID_H; row++){
		for(int col = 0; col < GRID_W; col++){
			if(BLACKOUT_MODE && blackoutCells[col][row] > 0){
				fill(0,25);
			} else if(PATH_EDIT_MODE && pathContainsCell(noodles[editingNoodle].path, col, row)) {
				fill(0, 255, 0, 25);
			} else {
				noFill();
			}
			rect(col * TILE_SIZE, row * TILE_SIZE, TILE_SIZE, TILE_SIZE);
		}
	}
	popMatrix();
}

String getFileName() {
	String d  = str( day()    );  // Values from 1 - 31
	String mo = str( month()  );  // Values from 1 - 12
	String y  = str( year()   );  // 2003, 2004, 2005, etc.
	String s  = str( second() );  // Values from 0 - 59
 	String min= str( minute() );  // Values from 0 - 59
 	String h  = str( hour()   );  // Values from 0 - 23

 	String date = y + "-" + mo + "-" + d + " " + h + "-" + min + "-" + s;
 	String n = date;
 	return n;
}