// Include the AccelStepper Library
#include <AccelStepper.h>

// Define pin connections
const int dirPin =32;
const int stepPin = 33;
const int MS1_1 = 27; 
const int MS2_1 = 26; 
const int MS3_1 = 25;

// Define motor interface type
#define motorInterfaceType 1

// Creates an instance
AccelStepper myStepper(motorInterfaceType, stepPin, dirPin);


void setup() {
    pinMode(MS3_1,OUTPUT);
  pinMode(MS2_1,OUTPUT);
  pinMode(MS1_1,OUTPUT);
  digitalWrite(MS3_1,HIGH);
  digitalWrite(MS2_1,HIGH);
  digitalWrite(MS1_1,HIGH);
  
myStepper.setMaxSpeed(10000.0);
myStepper.setAcceleration(5000.0);
myStepper.moveTo(3200);
}

void loop() {
if (myStepper.distanceToGo() == 0)
  myStepper.moveTo(-myStepper.currentPosition()+3200);
myStepper.run();
}
