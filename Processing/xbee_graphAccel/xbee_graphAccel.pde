/*
*/

import processing.serial.*;
import processing.net.*;

int screenWidth = 600;
int screenHeight = 600;

int boolToInt( boolean val ) { if(val) return 1; else return 0; }

void drawHorizLine( int y )
{
	beginShape();
	curveVertex(0,y);
	curveVertex(0,y);
	curveVertex(screenWidth,y);
	curveVertex(screenWidth,y);
	endShape();
}

//----------------------------------------
//  The port assigned to a player
//----------------------------------------
class PlayerSerial extends Serial
{
	int playerNumber;

	PlayerSerial( PApplet applet, String name, int baud, int _playerNumber )
	{
		super( applet, name, baud );
		playerNumber = _playerNumber;
    this.write('A');
	}
}

//Server for talking with Flash
DataServer server;

//----------------------------------------
//  FSM for jump detection
//----------------------------------------
class JumpDetector
{
	int dipThreshold = 2800;
	int minDipMs = 200;	// Ignore input for a bit after events to account for oscillations
	int maxInAirMs = 1000;	// no one can jump for more than 2s...

	String state = "onFloor";
	int msSinceDip = 0;
	int inAirMs = 0;
	int inAirLowPoint = 0;

	boolean isInAir() { return state == "inJumpDip" || state == "inAir"; }

	//----------------------------------------
	//  dt - ms since last sample. Should be reported directly from Arduino board.
	//----------------------------------------
	String processSample( int x, int y, int dt )
	{
		if( state == "onFloor" ) {
			if( x < dipThreshold ) {
				state = "inJumpDip";
				msSinceDip = 0;
				inAirMs = 0;
				inAirLowPoint = x;
				return "jump";
			}
		}
		else if( state == "inJumpDip" ) {
			inAirMs += dt;
			msSinceDip += dt;
			if( msSinceDip > minDipMs ) {
				if( x > dipThreshold ) {
					state = "inAir";
				}
			}
			else
				inAirLowPoint = min(x, inAirLowPoint);
		}
		else if( state == "inAir" ) {
			inAirMs += dt;

			if( x < dipThreshold ) {
				state = "inLandDip";
				msSinceDip = 0;
				return "land";
			}
			else if( inAirMs > maxInAirMs )
			{
				state = "onFloor";
				return "land";
			}
		}
		else if( state == "inLandDip" ) {
			msSinceDip += dt;
			if( msSinceDip > minDipMs ) {
				if( x < dipThreshold ) {
					state = "onFloor";
				}
			}
		}
		return "none";
	}
}

//----------------------------------------
//  State for one player
//----------------------------------------
class PlayerState
{
	int bytesPerSample = 12;	// This must match the Arduino code
	byte[] serialInArray = new byte[bytesPerSample];    // Where we'll put what we receive
	int serialCount = 0;                 // A count of how many bytes we receive
	int playerNumber = 0;
  boolean isReceivingSample = false;

	boolean firstContact = false;        // Whether we've heard from the microcontroller
	JumpDetector jumpDet = new JumpDetector();

	String connectionStatus = "Not Connected";
	int maxX = 0;
	int maxY = 0;
	int minX = 10000;
	int minY = 10000;
	int graphDensity = 500;
	ArrayList xData;
	ArrayList yData;
	ArrayList averageXData;
	ArrayList averageYData;
	ArrayList deltaTimeData;
	ArrayList periodXData;
	ArrayList periodYData;
	ArrayList inAirSignal;
	int currentSampleIdx = 0;
	PFont f;

	ArrayList rawXs;
	ArrayList rawYs;

	//Data for x,y combined graph
	int graph2X = 300;
	int graph2Y = 600;
	int graph2Height = 300;
	int graph2Width = 300;

	//Axis Bounds Data
	int dataMax = 8000;
	int dataMin = 0;

	//Analysis Data
	float averageX = 0.0;
	float averageY = 0.0;

	float hzX = 0.0;
	float hzY = 0.0;

	PlayerState( int _playerNumber ) {
		playerNumber = _playerNumber;
	}

	void setup()
	{
		f = loadFont("Verdana-14.vlw");

		xData = new ArrayList();
		yData = new ArrayList();
		averageXData = new ArrayList();
		averageYData = new ArrayList();
		deltaTimeData = new ArrayList();
		periodXData = new ArrayList();
		periodYData = new ArrayList();

		rawXs = new ArrayList();
		rawYs = new ArrayList();
		inAirSignal = new ArrayList();

		//fill arrayList with '5000's which is unity for the accellerometer 
		for(int counter=0;counter < graphDensity; counter++)
		{
			xData.add(5000.0);
			yData.add(5000.0);
			averageXData.add(5000.0);
			averageYData.add(5000.0);
			periodXData.add(0.0);
			periodYData.add(0.0);

			rawXs.add(5000);
			rawYs.add(5000);

			inAirSignal.add(0);
      deltaTimeData.add(10);
		}
	}

