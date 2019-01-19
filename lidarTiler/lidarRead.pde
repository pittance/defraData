class LidarRead {
  
  PImage imageAlpha;
  PImage imageSolid;
  
  //metadata (to read from file)
  int headerRows = 6;  //for each file, 6 rows of data, stored in variables below
  int ncols;
  int nrows;
  float xllcorner;
  float yllcorner;
  float cellsize;
  float NODATA_value;
  
  //data
  float[][] dataNum;
  float maxData;
  float minData;
  int minAtX = 0;
  int minAtY = 0;
  int maxAtX = 0;
  int maxAtY = 0;
  
  boolean drawMin = false;
  boolean drawMax = false;
  
  LidarRead(String[] data) {
    //argument should be a string array from loadStrings
    //read header data
    ncols = int(splitTokens(data[0])[1]);
    nrows = int(splitTokens(data[1])[1]);
    xllcorner = float(splitTokens(data[2])[1]);
    yllcorner = float(splitTokens(data[3])[1]);
    cellsize = float(splitTokens(data[4])[1]);
    NODATA_value = float(splitTokens(data[5])[1]);
    //output header data
    println("metadata:");
    println("  " + ncols + " columns, " + nrows + " rows");
    println("  xllcorner: " + xllcorner);
    println("  yllcorner: " + yllcorner);
    println("  cellsize: " + cellsize);
    println("  NODATA_value: " + NODATA_value);
    
    //read data & store
    String[] lineData;
    dataNum = new float[nrows][ncols];
    imageAlpha = createImage(ncols,nrows,ARGB);
    imageSolid = createImage(ncols,nrows,RGB);

    for (int i=0;i<nrows;i++) {
      lineData = splitTokens(data[headerRows+i]);
      for (int j=0;j<ncols;j++) {
        dataNum[i][j] = float(lineData[j]);
      }
    }
    
    minData = minDataVal();
    maxData = maxDataVal();
  }
  
  void lidarWrite() {
    minData = minDataVal();
    maxData = maxDataVal();
    
    for (int i=0;i<nrows;i++) {
      for (int j=0;j<ncols;j++) {
        if (dataNum[i][j] == NODATA_value) {
          imageAlpha.set(j,i,color(map(dataNum[i][j],minData,maxData,0,255),0));
        } else {
          imageAlpha.set(j,i,color(map(dataNum[i][j],minData,maxData,0,255),255));
        }
        imageSolid.set(j,i,color(map(dataNum[i][j],minData,maxData,0,255)));
      }
    }
  }
  
  void lidarWrite(float inMin, float inMax) {
    
    for (int i=0;i<nrows;i++) {
      for (int j=0;j<ncols;j++) {
        if (dataNum[i][j] == NODATA_value) {
          imageAlpha.set(j,i,color(map(dataNum[i][j],inMin,inMax,0,255),0));
        } else {
          imageAlpha.set(j,i,color(map(dataNum[i][j],inMin,inMax,0,255),255));
          if (drawMin) {
            if ((i == minAtX) && (j == minAtY)) imageAlpha.set(j,i,color(255,0,0));
          }
          if (drawMax) {
            if ((i == maxAtX) && (j == maxAtY)) imageAlpha.set(j,i,color(0,0,255));
          }
        }
        imageSolid.set(j,i,color(map(dataNum[i][j],inMin,inMax,0,255)));
      }
    }
  }
  
  void lidarDraw() {
    minData = minDataVal();
    maxData = maxDataVal();
    
    for (int i=0;i<nrows;i++) {
      for (int j=0;j<ncols;j++) {
        if (dataNum[i][j] == NODATA_value) {
          set(j,i,color(map(dataNum[i][j],minData,maxData,0,255),0));
        } else {
          set(j,i,color(map(dataNum[i][j],minData,maxData,0,255),255));
        }
        set(j,i,color(map(dataNum[i][j],minData,maxData,0,255)));
      }
    }
  }
  
  float maxDataVal() {
    float tempMax = dataNum[0][0];
    for (int i=0;i<nrows;i++) {
      for (int j=0;j<ncols;j++) {
        if (dataNum[i][j] > tempMax) {
          tempMax = dataNum[i][j];
          maxAtX = i;
          maxAtY = j;
        }
      }
    }
    println("max value: " + tempMax);
    return tempMax;
  }
  
  float minDataVal() {
    float tempMin = dataNum[0][0];
    
    //possible that the first value is the no data flag, reset with something better if so
    if (tempMin == NODATA_value) tempMin = maxDataVal();
    
    for (int i=0;i<nrows;i++) {
      for (int j=0;j<ncols;j++) {
        if (dataNum[i][j] < tempMin) {
          if (dataNum[i][j] != NODATA_value) {
            tempMin = dataNum[i][j];
            minAtX = i;
            minAtY = j;
          }
        }
      }
    }
    println("min value: " + tempMin);
    return tempMin;
  }
  
  float[][] getData(float noDataReplace) {
    float[][] tempOut = new float[nrows][ncols];
    for (int i=0;i<nrows;i++) {
      for (int j=0;j<ncols;j++) {
        if (dataNum[i][j] == NODATA_value) {
          tempOut[i][j] = noDataReplace;
        } else {
          tempOut[i][j] = dataNum[i][j];
        }
      }
    }
    return tempOut;
  }
  
  
}