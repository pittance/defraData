
//Process:
//  Go to: https://environment.data.gov.uk/DefraDataDownload/?Mode=survey
//
//  Use zoom/pan on the map to find the area you're intested in
//
//  Click the "Download your data" button
//
//  Use the buttons below the grey upload box to draw the area you're interested in
//
//  Click "Get available tiles" to see the data that are available for the area you've drawn
//
//  When you're choosing a product you need to decide if you want:
//    - DSM (digital surface model) is the scan data, with trees, houses etc.
//    - DTM (digital terrain model) tries to show you the land without all the crud
//  => Other types of data probably won't work with this code
//
//  You will also need to choose resolution, for a large scale map 1m or 2m is useful
//  finer (0.5 & 0.25m) resolutions probably aren't helpful unless you're checking if
//  you left your bins out on the day of the scan or you want just one or two houses.
//
//  NOTE: not all areas are scanned at the same resolutions or at all: bear in mind that
//  these are environment agency scans, if your house is scanned at 0.25m it probably
//  means it's at risk or flooding, subsiding, eroding or all three.
//
//  When you've chosen your product you can click the link to download: the example uses
//  the square TQ28se in London, the 1m DSM. When you unzip the file you will get a
//  collection of *.asc files containing the data. The filenames tell you which parts
//  of the overall square each file represents. For example all of the data from the
//  zip file are deleted except for 6 files:
//    - tq2580_DSM_1M.asc
//    - tq2581_DSM_1M.asc
//    - tq2680_DSM_1M.asc
//    - tq2681_DSM_1M.asc
//    - tq2780_DSM_1M.asc
//    - tq2781_DSM_1M.asc
//
//  Change the settings below to suit your files:
//    - gridSquare  => e.g. "tq"
//    - xxFrom      => square across start e.g.  
//    - xxTo        => square across end e.g. 
//    - yyFrom      => square up start e.g. 
//    - yyTo        => square up end e.g. 
//    - model       => surface or terrain e.g. "_DSM"
//    - resoln      => resolution of the file e.g. "_1M"
//    - extn        => file extension e.g. ".asc"
//  The data here are used to build up the file name
//  These files are in the bottom left of the square, covering Kensington Gardens
//  and Paddington station.
//
//  On running the code the data will be interpreted in the lidarRead class and used
//  to output a grayscale image representing height data.


//define indices & data for scan, used to reconstruct file name(s)
String gridSquare = "tq";
int xxFrom = 25;
int xxTo = 27;
int yyFrom = 80;
int yyTo = 81;
int numFiles;
String model = "_DSM";
String resoln = "_1M";
String extn = ".asc";

int tileRes = 1000;  //1000 points per tile: 1km square @ 1m resolution

////zoom in on data in the file - from/to metres for x & y (NB needs to be consistent with number of points in the file
//int fromMx = 0;
//int toMx = 1000;
//int fromMy = 0;
//int toMy = 1000;

// in a zip file the files store a vertical raster scan down each column
// when sorted alphabetically. The xx number is the left-right index
// The yy number is the up-down index. The filename is constructed from
// the xx and yy numbers in the format:
//   st5076_DSM_1M.asc
// where:
//   st is the grid square
//   50 is xx
//   76 is yy
//   _DSM identifies that this is a digital surface model (includes cars, trees, houses etc.)
//   _1M is the 1m resolution version

LidarRead[] lr;  //need all to get global max/min, read the data and then write image into the output
String[] fileName = new String[0];
String[] fileData;

int[] indexX = new int[0];
int[] indexY = new int[0];
boolean[] ok = new boolean[0];

int numTilesX;
int numTilesY;


float globalMin = 0;
float globalMax = 0;


//  SETTINGS
boolean drawTileNames = false;
// /SETTINGS

PGraphics outputTiles;

void setup() {
  size(100,100);
  
  //find output image data from input settings
  numTilesX = xxTo-xxFrom+1;
  numTilesY = yyTo-yyFrom+1;
  //find resolution of final tiled image and create it
  outputTiles = createGraphics(numTilesX*tileRes,numTilesY*tileRes);
  
  //load filenames into array
  numFiles = 0;
  int countX = 0;
  int countY = 0;
  for (int i=xxFrom;i<=xxTo;i++) {
    countY = 0;
    for (int j=yyTo;j>=yyFrom;j--) {
      numFiles++;
      fileName = expand(fileName,numFiles);
      indexX = expand(indexX,numFiles);
      indexY = expand(indexY,numFiles);
      ok = expand(ok,numFiles);
      fileName[numFiles-1] = gridSquare+i+j+model+resoln+extn;
      indexX[numFiles-1] = countX;
      indexY[numFiles-1] = countY;
      countY++;
    }
    countX++;
  }
  println(fileName);
  println("index files");
  println("        X");
  println(indexX);
  println("        Y");
  println(indexY);
  
  lr = new LidarRead[numFiles];
  
  println("errors");
  
  //load data into the lidarRead data
  boolean minMaxSet = false;
  for (int i=0;i<numFiles;i++) {
    try {
      ok[i] = true;
      println("ok " + i);
      String[] inData = loadStrings(fileName[i]);
      lr[i] = new LidarRead(inData);
    } catch (NullPointerException np) {
      ok[i] = false;
      println("nopenopenopenopenopenopenopenopenopenopenopenopenopenope " + i);
    }
    if (ok[i]) {
      if (!minMaxSet) {
        globalMin = lr[i].minData;
        globalMax = lr[i].maxData;
        println("Initial global min/max: " + globalMin + "/" + globalMax);
        minMaxSet = true;
      }
      if ((globalMax < lr[i].maxData)) {
        print("  reset global max, from:" + globalMax);
        globalMax = lr[i].maxData;
        println(" to: " + globalMax);
      }
      if ((globalMin > lr[i].minData)) {
        print("  reset global min, from:" + globalMin);
        globalMin = lr[i].minData;
        println(" to: " + globalMin);
      }
    }
  }
  
  println("final GLOBAL min: " + globalMin);
  println("final GLOBAL max: " + globalMax);
  
  outputTiles.beginDraw();
  PFont myFont = createFont("arial",30);
  outputTiles.textFont(myFont);
  outputTiles.fill(255,0,0);
  for (int i=0;i<numFiles;i++) {
    println("exporting............." + i);
    if (ok[i]) {
      lr[i].lidarWrite(globalMin,globalMax);
      outputTiles.image(lr[i].imageAlpha,indexX[i]*tileRes,indexY[i]*tileRes);
      if(drawTileNames)outputTiles.text(fileName[i],indexX[i]*tileRes+50,indexY[i]*tileRes+50);
    }
  }
  outputTiles.endDraw(); 
  println("saving.............");
  outputTiles.save("out.png");
  println("done...............");
  
  noLoop();
}

void draw() {
  println("closing...............");
  exit();
}