import processing.serial.*;
import ddf.minim.*;

Serial myPort;                       // The serial port
int[] serialInArray = new int[8];    // Where we'll put what we receive
int serialCount = 0;                 // A count of how many bytes we receive
boolean firstContact = false;        // Whether we've heard from the microcontroller

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
PFont f;

int graphX = 0;
int graphY = 600;
int graphHeight = 300;
int graphWidth = 300;

int dataMax = 8000;
int dataMin = 0;

//Data for x,y combined graph
int graph2X = 300;
int graph2Y = 600;
int graph2Height = 300;
int graph2Width = 300;

//Analysis Data
float averageX = 0.0;
float averageY = 0.0;

int lastSettingX = 0;
int lastSettingY = 0;

float timeFromSwitchX = 0.0;
float timeFromSwitchY = 0.0;

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
  
  //fill arrayList with '5000's which is unity for the accellerometer
  for(int counter=0;counter < graphDensity; counter++)
  {
    xData.add(5000.0);
    yData.add(5000.0);
    averageXData.add(5000.0);
    averageYData.add(5000.0);
  }
  
  f = loadFont("Verdana-14.vlw");
  textFont(f);
  fill(0);

  // Print a list of the serial ports, for debugging purposes:
  println(Serial.list());
  
  String portName = Serial.list()[3];
  myPort = new Serial(this, portName, 9600);
}


void draw() {
  tick();
  background(127);
  
  /***********
  Text display
  ***********/
  fill(255);
  text(connectionStatus, 20, 40);
  text("x: " + _X + "\ny: " + _Y + "\n\nMaxX: " + maxX + "\nMinX: " + minX + "\n\nMaxY: " + maxY + "\nMinY: " + minY + "\nPeriodX: " + hzX + "\nPeriodY: " + hzY, 20, 100);
  
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
  stroke(255,50);
  line(graphX, graphY - (averageX/dataMax)*graphHeight,graphX+graphWidth,graphY - (averageX/dataMax)*graphHeight);
  
  stroke(0,50);
  line(graphX, graphY - (averageY/dataMax)*graphHeight,graphX+graphWidth,graphY - (averageY/dataMax)*graphHeight);
  
  /***********
  GRAPH 2
  ***********/
  stroke(0, 100);
  beginShape();

  for(int j=0;j<yData.size();j++)
  {
    float pX = graph2X + ((Float)xData.get(j) / dataMax) * graph2Width;
    float pY = graph2Y - ((Float)yData.get(j) / dataMax) * graph2Height;
    curveVertex(pX,pY);
  }

  endShape();
  
  stroke(0);
  ellipse((graph2X + ((Float)xData.get(xData.size()-1) / dataMax) * graph2Width),(graph2Y - ((Float)yData.get(yData.size()-1) / dataMax) * graph2Height),10,10);
  
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
  int windowSize = 200;

  if(firstContact == true) //has first contact occured
  {
    //Calculate and draw x axis average
    for(int i=0;i<averageDistance;i++)
    {
      averageSum += (Float)xData.get(xData.size()-1-i);
    }
    
    averageX = averageSum / (float)averageDistance;
    averageXData.remove(0);
    averageXData.add(averageX);
    
    //Calculate and draw y axis average
    averageSum = 0;
    
    for(int i=0;i<averageDistance;i++)
    {
      averageSum += (Float)yData.get(yData.size()-1-i);
    }
    
    averageY = averageSum / (float)averageDistance;
    averageYData.remove(0);
    averageYData.add(averageX);
    
/*
    //Calculate the current frequency X
    float lastDataX = (Float)xData.get(xData.size()-1);
    int lastRealChangePoint = 1;
    int lastRealChangeState = 0;
    int changePoint = 0;
    int changeState = 0;

    for(int i = 1;i<windowSize;i++)
    {
      float diff = (Float)xData.get(xData.size() - 1 - i) - lastDataX; //the difference between this point and the last

      if(diff < 0)
      {
        if(lastChangeState > 0)
        {
          changePoint = i;
        }
        else
        {

        }
      }
      else
      {
        if(lastChangeState < 0)
        {

        }
        else
        {

        }
      }
    }*/
    /*
     if(abs(lastDataX - (Float)xData.get(xData.size()-1)) > noiseReducer)
    {
      if((Float)xData.get(xData.size()-1)-averageX <= 0)
      {
        currentSettingX = -1;
      }
      else 
      {
        currentSettingX = 1;
      }
    }
    
    if(abs(lastDataY - (Float)yData.get(yData.size()-1)) > noiseReducer)
    {
      if((Float)yData.get(yData.size()-1)-averageY <= 0)
      {
        currentSettingY = -1;
      }
      else 
      {
        currentSettingY = 1;
      }
    }
    
    if(currentSettingX != lastSettingX)
    {
      lastPeriodX = millis() - timeFromSwitchX;
      timeFromSwitchX = millis();
      lastSettingX = currentSettingY;
      
      hzX = 1000 / lastPeriodX;
    }
    
    if(currentSettingY != lastSettingY)
    {
      lastPeriodY = millis() - timeFromSwitchY;
      timeFromSwitchY = millis();
      lastSettingY = currentSettingY;
      
      hzY = 1000 / lastPeriodY;
    }
    */
  }
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

void stop()
{

}
