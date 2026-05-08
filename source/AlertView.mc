import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Shown after saving an activity when one or more parts are overdue.
// Displays a scrollable list of part names and instructions to dismiss.
class AlertView extends WatchUi.View {

    private var _bikeName as String;
    private var _overdueParts as Array<PartConfig>;
    private var _scrollOffset as Number = 0;
    private static const LINES_VISIBLE as Number = 3;

    function initialize(bikeName as String, overdueParts as Array<PartConfig>) {
        View.initialize();
        _bikeName = bikeName;
        _overdueParts = overdueParts;
    }

    function onLayout(dc as Graphics.Dc) as Void {
        // Layout handled in onUpdate.
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        // Title
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 8, Graphics.FONT_SMALL, "MAINTENANCE DUE", Graphics.TEXT_JUSTIFY_CENTER);

        var titleH = dc.getFontHeight(Graphics.FONT_SMALL);
        var tinyH  = dc.getFontHeight(Graphics.FONT_XTINY);

        // Bike name subtitle
        dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, 8 + titleH + 2, Graphics.FONT_XTINY, _bikeName, Graphics.TEXT_JUSTIFY_CENTER);

        var nameH = titleH;
        var descH = tinyH;
        var itemH = nameH + descH + 4;
        var startY = 8 + titleH + 2 + tinyH + 4;

        var count = _overdueParts.size();
        var end   = _scrollOffset + LINES_VISIBLE;
        if (end > count) { end = count; }

        for (var i = _scrollOffset; i < end; i++) {
            var part = _overdueParts[i];
            var y = startY + (i - _scrollOffset) * itemH;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(8, y, Graphics.FONT_SMALL, "• " + part.name, Graphics.TEXT_JUSTIFY_LEFT);
            if (!part.description.equals("")) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(16, y + nameH + 1, Graphics.FONT_XTINY, part.description, Graphics.TEXT_JUSTIFY_LEFT);
            }
        }

        // Scroll hint
        if (count > LINES_VISIBLE) {
            var hint = (_scrollOffset + LINES_VISIBLE < count) ? "v more v" : "^ top ^";
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(w / 2, h - dc.getFontHeight(Graphics.FONT_XTINY) - 18,
                        Graphics.FONT_XTINY, hint, Graphics.TEXT_JUSTIFY_CENTER);
        }

        // Dismiss instruction
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(w / 2, h - dc.getFontHeight(Graphics.FONT_XTINY) - 2,
                    Graphics.FONT_XTINY, "LAP to dismiss", Graphics.TEXT_JUSTIFY_CENTER);
    }

    // Scroll down through the list.
    function scrollDown() as Void {
        if (_scrollOffset + LINES_VISIBLE < _overdueParts.size()) {
            _scrollOffset++;
            WatchUi.requestUpdate();
        }
    }

    // Scroll up through the list.
    function scrollUp() as Void {
        if (_scrollOffset > 0) {
            _scrollOffset--;
            WatchUi.requestUpdate();
        }
    }
}

// Input delegate for AlertView — handles LAP button and touch to dismiss.
class AlertDelegate extends WatchUi.InputDelegate {

    private var _view as AlertView;

    function initialize(view as AlertView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_LAP) {
            WatchUi.popView(WatchUi.SLIDE_DOWN);
            return true;
        }
        if (key == WatchUi.KEY_DOWN) {
            _view.scrollDown();
            return true;
        }
        if (key == WatchUi.KEY_UP) {
            _view.scrollUp();
            return true;
        }
        return false;
    }

    function onTap(tapEvent as WatchUi.ClickEvent) as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
