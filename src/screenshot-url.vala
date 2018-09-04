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
/** This is the backend script for saving a screenshot of a URL to a given filepath.

    That's the central logic behind the extra nicities this site provides.
    
    Compile this with valac --pkg webkit2gtk-4.0 */
errordomain ScreenshotError {FAILED, SAVE, LOAD}
private async void screenshot_async(WebKit.WebView web, string url, string savepath)
        throws Error {
    var hook = web.load_changed.connect((evt) => {
        stderr.printf("."); stderr.flush();
        if (evt != WebKit.LoadEvent.FINISHED) return;

        screenshot_async.callback();
    });
    var errmsg = "";
    var errhook = web.load_failed.connect((evt, uri, err) => {
        errmsg = uri + ":\t" + err.message;
        screenshot_async.callback();
        return true; 
    });
    stderr.printf("Loading %s\n", url);
    web.load_uri(url);
    yield;
    web.disconnect(hook);
    web.disconnect(errhook);
    web.stop_loading();
    if (errmsg != "") throw new ScreenshotError.LOAD(errmsg);
    stderr.printf("Loaded %s\n", url);

    var shot = yield web.get_snapshot(WebKit.SnapshotRegion.VISIBLE,
            WebKit.SnapshotOptions.NONE, null);
    if (shot == null) throw new ScreenshotError.FAILED("WebView.get_snapshot");
    stderr.printf("Rendered %s\n", url);

    if (shot.write_to_png(savepath) != Cairo.Status.SUCCESS)
        throw new ScreenshotError.SAVE("Failed to save screenshot to %s", savepath);
    stderr.printf("Saved %s to %s\n", url, savepath);
}

string get_repo() {
    var ret = File.new_for_path(".");
    while (!ret.get_child(".git").query_exists())
        ret = ret.get_parent();
    return ret.get_path() == null ? "." : ret.get_path();
}

int main(string[] args) {
    Gtk.init(ref args);
    if (args.length != 3 && args.length != 2) {
        stderr.printf("USAGE: screenshot-url URL FILE\n");
        return 1;
    }
    var savefile = "";
    if (args.length == 2) {
        var filename = Checksum.compute_for_string(ChecksumType.MD5, args[1]);
        savefile = Path.build_filename(get_repo(), "screenshot", filename + ".png");
    } else savefile = args[2];

    var loop = new MainLoop();

    var web = new WebKit.WebView();
    var win = new Gtk.OffscreenWindow();
    web.set_size_request(512, 512);
    web.zoom_level = 0.5;
    win.add(web);
    win.show_all();

    int exitcode = 0;
    screenshot_async.begin(web, args[1], savefile, (obj, res) => {
        try {
            screenshot_async.end(res);
        } catch (Error err) {
            stderr.printf("%s\n", err.message);
            exitcode = 2;
        }
        loop.quit();
    });
    loop.run();
    return exitcode;
}
