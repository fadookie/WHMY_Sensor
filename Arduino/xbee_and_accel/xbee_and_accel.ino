// Requires remote Serial in loopback mode (DIN connected to DOUT)

#include <SoftwareSerial.h> 

#define Rx    6			    // DOUT to pin 6
#define Tx    7			    // DIN to pin 7
//SoftwareSerial Serial (Rx, Tx);

const int xIn = 2;              // X output
const int yIn = 3;              // Y output

unsigned long lastTimeMs = 0;

void setup() {
  Serial.begin(9600);               // Set to No line ending;
  //Serial.begin(9600);		    //   type a char, then hit enter
  establishContact();  // send a byte to establish contact until receiver responds
  lastTimeMs = millis();
}

void serialPrint4Digit(long x)
{
    if( x >= 10000 )
      x = 9999;
    String data = "";
    if( x < 1000 ) data += "0";
    if( x < 100 ) data += "0";
    if( x < 10 ) data += "0";
    data += x;
    Serial.print(data);
}

void loop() {
  // variables to read the pulse widths:
  int pulseX, pulseY;
  byte inByte;
 
  pulseX = pulseIn(xIn,HIGH);  // Read X pulse  
  pulseY = pulseIn(yIn,HIGH);  // Read Y pulse
  
  if(Serial.available() > 0)
  {
    // get incoming byte:
    inByte = Serial.read();
    
//    Serial.print( pulseX );
//    Serial.print( pulseY );

    Serial.print('s');  // indicate start of sample

    serialPrint4Digit(pulseX);
    serialPrint4Digit(pulseY);

    // Not sure why we can't use serialPrint4Digit here - meh!
    unsigned long nowMs = millis();
    unsigned long deltaMs = (nowMs-lastTimeMs) % 10000;
    String data = "";
    if( deltaMs < 1000 ) data += "0";
    if( deltaMs < 100 ) data += "0";
    if( deltaMs < 10 ) data += "0";
    data += deltaMs;
    Serial.print(data);
    lastTimeMs = nowMs;
    
  }
//  delay(10);
}

void establishContact() {
  while (Serial.available() <= 0) {
    Serial.print('A');   // send a capital A
    delay(500);
  }
}