	void plotIntegers( int posX, int posY, int width, int height, ArrayList data, float pixelsPerUnit, int currentIndex, String label,
			boolean drawRect)
	{
		if( drawRect ) {
			// draw rectangle
			stroke(0,0,0,100);
			fill(200, 100, 0, 50);
			beginShape();
			rect( posX, posY, width, height );
			endShape();
		}

		// plot data
		stroke(255, 255, 255, 255);
		noFill();
		beginShape();
		for( int i = 0; i < data.size(); i++ )
		{ 
			int val = (Integer)data.get(i);
			float pX = posX + ((float)i/data.size())*width;
			float pY = (posY+height) - ((float)val * pixelsPerUnit);
			curveVertex(pX,pY);
			if( i == 0 || i == data.size()-1 )
				curveVertex(pX,pY);
		}
		endShape();

		// draw reference line
		stroke(255,255,0,255);
		int i = currentIndex;
		float pX = posX + ((float)i/data.size())*width;
		beginShape();
		curveVertex(pX,posY);
		curveVertex(pX,posY);
		curveVertex(pX,posY+height);
		curveVertex(pX,posY+height);
		endShape();

		// label
		textFont(f);
		fill(255);
		text(label, posX+5, posY+height/2);

		// plot mouse stuff
		if( mouseY > posY && mouseY < (posY+height) )
		{
			textFont(f);
			fill(255);
			float yVal = (posY+height-mouseY) / pixelsPerUnit;
			text( "val = "+yVal, mouseX, mouseY );
			stroke(0,255,0,255);
			drawHorizLine( mouseY );
		}
	}


	void draw()
	{
		background(127);

		/***********
			Text display
		 ***********/
		fill(255);
		text(connectionStatus, 20, 40);
		text("\nMaxX: " + maxX + "\nMinX: " + minX + "\n\nMaxY: " + maxY + "\nMinY: " + minY + "\nPeriodX: " + hzX + "\nPeriodY: " + hzY + "\n\nMillis: " + millis(), 20, 100);

		//----------------------------------------
		//  The tracer plot
		//----------------------------------------
		stroke(0, 100);
		noFill();
		beginShape();
		for(int j=0;j<yData.size()-1;j++)
		{
			float pX = graph2X + ((Float)xData.get(j) / dataMax) * graph2Width;
			float pY = graph2Y - ((Float)yData.get(j) / dataMax) * graph2Height;
			curveVertex(pX,pY);
		}
		endShape();

		stroke(255);
		noFill();
		graph2X = screenWidth/4;
		graph2Y = screenHeight/2;
		ellipse((graph2X + ((Float)xData.get(currentSampleIdx) / dataMax) * graph2Width),(graph2Y - ((Float)yData.get(currentSampleIdx) / dataMax) * graph2Height),10,10);

		//----------------------------------------
		//  
		//----------------------------------------
		if( (Integer)inAirSignal.get(currentSampleIdx) == 1 ) {
			stroke( 255, 0, 0, 255 );
			fill(255);
			ellipse( 100, 300,
					20, 20 );
		}

		//----------------------------------------
		//  Graph in air signal
		//----------------------------------------
		int graphX = 0;
		int graphWidth = 600;
		int graphHeight = 50;

		plotIntegers(
				graphX, 400, graphWidth, graphHeight,
				inAirSignal, graphHeight/1.5, currentSampleIdx, "In Air?",
				true);

		//----------------------------------------
		//  Time deltas
		//----------------------------------------
		int graphY = 550;
		float pixelsPerMs = graphHeight / 50.0;

		String label = "";
		if( deltaTimeData.size() > 0 )
			label = "delta ms = "+(Integer)deltaTimeData.get(currentSampleIdx);

		stroke(255,0,0,255); //x axis should be white
		noFill(); //don't fill the graph curves
		plotIntegers(
				graphX, graphY, graphWidth, graphHeight,
				deltaTimeData, pixelsPerMs, currentSampleIdx, label,
				true);

		// draw green reference line
		stroke(0,255,0,255); //x axis should be white
		beginShape();
		float refMs = 33.0;
		float y = (graphY+graphHeight)-pixelsPerMs*refMs;
		curveVertex( graphX, y);
		curveVertex( graphX, y);
		curveVertex( graphX+graphWidth, y);
		curveVertex( graphX+graphWidth, y);
		endShape();

		//----------------------------------------
		//  raw X/Ys
		//----------------------------------------
		graphX = 0;
		graphY = 450;
		float maxAccelValue = 10000.0;
		plotIntegers(
				graphX, graphY, graphWidth, graphHeight,
				rawXs, (float)graphHeight/maxAccelValue, currentSampleIdx, "X",
				true);
		graphY = 500;
		plotIntegers(
				graphX, graphY, graphWidth, graphHeight,
				rawYs, (float)graphHeight/maxAccelValue, currentSampleIdx, "Y",
				true);
	}

	private void sendEvent( String event )
	{
		// TODO send even to flash here
		server.update( playerNumber, jumpDet.isInAir() );
	}

