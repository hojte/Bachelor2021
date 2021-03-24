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

// Creates an instance accelstepper
AccelStepper myStepper(motorInterfaceType, stepPin, dirPin);


void setup() {
    pinMode(MS3_1,OUTPUT);
  pinMode(MS2_1,OUTPUT);
  pinMode(MS1_1,OUTPUT);
  digitalWrite(MS3_1,HIGH);
  digitalWrite(MS2_1,HIGH);
  digitalWrite(MS1_1,HIGH);
  
myStepper.setMaxSpeed(20000.0);
myStepper.setSpeed(20000.0);
}

void loop() {
myStepper.runSpeed();
}
