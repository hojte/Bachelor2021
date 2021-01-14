// Include the AccelStepper Library
#include <AccelStepper.h>

// Define pin connections
const int dirPin = 4;
const int stepPin = 2;
const int qStep = 18; //Set high for quarterStep
const int eightStep = 19; //Set qStep and eightStep to HIGH.

// Define motor interface type
#define motorInterfaceType 1

// Creates an instance
AccelStepper myStepper(motorInterfaceType, stepPin, dirPin);

void setup() {
  // set the maximum speed, acceleration factor,
  // initial speed and the target position
  myStepper.setMaxSpeed(1000);
  myStepper.setAcceleration(100);
  myStepper.setSpeed(300);
  myStepper.moveTo(200);
  pinMode(qStep, OUTPUT);
  digitalWrite(qStep, HIGH);
  pinMode(eightStep, OUTPUT);
  digitalWrite(eightStep, HIGH);
}

void loop() {
  // Change direction once the motor reaches target position
  if (myStepper.distanceToGo() == 0) 
    myStepper.moveTo(-myStepper.currentPosition());

  // Move the motor one step
  myStepper.run();
}
