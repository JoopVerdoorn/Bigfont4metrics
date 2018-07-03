class Bigfont4metricsApp extends Toybox.Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    //! Return the initial view of your application here
    function getInitialView() {
        return [ new DatarunView() ];
    }
}


class DatarunView extends Toybox.WatchUi.DataField {
	using Toybox.WatchUi as Ui;


	
    hidden var uHrZones                     = [ 93, 111, 130, 148, 167, 185 ];
    hidden var unitP                        = 1000.0;
    hidden var unitD                        = 1000.0;
    var Pace1 								= 0;
    var Pace2 								= 0;
    var Pace3 								= 0;
	var Pace4 								= 0;
    var Pace5 								= 0;


    hidden var uRoundedPace                 = true;
    //! true     => Show current pace as Rounded Pace (i.e. rounded to 5 second intervals)
    //! false    => Show current pace without rounding (i.e. 1-second resolution)

    //! Which average pace metric should be used as the reference for deviation of the current pace? (see above)
    hidden var uTargetPaceMetric            = 0;

    hidden var mTimerRunning                = false;
    hidden var mStartStopPushed             = 0;    //! Timer value when the start/stop button was last pushed

    hidden var mStoppedTime                 = 0;
    hidden var mStoppedDistance             = 0;
    hidden var mPrevElapsedDistance         = 0;

    hidden var mLaps                        = 1;
    hidden var mLastLapDistMarker           = 0;
    hidden var mLastLapTimeMarker           = 0;
    hidden var mLastLapStoppedTimeMarker    = 0;
    hidden var mLastLapStoppedDistMarker    = 0;

    hidden var mLastLapTimerTime            = 0;
    hidden var mLastLapElapsedDistance      = 0;
    hidden var mLastLapMovingSpeed          = 0;

    function initialize() {
        DataField.initialize();

        uHrZones = UserProfile.getHeartRateZones(UserProfile.getCurrentSport());


         var mApp = Application.getApp();
         uTargetPaceMetric   = mApp.getProperty("pTargetPace");
         uRoundedPace        = mApp.getProperty("pRoundedPace");

        if (System.getDeviceSettings().paceUnits == System.UNIT_STATUTE) {
            unitP = 1609.344;
        }

        if (System.getDeviceSettings().distanceUnits == System.UNIT_STATUTE) {
            unitD = 1609.344;
        }

    }


    //! Calculations we need to do every second even when the data field is not visible
    function compute(info) {
        if (mTimerRunning) {  //! We only do some calculations if the timer is running

            var mElapsedDistance    = (info.elapsedDistance != null) ? info.elapsedDistance : 0.0;
            var mDistanceIncrement  = mElapsedDistance - mPrevElapsedDistance;
            var mLapElapsedDistance = mElapsedDistance - mLastLapDistMarker;

            
        }


    }


    //! Timer transitions from stopped to running state
    function onTimerStart() {
        startStopPushed();
        mTimerRunning = true;
    }


    //! Timer transitions from running to stopped state
    function onTimerStop() {
        startStopPushed();
        mTimerRunning = false;
    }


    //! Timer transitions from paused to running state (i.e. resume from Auto Pause is triggered)
    function onTimerResume() {
        mTimerRunning = true;
    }


    //! Timer transitions from running to paused state (i.e. Auto Pause is triggered)
    function onTimerPause() {
        mTimerRunning = false;
    }


    //! Start/stop button was pushed - emulated via timer start/stop
    //! If the button was double pressed quickly, toggle
    //! the force backlight feature (see in compute(), above).
    function startStopPushed() {
        var info = Activity.getActivityInfo();
        mStartStopPushed = info.elapsedTime;
      }


    //! Current activity is ended
    function onTimerReset() {

        mStartStopPushed            = 0;
    }


