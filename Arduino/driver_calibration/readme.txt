- Code for calibrating the max current of the driver. Holds the step pin high such that the board uses constant current, to make calibration easier. 
- Adjust the potentiometer st. the current (Ampere) does not exeed 350mA for NEMA 17 in full step mode.
- The more resistance of the motor rotating axis, the more current used.

- Made for the NodeMCU, with StepPin -> D3, and DirPin -> D4