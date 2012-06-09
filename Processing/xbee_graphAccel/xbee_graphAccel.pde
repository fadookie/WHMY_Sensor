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


void setup() {
  size(600, 600);  // Stage size
  
  xData = new ArrayList();
  yData = new ArrayList();
  
  //fill arrayList with '5000's which is unity for the accellerometer
  for(int counter=0;counter < graphDensity; counter++)
  {
    xData.add(5000);
    yData.add(5000);
  }
  
  f = loadFont("Verdana-14.vlw");
  textFont(f);
  fill(0);

  // Print a list of the serial ports, for debugging purposes:
  println(Serial.list());
  
  String portName = Serial.list()[2];
  myPort = new Serial(this, portName, 9600);
}


void draw() {
  float weightedAverageX = 0.0;
  float weightedAverageY = 0.0;
  float sumCombos = 0.0;
  float sumWeights = 0.0;
  
  int weightWidth = 6; //number of spaces to go in each direction 
  float weightFactor = 0.99;
  
  
  background(127);
  
  /***********
  Text display
  ***********/
  fill(255);
  text(connectionStatus, 20, 40);
  text("x: " + _X + "\ny: " + _Y + "\n\nMaxX: " + maxX + "\nMinX: " + minX + "\n\nMaxY: " + maxY + "\nMinY: " + minY, 20, 100);
  
  /***********
  GRAPH 1
  ***********/
  //DRAW X AXIS
  stroke(255); //x axis should be white
  noFill(); //don't fill the graph curves
  beginShape();
  curveVertex(graphX, graphY - ((float)(Integer)xData.get(0) / dataMax) * graphHeight); //first point on the curve (duplicated in for loop)
  for(int i=0;i<xData.size();i++)
  {
    sumCombos = 0.0;
    sumWeights = 0.0;
    
    for(int k = 1; k <= weightWidth; k++)
    {
      if((i-k)>=0)
      {
        sumCombos += ((float)(Integer)xData.get(i-k) * pow(weightFactor, k));
        sumWeights += (pow(weightFactor, k));
      }
    }
    
    weightedAverageX = sumCombos/sumWeights;
    
    float pX = graphX + ((float)i / graphDensity) * graphWidth;
    float pY = graphY - (weightedAverageX / dataMax) * graphHeight;
    curveVertex(pX,pY);
  }
  curveVertex(graphX+graphHeight, graphY - ((float)(Integer)xData.get(xData.size()-1) / dataMax) * graphHeight); //last point on the curve (duplicated in for loop)
  endShape();
  
  //DRAW Y AXIS
  stroke(0);
  beginShape();
  curveVertex(graphX, graphY - ((float)(Integer)yData.get(0) / dataMax) * graphHeight);
  for(int j=0;j<yData.size();j++)
  {
    //smooth the data for
    sumCombos = 0.0;
    sumWeights = 0.0;
    
    for(int l = 1; l <= weightWidth; l++)
    {
      if((j-l)>=0)
      {
        sumCombos += ((float)(Integer)yData.get(j-l) * pow(weightFactor, l));
        sumWeights += (pow(weightFactor, l));
      }
    }
    
    weightedAverageY = sumCombos/sumWeights;
    
    float pX = graphX + ((float)j / graphDensity) * graphWidth;
    float pY = graphY - (weightedAverageY / dataMax) * graphHeight;
    curveVertex(pX,pY);
  }
  curveVertex(graphX+graphHeight, graphY - ((float)(Integer)yData.get(yData.size()-1) / dataMax) * graphHeight);
  endShape();
  
  /***********
  GRAPH 2
  ***********/
  stroke(0, 100);
  beginShape();
  curveVertex(graph2X + ((float)(Integer)xData.get(0) / dataMax) * graph2Height, graph2Y - ((float)(Integer)yData.get(0) / dataMax) * graph2Height);
  for(int j=0;j<yData.size();j++)
  {
    //smooth x axis
    sumCombos = 0.0;
    sumWeights = 0.0;
    
    for(int k = 1; k <= weightWidth; k++)
    {
      if((j-k)>=0)
      {
        sumCombos += ((float)(Integer)xData.get(j-k) * pow(weightFactor, k));
        sumWeights += (pow(weightFactor, k));
      }
    }
    
    weightedAverageX = sumCombos/sumWeights;
    
    //smooth y axis
    sumCombos = 0.0;
    sumWeights = 0.0;
    
    for(int l = 1; l <= weightWidth; l++)
    {
      if((j-l)>=0)
      {
        sumCombos += ((float)(Integer)yData.get(j-l) * pow(weightFactor, l));
        sumWeights += (pow(weightFactor, l));
      }
    }
    
    weightedAverageY = sumCombos/sumWeights;
 
    float pX = graph2X + (weightedAverageX / dataMax) * graph2Width;
    float pY = graph2Y - (weightedAverageY / dataMax) * graph2Height;
    curveVertex(pX,pY);
  }
  curveVertex(graph2X + ((float)(Integer)xData.get(xData.size()-1) / dataMax) * graph2Width, graph2Y - ((float)(Integer)yData.get(yData.size()-1) / dataMax) * graph2Height);
  endShape();
  
  stroke(0);
  ellipse((graph2X + ((float)(Integer)xData.get(xData.size()-1) / dataMax) * graph2Width),(graph2Y - ((float)(Integer)yData.get(yData.size()-1) / dataMax) * graph2Height),10,10);
  
}

void serialEvent(Serial myPort) {
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
      
      //add the new data, remove the old
      //should maintain the size of the list
      xData.add(_X);
      xData.remove(0);
      yData.add(_Y);
      yData.remove(0);
      
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
