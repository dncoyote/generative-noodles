import processing.svg.*;


int TILE_SIZE = 100;
int GRID_W = 19;
int GRID_H = 11;

boolean showGrid = true;
boolean saveFile = false;

PShape head;
Noodle noodle; 
Noodle noodle2;

int numNoodles = 20;
Noodle[] noodles;

Point[][] paths;
int[][] cells;



void settings() {
	size(TILE_SIZE * GRID_W, TILE_SIZE * GRID_H);
	pixelDensity(displayDensity());
}

void setup() {
	head = loadShape("test.svg");
	reset();
}

void draw() {
	background(255);
	if(showGrid){
		drawGrid();
	}
	
	if(saveFile){
		beginRecord(SVG, "output/" + getFileName() + ".svg");
	}

	for(int i=0; i < numNoodles; i++){
		noodles[i].draw();
	}	

	
	if(saveFile){
		endRecord();
		saveFile = false;
	}

}

void reset() {

	cells = new int[GRID_W][GRID_H];
	noodles = new Noodle[numNoodles];
	
	
	for(int i=0; i < numNoodles; i++){
		Point[] p = createNoodlePath(cells);
		noodles[i] = new Noodle(p, TILE_SIZE, head);
	}
}

void keyPressed() {
	switch(key) {
		case 's' :
			saveFile = true;
		break;
		case 'g':
			showGrid = !showGrid;
		break;
		case 'r':
			reset();
		break;
	}
}



void drawGrid() {
	pushMatrix();
	stroke(200);
	strokeWeight(1);
	for(int row = 0; row < GRID_H; row++){
		for(int col = 0; col < GRID_W; col++){
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
