// Requires remote XBee in loopback mode (DIN connected to DOUT)

#include <SoftwareSerial.h> 

#define Rx    6			    // DOUT to pin 6
#define Tx    7			    // DIN to pin 7
SoftwareSerial Xbee (Rx, Tx);

const int xIn = 2;              // X output
const int yIn = 3;              // Y output

void setup() {
  Serial.begin(9600);               // Set to No line ending;
  Xbee.begin(9600);		    //   type a char, then hit enter
  establishContact();  // send a byte to establish contact until receiver responds
}

void loop() {
  // variables to read the pulse widths:
  int pulseX, pulseY;
  byte inByte;
 
  pulseX = pulseIn(xIn,HIGH);  // Read X pulse  
  pulseY = pulseIn(yIn,HIGH);  // Read Y pulse
  
  if(Xbee.available() > 0)
  {
    // get incoming byte:
    inByte = Xbee.read();
    
    Xbee.print(pulseX);
    Xbee.print(pulseY);
    
  }
  delay(50);
}

void establishContact() {
  while (Xbee.available() <= 0) {
    Xbee.print('A');   // send a capital A
    delay(500);
  }
}