    //! Do necessary calculations and draw fields.
    //! This will be called once a second when the data field is visible.
    function onUpdate(dc) {
        var info = Activity.getActivityInfo();
        var mColour;
	   var Garminfont2 = Ui.loadResource(Rez.Fonts.Garmin2);
	   var Garminfont3 = Ui.loadResource(Rez.Fonts.Garmin3);

        //! Draw colour indicators
        //!
        //! HR zone
        mColour = Graphics.COLOR_LT_GRAY;
        dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(110, 0, 107, 58);
        dc.fillRectangle(0, 0, 108, 58);

        var mCurrentHeartRate = 0;
        if (info.currentHeartRate != null) {
            mCurrentHeartRate = info.currentHeartRate;
            if (uHrZones != null) {
                if (mCurrentHeartRate >= uHrZones[4]) {
                    mColour = Graphics.COLOR_RED;        //! Maximum (Z5)
                } else if (mCurrentHeartRate >= uHrZones[3]) {
                    mColour = Graphics.COLOR_ORANGE;    //! Threshold (Z4)
                } else if (mCurrentHeartRate >= uHrZones[2]) {
                    mColour = Graphics.COLOR_GREEN;        //! Aerobic (Z3)
                } else if (mCurrentHeartRate >= uHrZones[1]) {
                    mColour = Graphics.COLOR_BLUE;        //! Easy (Z2)
                } //! Else Warm-up (Z1) and no zone both inherit default light grey here
            }
        }
        dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(110, 160, 107, 58);

        //! Current pace vs target pace colour indicator
        mColour = Graphics.COLOR_LT_GRAY;
        if (info.currentSpeed != null && info.currentSpeed > 2.0) {    //! Only use the pace colour indicator when running at least 2.0 m/s (= 8:20 min/km, 13:25 min/mi)
            var mTargetSpeed = 0.0;
            if (uTargetPaceMetric == 0 && info.averageSpeed != null) {
                mTargetSpeed = info.averageSpeed;
            } 
            if (mTargetSpeed > 0) {
                var paceDeviation = (info.currentSpeed / mTargetSpeed);
                if (paceDeviation < 0.95) {    //! More than 5% slower
                    mColour = Graphics.COLOR_RED;
                } else if (paceDeviation <= 1.05) {    //! Within +/-5% of target pace
                    mColour = Graphics.COLOR_GREEN;
                } else {  //! More than 5% faster
                    mColour = Graphics.COLOR_BLUE;
                }
            }
        }
        dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(0, 160, 108, 58);

		//! Draw separator lines
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawLine(0,   109,  218, 109);
        dc.drawLine(109, 0,  109, 218);
        
        //! Set text colour
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);

        //!
        //! Draw field values
        //! =================
        //!

        mColour = Graphics.COLOR_BLACK;
		dc.setColor(mColour, Graphics.COLOR_TRANSPARENT);

        var xul=56;
        var yul=79;
        var xtul=66;
        var ytul=40;

        var xur=162;
        var yur=79;
        var xtur=115;
        var ytur=40;

        var xbl=56;
        var ybl=132;
        var xtbl=66;
        var ytbl=172;

        var xbr=162;
        var ybr=132;
        var xtbr=115;
        var ytbr=172;

				
        //! Top row left: time
        var mTimerTime      = 0;
        if (info.timerTime != null) {
            mTimerTime = info.timerTime / 1000;
        }


        var fTimerSecs = (mTimerTime % 60).format("%02d");
        var fTimer = (mTimerTime / 60).format("%d") + ":" + fTimerSecs;  //! Format time as m:ss
        var x = xul;
        if (mTimerTime > 3599) {
            //! (Re-)format time as h:mm(ss) if more than an hour
            fTimer = (mTimerTime / 3600).format("%d") + ":" + (mTimerTime / 60 % 60).format("%02d");
            x = xul-10;
            dc.drawText(82, 74, Graphics.FONT_NUMBER_MILD, fTimerSecs, Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(x, yul, Garminfont2, fTimer, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtul, ytul, Garminfont3,  "Timer", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Top row right: distance
        var mDistance = (info.elapsedDistance != null) ? info.elapsedDistance / unitD : 0;
        var fString = "%.2f";
         if (mDistance > 100) {
             fString = "%.1f";
         }
        dc.drawText(xur, yur, Garminfont2, mDistance.format(fString), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtur, ytur, Garminfont3,  "Distanc.", Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Bottom left: current pace
        var Averagespeedinmpersec 			= 0;
        var fCurrentPace 					= 0;
        if (info.currentSpeed != null and info.currentSpeed > 0) {
            
            	//! Calculate average pace
				if (info.currentSpeed != null) {
        		Pace5 								= Pace4;
        		Pace4 								= Pace3;
        		Pace3 								= Pace2;
        		Pace2 								= Pace1;
        		Pace1								= info.currentSpeed; 
        		} else {
					Pace5 								= Pace4;
    	    		Pace4 								= Pace3;
        			Pace3 								= Pace2;
        			Pace2 								= Pace1;
        			Pace1								= 0;
				}
				Averagespeedinmpersec= (Pace1+Pace2+Pace3+Pace4+Pace5)/5;
				if (uRoundedPace) {
                	fCurrentPace 					= unitP/(Math.round( (unitP/Averagespeedinmpersec) / 5 ) * 5);
                } else {
                	fCurrentPace 					= Averagespeedinmpersec;
                }
			
            dc.drawText(xbl, ybl, Garminfont2, fmtPace(fCurrentPace), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        }
        dc.drawText(xtbl, ytbl, Garminfont3,  "Pace", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);

        //! Bottom right: heart rate mCurrentHeartRate
        dc.drawText(xbr, ybr, Garminfont2, mCurrentHeartRate, Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(xtbr, ytbr, Garminfont3, "Heartr.", Graphics.TEXT_JUSTIFY_LEFT|Graphics.TEXT_JUSTIFY_VCENTER);

	}


    function fmtPace(secs) {
        var s = (unitP/secs).toLong();
        return (s / 60).format("%0d") + ":" + (s % 60).format("%02d");
    }


}
