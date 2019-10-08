// Runs experiments when rocket starts to fall back.
WAIT UNTIL SHIP:UNPACKED.
WAIT 8.
STAGE.
// Second stage
WAIT UNTIL SHIP:AVAILABLETHRUST < 1.
WAIT 4.
STAGE.
// Fallback
WAIT UNTIL SHIP:VERTICALSPEED < 0.
runExperiments().
WAIT UNTIL realAlt() < 500.
STAGE.

declare function runExperiments {
	PRINT "Running Experiments".
	SET allScience TO SHIP:PARTSTAGGED("science").
	FOR experiment IN allScience {
		SET m to experiment:GETMODULE("ModuleScienceExperiment").
		m:DEPLOY.
		WAIT UNTIL m:HASDATA.
	}
	PRINT "Done Running Experiments".
}

declare function realAlt {
	IF SHIP:GEOPOSITION:TERRAINHEIGHT > 0 { 
		// When have "radar alt" or when we are above hard surface
		RETURN SHIP:ALTITUDE - SHIP:GEOPOSITION:TERRAINHEIGHT.
	} ELSE {
		// When not, so we are above sea
		RETURN SHIP:ALTITUDE.
	}
}
