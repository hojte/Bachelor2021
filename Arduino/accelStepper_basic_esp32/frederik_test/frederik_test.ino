// Include the AccelStepper Library
#include <AccelStepper.h>

// Define pin connections
const int dirPin =32;
const int stepPin = 33;
const int qStep = 18; //Set high for quarterStep
const int eightStep = 19; //Set qStep and eightStep to HIGH.

// Define motor interface type
#define motorInterfaceType 1

// Creates an instance
AccelStepper myStepper(motorInterfaceType, stepPin, dirPin);


void setup() {
   myStepper.setMaxSpeed(2200);
    //myStepper.setAcceleration(500.0);
    myStepper.setSpeed(2000);
}

void loop() {
    myStepper.runSpeed();
}
