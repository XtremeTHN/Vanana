namespace Utils {
    public enum ImageQuality {
        MAX,
        MEDIUM,
        HIGH,
        LOW
    }

    public string capitalize_first (string input) {
        if (input.length == 0)
            return input;

        string inp = input.ascii_down ();

        return inp.substring (0, 1).up () + inp.substring (1);
    }

    string format_relative_time (int64 timestamp) {
        var date = new DateTime.now_utc ();

        int64 now = date.to_unix ();
        int64 diff = now - timestamp;

        if (diff < 60) {
            return "%ds".printf ( (int) diff); // seconds
        } else if (diff < 3600) {
            return "%dm".printf ( (int) (diff / 60)); // minutes
        } else if (diff < 86400) {
            return "%dh".printf ( (int) (diff / 3600)); // hours
        } else if (diff < 2592000) {
            return "%dd".printf ( (int) (diff / 86400)); // days
        } else if (diff < 31536000) {
            return "%dm".printf ((int) (diff / 2592000)); // months
        } else {
            return "%dy".printf ((int) (diff / 31536000)); // years
        }
    }

    public string remove_html_tags (string html) {
        try {
            var reg = new Regex ("<[^>]+>", GLib.RegexCompileFlags.DEFAULT, GLib.RegexMatchFlags.DEFAULT);
            return reg.replace (html, html.length, 0, "", GLib.RegexMatchFlags.DEFAULT).replace ("&", "&amp;");
        } catch (Error e) {
            warning ("Couldn't remove html tags from string.");
            return html;
        }
    }

    public string build_image_url (Json.Object image_info, ImageQuality quality = ImageQuality.MEDIUM) {
        string file = "";
        string default_file = image_info.get_string_member ("_sFile");
        switch (quality) {
            case ImageQuality.MAX:
                file = default_file;
                break;
            case ImageQuality.HIGH:
                file = image_info.get_string_member_with_default ("_sFile530", default_file);
                break;
            case ImageQuality.MEDIUM:
                file = image_info.get_string_member_with_default ("_sFile220", default_file);
                break;
            case ImageQuality.LOW:
                file = image_info.get_string_member_with_default ("_sFile100", default_file);
                break;
        }

        return image_info.get_string_member ("_sBaseUrl") + "/" + file;
    }

    public void warn (Gtk.Widget self, string message) {
        show_toast (self, message);
        warning (message);
    }

    public void show_toast (Gtk.Widget self, string message) {
        var root = (Vanana.Window) self.get_root ();
        if (root == null) {
            warning (message);
            warning ("root is null, append self to some widget");
            return;
        }
        
        root.show_message (message);
    }

    public void show_submission_page (Gtk.Widget self, SubmissionType? type, int64 id) {
        if (type == null) {
            warning ("<%s>: Unknown submission type", id.to_string ());
            return;
        }

        Vanana.Window win = (Vanana.Window) self.get_root ();
        Adw.NavigationPage page;

        switch (type) {
            case SubmissionType.TOOL:
            case SubmissionType.MOD:
                page = new DownloadablePage (type, id);
                break;
            case SubmissionType.WIP:
                page = new WipPage (id);
                break;
            default:
                warning ("<%s>: Submission type not implemented: %s", id.to_string (), type.to_string ());
                Utils.show_toast (self, "\"%s\" submissions are not supported".printf (type.to_string ()));
                return;
        }

        win.navigation_view.push (page);
    }
}