/**
* This file is part of Odysseus Web Browser's Recommendations site (Copyright Adrian Cochrane 2018).
*
* Odysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Odysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Odysseus.  If not, see <http://www.gnu.org/licenses/>.
*/
/** This script takes a screenshot of webpages to be used to represent their
    links both on Odysseus's Recommendations site and
    in Odysseus's topsites display.

    Compile this with valac --pkg webkit2gtk-4.0*/
async void take_screenshot(string url) throws Error {
    var web = new WebKit.WebView();
    var win = new Gtk.OffscreenWindow();
    web.set_size_request(512, 512);
    web.zoom_level = 0.5;
    win.add(web);
    win.show_all();

    web.load_changed.connect((evt) => {
        if (evt == WebKit.LoadEvent.FINISHED) take_screenshot.callback();
    });
    web.load_uri(url);
    yield;

    var shot = yield web.get_snapshot(WebKit.SnapshotRegion.VISIBLE,
            WebKit.SnapshotOptions.NONE, null);
    uint8[] png;
    Gdk.pixbuf_get_from_surface(shot, 0, 0, 512, 512).save_to_buffer(out png, "png");
    var encoded = Base64.encode(png);
    stdout.printf("%s\n", encoded);
}

static int main(string[] args) {
    Gtk.init(ref args);
    int ret = 0;
    var loop = new MainLoop();

    take_screenshot.begin(args[1], (obj, res) => {
        try {
            take_screenshot.end(res);
        } catch (Error err) {ret = -1;}
        loop.quit();
    });
    loop.run();
    return ret;
}
