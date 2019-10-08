WAIT UNTIL SHIP:UNPACKED.

// Configuration
SET countDownTime TO 10.
SET vAscentEndVelocity TO 80.
SET turnExponent TO 0.45.
SET targetAP TO 100000.
SET targetPE TO 100000.

SET waitTime TO 0.001.
// System variables

SET MODE_PRELAUNCH TO 0.
SET MODE_LAUNCH TO 1.
SET MODE_VERTICAL_ASCENT TO 2.
SET MODE_GRAVITY_TURN TO 3.
SET MODE_TUNE_APOAPSIS TO 4.
SET MODE_CIRCULARIZE TO 5.
SET MODE_STOP TO -1.

SET controlPitch TO 0.
SET controlRoll TO 0.
SET controlDir TO 0.
SET controlThrottle TO 0.

SET mode TO MODE_PRELAUNCH.

SET startTime TO TIME:SECONDS.
SET startTurnAltitude TO 0.
SET fairingDeployed TO FALSE.

UNTIL mode = MODE_STOP {
	IF (mode = MODE_PRELAUNCH) {
		IF (TIME:SECONDS > countDownTime + startTime) {
			SET mode TO MODE_LAUNCH.
		} ELSE {
			PRINT "Countdown: " + ((countDownTime + startTime) - TIME:SECONDS).
		}
	} ELSE IF (mode = MODE_LAUNCH) {
		STAGE.
		SET mode TO MODE_VERTICAL_ASCENT.
	} ELSE IF (mode = MODE_VERTICAL_ASCENT) {
		SET controlRoll TO 0.
		SET controlDir TO 90.
		SET controlPitch TO 90.
		SET controlThrottle TO 1.

		IF (SHIP:VERTICALSPEED >= vAscentEndVelocity) {
		 	SET startTurnAltitude TO SHIP:ALTITUDE.
			SET mode TO MODE_GRAVITY_TURN.
		}
	} ELSE IF (mode = MODE_GRAVITY_TURN) {
		SET controlPitch TO 90 * (1-((SHIP:ALTITUDE - startTurnAltitude) / BODY:ATM:HEIGHT) ^ turnExponent).		
		IF (SHIP:APOAPSIS >= targetAP) {
			SET controlThrottle TO 0.
			SET mode TO MODE_TUNE_APOAPSIS.
		}
	} ELSE IF (mode = MODE_TUNE_APOAPSIS) {
		IF (SHIP:APOAPSIS < targetAP) {
			SET controlThrottle TO 0.5.
		} ELSE {
			SET controlThrottle TO 0.
		}
		IF (SHIP:ALTITUDE > BODY:ATM:HEIGHT) {
			SET mode TO MODE_CIRCULARIZE.
		}
	} ELSE IF (mode = MODE_CIRCULARIZE) {
		// Get real pitch/dir from SHIP:PROGRADE ;)
		SET controlPitch TO 90 - VANG(SHIP:PROGRADE:FOREVECTOR, SHIP:UP:VECTOR).
		SET controlDir TO VANG(SHIP:PROGRADE:FOREVECTOR, SHIP:NORTH:VECTOR).
		SET controlRoll TO 0.
		
		SET rAP TO targetAP + SHIP:BODY:RADIUS.
		SET rPE TO targetPE + SHIP:BODY:RADIUS.

		// Vis-Viva equatiion to get ship speed in current AP
		SET vOrbital TO SQRT(SHIP:BODY:MU * (2 / SHIP:BODY:RADIUS + SHIP:BODY:APOAPSIS) - 1 / SHIP:ORBIT:SEMIMAJORAXIS)).
		SET sMA TO (rAP + rPE) / 2.
		SET vOrbitalNeeded TO SQRT(SHIP:BODY:MU * (2/rAP - 1/sMA)).
		SET deltaV TO vOrbitalNeeded - vOrbital.
		
		SET engineISP TO getStageISP().
		
		if (engineISP > 0) {
			SET startAccel TO SHIP:MAXTHRUST / SHIP:MASS.
			SET startMass TO SHIP:MASS.
			SET massLoss TO SHIP:MASS - SHIP:MASS * CONSTANT:E^(-deltaV / (engineISP * g)).
			SET endAccel TO SHIP:MAXTHRUST / (SHIP:MASS - massLoss).
			SET avgAccel TO (startAccel + endAccel) / 2.
			SET burnTime TO deltaV / avgAccel.

			IF (ETA:APOAPSIS < (burnTime / 2)) {
				SET controlThrottle TO 1.
			} ELSE {
				SET controlThrottle TO 0.
			}	
		}
	}

	printState().
	checkStage().
	checkAtmosphere().
	setHeading().
	setThrottle().

	WAIT waitTime.
}

DECLARE FUNCTION printState {
	PRINT "Mode: " + mode.
	PRINT "AP: " + SHIP:ORBIT:APOAPSIS + " PE: " + SHIP:ORBIT:PERIAPSIS.
	PRINT "Pitch: " + controlPitch + " Dir: " + controlDir + " Roll: " + controlRoll.
	Print "Throttle: " + controlThrottle.
}

DECLARE FUNCTION checkStage {
	IF (mode > MODE_PRELAUNCH) {
		IF(SHIP:AVAILABLETHRUST < 0.1) {
			STAGE.
		}
	}
}

DECLARE FUNCTION checkAtmosphere {
	IF (SHIP:ALTITUDE > BODY:ATM:HEIGHT * 0.9 AND NOT fairingDeployed) {
		STAGE. // to deploy fairing.
		RCS ON.
		SET fairingDeployed TO TRUE.
	}
}

DECLARE FUNCTION setHeading {
	SET headingDir TO HEADING(controlDir, controlPitch).
	LOCK STEERING TO ANGLEAXIS(controlRoll, headingDir:FOREVECTOR) * headingDir.
}

DECLARE FUNCTION setThrottle {
	LOCK THROTTLE to controlThrottle.
}

DECLARE FUNCTION getStageISP {
	LIST ENGINES IN eList.
	SET isp TO 0.
	SET engines TO 0.
	FOR e IN eList {
		IF (e:IGNITION) {
			SET isp TO isp + e:ISP.
			SET engines TO engines + 1.
		}
	}
	
	// TODO: division by 0.
	RETURN isp / engines.
}
