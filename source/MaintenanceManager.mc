import Toybox.Application;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Holds configuration for a single tracked part.
class PartConfig {
    var name as String;
    var description as String;
    var kmThreshold as Number;      // 0 = disabled
    var daysThreshold as Number;    // 0 = disabled

    function initialize(n as String, desc as String, km as Number, days as Number) {
        name = n;
        description = desc;
        kmThreshold = km;
        daysThreshold = days;
    }
}

// Mutable runtime state for a single part.
class PartState {
    var cumulativeKm as Float;
    var lastMaintenanceDate as String; // "YYYY-MM-DD" or ""

    function initialize(km as Float, date as String) {
        cumulativeKm = km;
        lastMaintenanceDate = date;
    }
}

class MaintenanceManager {

    static const NUM_BIKES as Number = 2;
    static const NUM_PARTS as Number = 5;

    // Returns today's date as a "YYYY-MM-DD" string.
    static function todayString() as String {
        var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return now.year.format("%04d") + "-" + now.month.format("%02d") + "-" + now.day.format("%02d");
    }

    // Parses a "YYYY-MM-DD" string into a Moment. Returns null on failure.
    static function parseDate(dateStr as String) as Time.Moment or Null {
        if (dateStr.length() != 10) {
            return null;
        }
        var year  = dateStr.substring(0, 4).toNumber();
        var month = dateStr.substring(5, 7).toNumber();
        var day   = dateStr.substring(8, 10).toNumber();
        if (year == null || month == null || day == null) {
            return null;
        }
        return Gregorian.moment({ :year => year, :month => month, :day => day,
                                  :hour => 12, :minute => 0, :second => 0 });
    }

    // Reads app settings and returns an array of NUM_PARTS PartConfig for bikeIndex (0-based).
    static function loadParts(bikeIndex as Number) as Array<PartConfig> {
        var prefix = "bike" + (bikeIndex + 1).toString() + "Part";
        var parts = [] as Array<PartConfig>;

        for (var i = 1; i <= NUM_PARTS; i++) {
            var name  = Application.Properties.getValue(prefix + i.toString() + "Name") as String or Null;
            var desc  = Application.Properties.getValue(prefix + i.toString() + "Description") as String or Null;
            var km    = Application.Properties.getValue(prefix + i.toString() + "KmThreshold") as Number or Null;
            var days  = Application.Properties.getValue(prefix + i.toString() + "DaysThreshold") as Number or Null;
            if (name == null) { name = "Part " + i.toString(); }
            if (desc == null) { desc = ""; }
            if (km   == null) { km   = 0; }
            if (days == null) { days = 0; }
            parts.add(new PartConfig(name, desc, km, days));
        }
        return parts;
    }

    // Loads full persistent state dictionary from storage.
    // Shape: { "bike0": { "part0": { "cumulativeKm": Float, "lastMaintenanceDate": String }, ... }, ... }
    static function loadState() as Dictionary {
        var state = Application.Storage.getValue("state") as Dictionary or Null;
        if (state == null) {
            state = {} as Dictionary;
        }
        return state;
    }

    static function saveState(state as Dictionary) as Void {
        Application.Storage.setValue("state", state);
    }

    // Gets (or initialises) state for a specific bike/part.
    static function getPartState(state as Dictionary, bikeIndex as Number, partIndex as Number) as Dictionary {
        var bikeKey = "bike" + bikeIndex.toString();
        var partKey = "part" + partIndex.toString();

        if (!state.hasKey(bikeKey)) {
            state[bikeKey] = {} as Dictionary;
        }
        var bikeState = state[bikeKey] as Dictionary;
        if (!bikeState.hasKey(partKey)) {
            bikeState[partKey] = { "cumulativeKm" => 0.0f, "lastMaintenanceDate" => "" };
        }
        return bikeState[partKey] as Dictionary;
    }

    // Returns true when the part needs maintenance.
    static function isOverdue(config as PartConfig, partState as Dictionary) as Boolean {
        var cumKm = partState["cumulativeKm"] as Float;

        if (config.kmThreshold > 0 && cumKm >= config.kmThreshold.toFloat()) {
            return true;
        }

        if (config.daysThreshold > 0) {
            var dateStr = partState["lastMaintenanceDate"] as String;
            if (dateStr.equals("")) {
                // Never maintained — treat as overdue if a threshold is set.
                return true;
            }
            var lastMaint = parseDate(dateStr);
            if (lastMaint != null) {
                var elapsed = Time.now().subtract(lastMaint);
                var elapsedDays = (elapsed.value() / 86400).toNumber();
                if (elapsedDays >= config.daysThreshold) {
                    return true;
                }
            }
        }

        return false;
    }

    // Adds ride distance (metres) to every part of the active bike.
    // Returns an array of overdue PartConfig (may be empty).
    static function updateAfterRide(bikeIndex as Number, distanceMeters as Float) as Array<PartConfig> {
        var distanceKm = distanceMeters / 1000.0f;
        var parts      = loadParts(bikeIndex);
        var state      = loadState();
        var overdue    = [] as Array<PartConfig>;

        for (var i = 0; i < NUM_PARTS; i++) {
            var ps = getPartState(state, bikeIndex, i);
            ps["cumulativeKm"] = (ps["cumulativeKm"] as Float) + distanceKm;

            if (isOverdue(parts[i], ps)) {
                overdue.add(parts[i]);
            }
        }

        saveState(state);
        return overdue;
    }

    // Returns km remaining to the nearest upcoming maintenance threshold for any part
    // on the given bike. Returns null if nothing is configured.
    static function kmToNextMaintenance(bikeIndex as Number) as Float or Null {
        var parts   = loadParts(bikeIndex);
        var state   = loadState();
        var minKm   = null as Float or Null;

        for (var i = 0; i < NUM_PARTS; i++) {
            var config = parts[i];
            if (config.kmThreshold <= 0) {
                continue;
            }
            var ps     = getPartState(state, bikeIndex, i);
            var cumKm  = ps["cumulativeKm"] as Float;
            var remaining = config.kmThreshold.toFloat() - cumKm;
            if (minKm == null || remaining < (minKm as Float)) {
                minKm = remaining;
            }
        }

        return minKm;
    }

    // Resets cumulative km and last maintenance date for a specific part.
    static function resetPart(bikeIndex as Number, partIndex as Number) as Void {
        var state = loadState();
        var ps    = getPartState(state, bikeIndex, partIndex);
        ps["cumulativeKm"]          = 0.0f;
        ps["lastMaintenanceDate"]   = todayString();
        saveState(state);
    }
}
