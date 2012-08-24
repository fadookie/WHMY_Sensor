import processing.serial.*;
import processing.net.*;

//Data for setting up the Arduino Serial Connection
Serial myPort;                       // The serial port
int[] serialInArray = new int[8];    // Where we'll put what we receive
int serialCount = 0;                 // A count of how many bytes we receive
boolean firstContact = false;        // Whether we've heard from the microcontroller

//Data for Setting Up the Flash Socket Server
int sport = 9002;
Server myServer;
byte zero = 0;

String s_X = "0";
String s_Y = "0";
String connectionStatus = "Not Connected";
int _X = 0;
int _Y = 0;
int maxX = 0;
int maxY = 0;
int minX = 10000;
int minY = 10000;
int graphDensity = 500;
ArrayList xData;
ArrayList yData;
ArrayList averageXData;
ArrayList averageYData;
ArrayList timeCodeData;
ArrayList periodXData;
ArrayList periodYData;
PFont f;

//Data for separated axis graph
int graphX = 0;
int graphY = 600;
int graphHeight = 300;
int graphWidth = 300;

//Data for x,y combined graph
int graph2X = 300;
int graph2Y = 600;
int graph2Height = 300;
int graph2Width = 300;

//Data for Period Graph
int graph3X = 300;
int graph3Y = 150;
int graph3Height = 150;
int graph3Width = 300;

//Period Bounds Data
int periodMax = 8;
int periodMin = 0;

//Axis Bounds Data
int dataMax = 8000;
int dataMin = 0;

//Analysis Data
float averageX = 0.0;
float averageY = 0.0;

float lastPeriodX = 0;
float lastPeriodY = 0;

float hzX = 0.0;
float hzY = 0.0;

float lastDataX = 5000;
float lastDataY = 5000;

float noiseReducer = 100;

void setup() {
  size(600, 600);  // Stage size
  
  xData = new ArrayList();
  yData = new ArrayList();
  averageXData = new ArrayList();
  averageYData = new ArrayList();
  timeCodeData = new ArrayList();
  periodXData = new ArrayList();
  periodYData = new ArrayList();
  
  //fill arrayList with '5000's which is unity for the accellerometer 
  for(int counter=0;counter < graphDensity; counter++)
  {
    xData.add(5000.0);
    yData.add(5000.0);
    averageXData.add(5000.0);
    averageYData.add(5000.0);
    periodXData.add(0.0);
    periodYData.add(0.0);
  }
  
  f = loadFont("Verdana-14.vlw");
  textFont(f);
  fill(0);

  // Print a list of the serial ports, for debugging purposes:
  println(Serial.list());
  
  String portName = Serial.list()[3];
  myPort = new Serial(this, portName, 9600);

  //Settup the socket server
  myServer = new Server(this,sport);
}


