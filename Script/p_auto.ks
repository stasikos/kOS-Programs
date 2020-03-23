WAIT UNTIL SHIP:UNPACKED.

SET maxPitch TO 15.
SET maxRoll TO 45.

SET stop TO FALSE.
SET savedState TO FALSE.

SET savedAlt TO 0.
SET savedSpeed TO 0.
SET savedBearing TO 0.

SET EDIT_ALT TO 0.
SET EDIT_BEARING TO 1.

SET editor TO FALSE.
SET editorValue TO 0.
SET editorIncrement TO 1.
SET editorSelector TO 0. // 0 - Altitude; 1 - Bearing.

SET altPID TO PIDLOOP(2, 0.01, 0.5).
SET altPID:MAXOUTPUT TO maxPitch.
SET altPID:MINOUTPUT TO -maxPitch.

SET pitchPID TO PIDLOOP(0.07, 0.02, 0.04).
SET pitchPID:MAXOUTPUT TO 1.
SET pitchPID:MINOUTPUT TO -1.

//SET dirPID TO PIDLOOP(0.6, 0.3, 0.075).
SET dirPID TO PIDLOOP(2.4, 0.3, 1.2).
SET dirPID:SETPOINT TO 0.
SET dirPID:MAXOUTPUT TO maxRoll.
SET dirPID:MINOUTPUT TO -maxRoll.

SET rollPID TO PIDLOOP(0.035, 0.05, 0.02).
SET rollPID:MAXOUTPUT TO 1.
SET rollPID:MINOUTPUT TO -1.

UNTIL stop {
	CLEARSCREEN.

	SET myPitch TO 90 - VANG(SHIP:UP:VECTOR, SHIP:FACING:FOREVECTOR).

	SET myBearing TO SHIP:BEARING.
	if (myBearing > 0) {
		SET myBearing TO 360 - myBearing.
	} ELSE {
		SET myBearing TO -myBearing.
	}
	
	SET myRoll TO 90 - VANG(SHIP:UP:VECTOR, SHIP:FACING:STARVECTOR).

	IF (RCS) {
		IF (NOT savedState) {
			SET savedAlt TO realAlt().
			SET savedSpeed TO SHIP:AIRSPEED.
			SET savedBearing TO myBearing.
			SET savedState TO TRUE.
			SAS OFF.
		}
		PRINT "Autopilot is Active".

		valueEditor().

		SET altPID:SETPOINT TO savedAlt.
		SET altSignal TO altPID:UPDATE(TIME:SECONDS, realAlt).
		SET pitchPID:SETPOINT TO altSignal.
		SET pitchSignal TO pitchPID:UPDATE(TIME:SECONDS, myPitch).
		SET SHIP:CONTROL:PITCH TO pitchSignal.

		SET bearingError TO myBearing - savedBearing.
		IF (bearingError > 180) {
			SET bearingError TO bearingError - 360.
		}

		IF (bearingError < -180) {
			SET bearingError TO 360 + bearingError.
		}

		SET rollAngle TO dirPID:UPDATE(TIME:SECONDS, -bearingError).
		SET rollPID:SETPOINT TO rollAngle.
		SET rollSignal TO rollPID:UPDATE(TIME:SECONDS, myRoll).

		PRINT "Saved Alt: " + savedAlt.
		PRINT "Altitude Signal: " + altSignal.
		PRINT "Saved bearing: " + savedBearing.
		PRINT "Current bearing: " + myBearing.
		PRINT "Bearing Error: " + bearingError.
		PRINT "Roll Angle: " + rollAngle.

		SET SHIP:CONTROL:ROLL TO -rollSignal.
		
	} ELSE {
		SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
		SET savedState TO FALSE.
		PRINT "Autopilot is Not Active".
		SAS ON.
	}
	
	WAIT 0.001.
}

DECLARE FUNCTION realAlt {
	return SHIP:ALTITUDE.
}

DECLARE FUNCTION valueEditor {

	// w - increment value; s - decrement value
	// a - multiplier increment ; d - multiplier decrement
	// Also: select mode.
	// q - exit; e - accept (also edit).

	SET mode TO "unknown".

	IF (editorSelector = EDIT_ALT) {
		SET mode TO "altitude".
	} ELSE IF (editorSelector = EDIT_BEARING) {
		SET mode TO "bearing".
	}

	PRINT "Edit: " + mode.

	IF (TERMINAL:INPUT:HASCHAR()) {
		SET ch TO TERMINAL:INPUT:GETCHAR().
		IF (ch = "e") {
			IF (editor) {
				IF (editorSelector = EDIT_ALT) {
					SET savedAlt TO editorValue.
				} ELSE IF (editorSelector = EDIT_BEARING) {
					SET savedBearing TO editorValue.
				}
				SET editor TO FALSE.
			} ELSE {
				IF (editorSelector = EDIT_ALT) {
					SET editorValue TO savedAlt.
				} ELSE IF (editorSelector = EDIT_BEARING) {
					SET editorValue TO savedBearing.
				}
				SET editor TO TRUE.
			}
		} ELSE IF (ch = "a") {
			IF (editor) {
				SET editorIncrement TO editorIncrement / 10.
			} ELSE {
				SET editorSelector TO editorSelector + 1.
			}
		} ELSE IF (ch = "d") {
			IF (editor) {
				SET editorIncrement TO editorIncrement * 10.
			} ELSE {
				SET editorSelector TO editorSelector + 1.
			}
		} ELSE IF (ch = "w" AND editor) {
			SET editorValue TO editorValue + editorIncrement.
		} ELSE IF (ch = "s" AND editor) {
			SET editorValue TO editorValue - editorIncrement.
		} ELSE IF (ch = "q") {
			SET editor TO FALSE.
		}
	
	}
	
	IF (editorSelector > EDIT_BEARING) {
		SET editorSelector TO EDIT_ALT.
	}
	IF (editorSelector < 0) {
		SET editorSelector TO EDIT_BEARING.
	}

	IF (editor) {
		PRINT "Edit: " + editorValue + " increment " + editorIncrement.	
	}
}