	void serialEvent( Serial myPort )
	{
    assert( myPort != null );

		//data for smoothing
		float weightedAverageX = 0.0;
		float weightedAverageY = 0.0;
		float sumCombos = 0.0;
		float sumWeights = 0.0;

		int weightWidth = 5; //number of spaces to go in each direction 
		float weightFactor = 0.4;

		// read a byte from the serial port:
		byte inByte = (byte)myPort.read();

    if( verbose )
      println("serial read "+(char)inByte);

    if( !isReceivingSample )
    {
      if( (char)inByte == 's')
        isReceivingSample = true;
      // always send something to indicate we're ready to read more data
			myPort.write('A');
    }
    else
    {
			serialInArray[serialCount] = inByte;
			//println(serialCount + ": " + inByte);
			serialCount++;

      // If we just got our last sample, process it
			if (serialCount >= 12)
			{
				serialCount = 0;
        isReceivingSample = false;

				String s_X = "";
				s_X += (char)serialInArray[0];
				s_X += (char)serialInArray[1];
				s_X += (char)serialInArray[2];
				s_X += (char)serialInArray[3];

				String s_Y = "";
				s_Y += (char)serialInArray[4];
				s_Y += (char)serialInArray[5];
				s_Y += (char)serialInArray[6];
				s_Y += (char)serialInArray[7];

				String deltaMsStr = "";
				deltaMsStr += (char)serialInArray[8];
				deltaMsStr += (char)serialInArray[9];
				deltaMsStr += (char)serialInArray[10];
				deltaMsStr += (char)serialInArray[11];

				int deltaMs = int(deltaMsStr);

				int _X = int(s_X);
				int _Y = int(s_Y);

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

				currentSampleIdx++;
				currentSampleIdx = currentSampleIdx % xData.size();

				xData.set(currentSampleIdx, weightedAverageX);
				yData.set(currentSampleIdx, weightedAverageY);
				averageXData.set(currentSampleIdx, averageX);
				averageYData.set(currentSampleIdx, averageY);
				deltaTimeData.set(currentSampleIdx, deltaMs); 
				periodXData.set(currentSampleIdx, hzX);
				periodYData.set(currentSampleIdx, hzY);

				rawXs.set(currentSampleIdx, _X);
				rawYs.set(currentSampleIdx, _Y);

				// send to detector
				String event = jumpDet.processSample( _X, _Y, deltaMs );
				if( event != "none" )
					sendEvent(event);

				inAirSignal.set( currentSampleIdx, boolToInt(jumpDet.isInAir()) );

				if(_X > maxX)
					maxX = _X;

				if(_Y > maxY)
					maxY = _Y;

				if(_X < minX)
					minX = _X;

				if(_Y < minY)
					minY = _Y;
			}
		}
	}
}

final int NumPlayers = 4;
PlayerSerial playerSerials[] = new PlayerSerial[ NumPlayers ];
PlayerState playerStates[] = new PlayerState[ NumPlayers ];

void setup()
{
	size(screenWidth, screenHeight);  // Stage size

  // Create states BEFORE hooking up serial ports..
	for( int playerNum = 0; playerNum < NumPlayers; playerNum++ )
	{
		playerStates[playerNum] = new PlayerState(playerNum);
		playerStates[playerNum].setup();
	}

	// Print a list of the serial ports, for debugging purposes:
	println( Serial.list() );

	playerSerials[0] = new PlayerSerial( this, Serial.list()[0], 9600, 0 );
	playerSerials[1] = new PlayerSerial( this, Serial.list()[2], 9600, 1 );
	//playerSerials[2] = new PlayerSerial( this, Serial.list()[2], 9600, 2 );
	//playerSerials[3] = new PlayerSerial( this, Serial.list()[3], 9600, 3 );

	//Setup the socket server
	server = new DataServer(this);
}

int activePlayer = 0;
boolean verbose = false;
boolean pauseSerialInput = false;

void draw()
{
	playerStates[ activePlayer ].draw();
}

void serialEvent(Serial myPort)
{
  try
  {
    if( !pauseSerialInput )
    {
      assert( myPort != null ) :"null port";
      PlayerSerial playerPort = (PlayerSerial)myPort;
      assert( playerPort != null ):"null playerport";
      assert(playerPort.playerNumber < playerStates.length):"bad player number "+playerPort.playerNumber;
      assert(playerStates[playerPort.playerNumber] != null):"player state not inited "+playerPort.playerNumber;
      playerStates[ playerPort.playerNumber ].serialEvent( myPort );
    }
  }
  catch( Exception e)
  {
    new Exception().printStackTrace();
  }
}

void keyPressed()
{
	if( key != CODED )
	{
		if( key == '1' )
			activePlayer = 0;
		else if( key == '2' )
			activePlayer = 1;
		else if( key == '3' )
			activePlayer = 2;
		else if( key == '4' )
			activePlayer = 3;
    else if( key == 'v' )
      verbose = !verbose;
    else if( key == 'p' ) {
      println("TOGGLE PAUSING");
      pauseSerialInput = !pauseSerialInput;
    }
	}
}

void stop()
{
}