void draw() {
  if(firstContact)
  {
    tick();
    exportData();
  }
  
  background(127);
  
  /***********
  Text display
  ***********/
  fill(255);
  text(connectionStatus, 20, 40);
  text("x: " + _X + "\ny: " + _Y + "\n\nMaxX: " + maxX + "\nMinX: " + minX + "\n\nMaxY: " + maxY + "\nMinY: " + minY + "\nPeriodX: " + hzX + "\nPeriodY: " + hzY + "\n\nMillis: " + millis(), 20, 100);
  
  /***********
  GRAPH 1
  ***********/
  //DRAW X AXIS
  stroke(255); //x axis should be white
  noFill(); //don't fill the graph curves
  beginShape();
  curveVertex(graphX, graphY - ((Float)xData.get(0) / dataMax) * graphHeight); //first point on the curve (duplicated in for loop)
  for(int i=0;i<xData.size();i++)
  { 
    float pX = graphX + ((float)i / graphDensity) * graphWidth;
    float pY = graphY - ((Float)xData.get(i) / dataMax) * graphHeight;
    curveVertex(pX,pY);
  }
  curveVertex(graphX+graphHeight, graphY - ((Float)xData.get(xData.size()-1) / dataMax) * graphHeight); //last point on the curve (duplicated in for loop)
  endShape();
  
  //DRAW Y AXIS
  stroke(0);
  beginShape();
  curveVertex(graphX, graphY - ((Float)yData.get(0) / dataMax) * graphHeight);
  for(int j=0;j<yData.size();j++)
  {
    float pX = graphX + ((float)j / graphDensity) * graphWidth;
    float pY = graphY - ((Float)yData.get(j) / dataMax) * graphHeight;
    curveVertex(pX,pY);
  }
  curveVertex(graphX+graphHeight, graphY - ((Float)yData.get(yData.size()-1) / dataMax) * graphHeight);
  endShape();
  
  //DRAW AVERAGE LINES
  //DRAW X AXIS INSTANT AVERAGE
  stroke(255,80);
  beginShape();
  curveVertex(graphX, graphY - ((Float)averageXData.get(0) / dataMax) * graphHeight);
  for(int j=0;j<yData.size();j++)
  {
    float pX = graphX + ((float)j / graphDensity) * graphWidth;
    float pY = graphY - ((Float)averageXData.get(j) / dataMax) * graphHeight;
    curveVertex(pX,pY);
  }
  curveVertex(graphX+graphHeight, graphY - ((Float)averageXData.get(yData.size()-1) / dataMax) * graphHeight);
  endShape();
  //line(graphX, graphY - (averageX/dataMax)*graphHeight,graphX+graphWidth,graphY - (averageX/dataMax)*graphHeight);
  
  //DRAW Y AXIS INSTANT AVERAGE
  stroke(0,80);
  beginShape();
  curveVertex(graphX, graphY - ((Float)averageYData.get(0) / dataMax) * graphHeight);
  for(int j=0;j<yData.size();j++)
  {
    float pX = graphX + ((float)j / graphDensity) * graphWidth;
    float pY = graphY - ((Float)averageYData.get(j) / dataMax) * graphHeight;
    curveVertex(pX,pY);
  }
  curveVertex(graphX+graphHeight, graphY - ((Float)averageYData.get(yData.size()-1) / dataMax) * graphHeight);
  endShape();
  //line(graphX, graphY - (averageY/dataMax)*graphHeight,graphX+graphWidth,graphY - (averageY/dataMax)*graphHeight);
  
  /***********
  GRAPH 2
  ***********/
  stroke(0, 100);
  beginShape();

  for(int j=0;j<yData.size()-1;j++)
  {
    float pX = graph2X + ((Float)xData.get(j) / dataMax) * graph2Width;
    float pY = graph2Y - ((Float)yData.get(j) / dataMax) * graph2Height;
    curveVertex(pX,pY);
  }

  endShape();
  
  stroke(255);
  ellipse((graph2X + ((Float)xData.get(xData.size()-1) / dataMax) * graph2Width),(graph2Y - ((Float)yData.get(yData.size()-1) / dataMax) * graph2Height),10,10);
  

  /************
  GRAPH 3 - Period
  *************/
  //DRAW X AXIS
  stroke(255); //x axis should be white
  noFill(); //don't fill the graph curves
  beginShape();
  curveVertex(graph3X, graph3Y - ((Float)periodXData.get(0) / periodMax) * graph3Height); //first point on the curve (duplicated in for loop)
  for(int i=0;i<periodXData.size();i++)
  { 
    float pX = graph3X + ((float)i / graphDensity) * graph3Width;
    float pY = graph3Y - ((Float)periodXData.get(i) / periodMax) * graph3Height;
    curveVertex(pX,pY);
  }
  curveVertex(graph3X+graph3Height, graph3Y - ((Float)periodXData.get(periodXData.size()-1) / periodMax) * graph3Height); //last point on the curve (duplicated in for loop)
  endShape();
  
  //DRAW Y AXIS
  stroke(0);
  beginShape();
  curveVertex(graph3X, graph3Y - ((Float)periodYData.get(0) / periodMax) * graph3Height);
  for(int j=0;j<periodYData.size();j++)
  {
    float pX = graph3X + ((float)j / graphDensity) * graph3Width;
    float pY = graph3Y - ((Float)periodYData.get(j) / periodMax) * graph3Height;
    curveVertex(pX,pY);
  }
  curveVertex(graph3X+graph3Height, graph3Y - ((Float)periodYData.get(periodYData.size()-1) / periodMax) * graph3Height);
  endShape();
}

void tick(){
  //for average
  int averageDistance = 40; //how many datapoints to use to calulate the current average
  float averageDropoff = 0.9; //what is the dropoff for distance to current for average calculations
  float averageSum = 0;

  //for frequency
  int currentSettingX = 0;
  int currentSettingY = 0;

  //number of peaks
  int peakCount = 0;

  //data window to look at
  int windowSize = 30;

  if(firstContact == true) //has first contact occured
  {
    //Calculate and draw x axis average
    for(int i=0;i<averageDistance;i++)
    {
      averageSum += (Float)xData.get(xData.size()-1-i);
    }
    
    averageX = averageSum / (float)averageDistance;
    
    
    //Calculate and draw y axis average
    averageSum = 0;
    
    for(int i=0;i<averageDistance;i++)
    {
      averageSum += (Float)yData.get(yData.size()-1-i);
    }
    
    averageY = averageSum / (float)averageDistance;
        

    //Calculate the current frequency X
   
    //get the seconds represented by the window
    int timeScale = ((Integer)timeCodeData.get(timeCodeData.size() - 1) - (Integer)timeCodeData.get(timeCodeData.size() - 1 - windowSize))/1000;
    float lastDataX = (Float)xData.get(xData.size()-1);
    
    int switchesX = 0;
    int switchesY = 0;

    //Saying peaks and valleys is actually a misnomer.  Just using it to hold two points.
    float lastPeakX = 5000;

    int lastState = 1;
    int thisState = 1;

    int switchesPerStepX = 0;

    float sizeReduction = 30;

    for(int i = 1;i<windowSize;i++)
    { 
      float p1 = (Float)xData.get(xData.size() - 1 - i);
      float p2 = lastDataX;
      lastDataX = (Float)xData.get(xData.size() - 1 - i);

      if(p1 < p2)
      {
        thisState = 1;
      }
      else 
      {
        thisState = -1;
      }

      if(thisState != lastState)
      {
        if(verifyStateChange(p1,i,thisState))
        {
          if(abs(p1 - lastPeakX) >= sizeReduction)
          {
            switchesX++;
          }
          else
          {
            //println("negating switch, too small a change");
          }
          lastState = thisState;
          lastPeakX = p1;
        }
      }
    }
    if(timeScale!=0)
    { 
      hzX = (float)((float)switchesX / (float)timeScale)/2.0;
    }
  }
}

