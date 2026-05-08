import Toybox.Activity;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Data field view shown during a ride.
// Displays km remaining to the next maintenance threshold.
// On activity save (onReset), updates cumulative km and triggers an alert if anything is overdue.
class BikeMaintView extends WatchUi.DataField {

    private var _activeBikeIndex as Number = 0;
    private var _label as String = "";
    private var _unit as String = "";

    function initialize() {
        DataField.initialize();
        _activeBikeIndex = _getActiveBikeIndex();
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Dynamic layout — nothing to do here.
    }

    // Called repeatedly during the activity with live sensor/activity data.
    function compute(info as Activity.Info) as Numeric or String or Null {
        _activeBikeIndex = _getActiveBikeIndex();

        var kmRemaining = MaintenanceManager.kmToNextMaintenance(_activeBikeIndex);
        if (kmRemaining == null) {
            _label = WatchUi.loadResource(Rez.Strings.LabelAllGood) as String;
            _unit  = "";
        } else if (kmRemaining <= 0.0f) {
            _label = "OVERDUE";
            _unit  = "";
        } else {
            _label = kmRemaining.format("%.0f");
            _unit  = "km";
        }

        return _label;
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        // Background
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Sub-label
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 4, Graphics.FONT_XTINY,
                    WatchUi.loadResource(Rez.Strings.LabelKmToMaint) as String,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Main value
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var numH = dc.getFontHeight(Graphics.FONT_NUMBER_MEDIUM);
        var midY = h / 2;
        if (_unit.length() > 0) {
            // Number in large numeric font, unit in small text font below
            dc.drawText(w / 2, midY - numH / 2, Graphics.FONT_NUMBER_MEDIUM,
                        _label, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, midY + numH / 2, Graphics.FONT_SMALL,
                        _unit, Graphics.TEXT_JUSTIFY_CENTER);
        } else {
            dc.drawText(w / 2, midY, Graphics.FONT_LARGE,
                        _label, Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    // Called when the user saves the activity.
    // This is the hook for updating maintenance state and showing an alert.
    function onReset() as Void {
        // elapsedDistance is not available via onReset directly; retrieve from activity.
        var info = Activity.getActivityInfo();
        var distanceMeters = 0.0f;
        if (info != null && info.elapsedDistance != null) {
            distanceMeters = (info.elapsedDistance as Float);
        }

        var overdue = MaintenanceManager.updateAfterRide(_activeBikeIndex, distanceMeters);

        if (overdue.size() > 0) {
            var bikeName = Application.Properties.getValue("bike" + (_activeBikeIndex + 1).toString() + "Name") as String or Null;
            if (bikeName == null) { bikeName = "Bike " + (_activeBikeIndex + 1).toString(); }
            var alertView     = new AlertView(bikeName, overdue);
            var alertDelegate = new AlertDelegate(alertView);
            WatchUi.pushView(alertView, alertDelegate, WatchUi.SLIDE_UP);
        }
    }

    // Reads the active bike index from app properties (may be changed in Garmin Connect).
    private function _getActiveBikeIndex() as Number {
        var idx = Application.Properties.getValue("activeBikeIndex") as Number or Null;
        if (idx == null || idx < 0 || idx >= MaintenanceManager.NUM_BIKES) {
            return 0;
        }
        return idx;
    }
}
