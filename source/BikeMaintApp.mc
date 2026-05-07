import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Application entry point.
// getInitialView() returns the data field view that the device displays during a ride.
class BikeMaintApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [ WatchUi.Views ] or [ WatchUi.Views, WatchUi.InputDelegates ] {
        return [ new BikeMaintView() ];
    }
}

// Module-level factory required by the Connect IQ runtime.
function getApp() as BikeMaintApp {
    return Application.getApp() as BikeMaintApp;
}