//verifyStateChange(p1,i,thisState);
boolean verifyStateChange(Float p1,int i,int goalState)
{
  int thisState = 0;
  int verifyRange = 1;

  for(int offset = 1;offset<verifyRange;offset++)
  {
    float p3 = (Float)xData.get(xData.size() - 1 - i - offset);

    if(p1 < p3)
    {
      thisState = 1;
    }
    else 
    {
      thisState = -1;
    }

    if(thisState != goalState)
    {
      println("thisState != goalState in verifyStateChange");
      return false;
    }
  }

  return true;
}

void serialEvent(Serial myPort) {
  //data for smoothing
  float weightedAverageX = 0.0;
  float weightedAverageY = 0.0;
  float sumCombos = 0.0;
  float sumWeights = 0.0;
  
  int weightWidth = 10; //number of spaces to go in each direction 
  float weightFactor = 0.4;
  
  // read a byte from the serial port:
  int inByte = myPort.read();
  // if this is the first byte received, and it's an A,
  // clear the serial buffer and note that you've
  // had first contact from the microcontroller. 
  // Otherwise, add the incoming byte to the array:
  if (firstContact == false) {
    println("firstContact");
    if (inByte == 'A') { 
      //fill the timecode with the data collection start time
      for(int counter=0;counter < graphDensity; counter++)
      {
        timeCodeData.add(millis());
      }
      myPort.clear();          // clear the serial port buffer
      firstContact = true;     // you've had first contact from the microcontroller
      myPort.write('A');       // ask for more
      connectionStatus = "connected";
    } 
  } 
  else {
    serialInArray[serialCount] = inByte;
    //println(serialCount + ": " + inByte);
    serialCount++;

    // If we have 8 bytes:
    if (serialCount > 7) {
      s_X = ""+int(serialInArray[0] - 48);
      s_X += ""+int(serialInArray[1] - 48);
      s_X += ""+int(serialInArray[2] - 48);
      s_X += ""+int(serialInArray[3] - 48);
      
      s_Y = ""+int(serialInArray[4] - 48);
      s_Y += ""+int(serialInArray[5] - 48);
      s_Y += ""+int(serialInArray[6] - 48);
      s_Y += ""+int(serialInArray[7] - 48);
      
      _X = int(s_X);
      _Y = int(s_Y);
      
      //smooth x axis
      sumCombos = _X;
      sumWeights = 1.0;
    
      for(int k = 1; k <= weightWidth; k++)
      {
        if((xData.size()-1-k)>=0)
        {
          sumCombos += ((Float)xData.get((xData.size()-1)-k) * pow(weightFactor, k));
          sumWeights += (pow(weightFactor, k));
        }
      }
      
      weightedAverageX = (float)sumCombos / (float)sumWeights;
      
      //smooth the data for y axis
      sumCombos = _Y;
      sumWeights = 1.0;
      
      for(int l = 1; l <= weightWidth; l++)
      {
        if((yData.size()-1-l)>=0)
        {
          sumCombos += ((Float)yData.get((yData.size()-1)-l) * pow(weightFactor, l));
          sumWeights += (pow(weightFactor, l));
        }
      }
      
      weightedAverageY = (float)sumCombos / (float)sumWeights;
      
      //add the new data, remove the old
      //should maintain the size of the list
      xData.remove(0);
      xData.add(weightedAverageX);
      yData.remove(0);
      yData.add(weightedAverageY);
      averageXData.remove(0);
      averageXData.add(averageX);
      averageYData.remove(0);
      averageYData.add(averageY);
      timeCodeData.remove(0);
      timeCodeData.add(millis()); 
      periodXData.remove(0);
      periodXData.add(hzX);
      periodYData.remove(0);
      periodYData.add(hzY);
      
      if(_X > maxX)
      {
        maxX = _X;
      }
      
      if(_Y > maxY)
      {
        maxY = _Y;
      }
      
      if(_X < minX)
      {
        minX = _X;
      }
      
      if(_Y < minY)
      {
        minY = _Y;
      }
      
      serialCount = 0;
       
    }
    myPort.write('A');
  }
}

void exportData()
{
  //((Float)periodXData.get(periodXData.size()-1)
    //converting the number to an int 1000x as big.
    Float rockData = ((Float)periodXData.get(periodXData.size()-1)) * 1000;
    int rockInt = int(rockData);
    println(rockInt);
    myServer.write(rockInt+"\0");
}

void stop()
{

}
