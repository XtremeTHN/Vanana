class Tag : Gtk.Box {
    Gtk.Label title;
    Gtk.ListBox box;

    public Tag () {
        Object (spacing: 5, orientation: Gtk.Orientation.VERTICAL);
        
        title = new Gtk.Label (null);
        title.add_css_class ("heading");
        title.set_xalign (0);
        box = new Gtk.ListBox ();
        box.set_selection_mode (Gtk.SelectionMode.NONE);
        box.set_css_classes ({"boxed-list"});

        append (title);
        append (box);
    }

    void on_save (Object diag, AsyncResult res, string name, string url) {
        try {
            File dest = ((Gtk.FileDialog) diag).save.end (res);
            new DownloadManager ().add_download (name, "", url, dest);
        } catch (Error e) {}
    }

    void download (Adw.ActionRow row) {
        string url = row.get_data<string> ("url");
        string name = row.get_title ();

        var diag = new Gtk.FileDialog ();
        diag.title = name;
        diag.initial_name = name;
        diag.initial_folder = File.new_for_path (Environment.get_user_special_dir (UserDirectory.DOWNLOAD));

        diag.save.begin (Utils.get_parent_window (this), null, (obj, res) => {
            on_save (obj, res, name, url);
        });
    }

    public void set_title (string title) {
        this.title.label = title;
    }

    public void add_source (Json.Object? obj) {
        if (obj == null) return;

        string url = obj.get_string_member ("browser_download_url");
        string name = obj.get_string_member ("name");
        int64 size = obj.get_int_member ("size");

        var row = new Adw.ActionRow ();
        row.set_activatable (true);
        row.set_title (name);
        row.set_subtitle (format_size (size));
        row.set_data<string> ("url", url);

        row.activated.connect (download);
        
        box.append (row);
    }
}

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/engine-downloads.ui")]
public class EngineDownloadsDialog : Adw.Dialog {
    [GtkChild]
    unowned Adw.ViewStack view_stack;

    [GtkChild]
    unowned LoadingWidget funkin;

    [GtkChild]
    unowned LoadingWidget psych;

    [GtkChild]
    unowned LoadingWidget codename;

    public EngineDownloadsDialog () {
        Object ();

        view_stack.notify["visible-child"].connect (on_engine_change);

    }

    public new void present (Gtk.Widget parent) {
        base.present (parent);
        on_engine_change.begin ();
    }

    async void populate_box (LoadingWidget engine, Json.Array releases) {
        engine.start_loading ();

        // TODO: i should think of a better way of getting the box
        var scr = (Gtk.ScrolledWindow) engine.content;
        var box = (Gtk.Box) ((Gtk.Viewport) scr.get_child ()).get_child (); 

        foreach (var item in releases.get_elements ()) {
            var tag = item.get_object ();
            
            var assets = tag.get_array_member ("assets");
            if (assets.get_length () == 0) continue;
            
            var widget = new Tag ();
            widget.set_title (tag.get_string_member ("name"));
            
            foreach (var i in assets.get_elements ()) {
                widget.add_source (i.get_object ());
            }

            box.append (widget);
        }

        engine.finish_loading ();
    }

    async void on_engine_change () {
        var current = (LoadingWidget) view_stack.get_visible_child ();

        if (current.get_is_finished ()) return;

        Json.Array? res;
        LoadingWidget? widget;

        try {
            switch (current.get_name ()) {
                case "funkin":
                    res = yield Github.get_releases ("FunkinCrew", "Funkin");
                    widget = funkin;
                    break;
                case "psych":
                    res = yield Github.get_releases ("ShadowMario", "FNF-PsychEngine");
                    widget = psych;
                    break;
                case "codename":
                    res = yield Github.get_releases ("CodenameCrew", "CodenameEngine");
                    widget = codename;
                    break;
                default:
                    warning ("unknown engine");
                    return;
            }

            yield populate_box (widget, res);
        } catch (Error e) {
            Utils.show_toast (this, "Couldn't get download list: " + e.message);
        }
    }
}