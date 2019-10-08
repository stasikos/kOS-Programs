WAIT UNTIL SHIP:UNPACKED.

SET maxPitch TO 15.
SET maxRoll TO 45.

SET stop TO FALSE.
SET savedState TO FALSE.

SET savedAlt TO 0.
SET savedSpeed TO 0.
SET savedBearing TO 0.

SET altPID TO PIDLOOP(2, 0.01, 0.5).
SET altPID:MAXOUTPUT TO maxPitch.
SET altPID:MAXOUTPUT TO -maxPitch.

SET pitchPID TO PIDLOOP(0.07, 0.02, 0.04).
SET pitchPID:MAXOUTPUT TO 1.
SET pitchPID:MINOUTPUT TO -1.

SET dirPID TO PIDLOOP(0.6, 0.3, 0.075).
SET dirPID:MAXOUTPUT TO maxRoll.
SET dirPID:MAXOUTPUT TO -maxRoll.

UNTIL stop {
	CLEARSCREEN.

	SET myPitch TO 90 - VANG(SHIP:UP:VECTOR, SHIP:FACING:FOREVECTOR).

	SET myBearing TO SHIP:BEARING.
	if (myBearing > 0) {
		SET myBearing TO 360 - myBearing.
	} ELSE {
		SET myBearing TO -myBearing.
	}		

	IF (RCS) {
		IF (NOT savedState) {
			SET savedAlt TO realAlt().
			SET savedSpeed TO SHIP:AIRSPEED.
			SET savedBearing TO myBearing.
			SET savedState TO TRUE.
		}
		PRINT "Autopilot is Active".

		SET altPID:SETPOINT TO savedAlt.
		SET pitchPID:SETPOINT TO altPID:UPDATE(TIME:SECONDS, realAlt).
		SET pitchSignal TO pitchPID:UPDATE(TIME:SECONDS, myPitch).
		SET SHIP:CONTROL:PITCH TO pitchSignal.

		SET bearingError TO myBearing - savedBearing.
		IF (bearingError > 180) {
			SET bearingError TO bearingError - 360.
		}

		IF (bearingError < -180) {
			SET bearingError TO 360 + bearingError.
		}

		SET rollSignal TO dirPID:UPDATE(TIME:SECONDS, bearingError).
		SET SHIP:CONTROL:ROLL TO rollSignal.
		
	} ELSE {
		SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
		SET savedState TO FALSE.
		PRINT "Autopilot is Not Active".
	}
	
	WAIT 0.001.
}

DECLARE FUNCTION realAlt {
	return SHIP:ALTITUDE.
}