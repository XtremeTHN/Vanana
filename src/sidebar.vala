[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/download-row.ui")]
public class DownloadRow : Gtk.ListBoxRow {
    [GtkChild]
    private unowned Gtk.Label file_title;

    [GtkChild]
    private unowned Gtk.Label file_name;

    [GtkChild]
    private unowned Gtk.Label progress_string;

    [GtkChild]
    private unowned Gtk.Label speed;

    [GtkChild]
    private unowned Gtk.Button stop_btt;

    [GtkChild]
    private unowned Gtk.ProgressBar progress_bar;

    [GtkChild]
    private unowned Gtk.Button open_btt;

    [GtkChild]
    private unowned Gtk.Box error_box;

    [GtkChild]
    private unowned Gtk.Label error_label;

    public signal void finish () {}

    File? dest;
    Cancellable cancellable;
    private string url;
    private int64 start_time;

    public DownloadRow (Json.Object file_info, string submission_name) {
        Object ();

        var date = new DateTime.now_local ();
        start_time = date.to_unix ();

        cancellable = new Cancellable ();
        file_title.set_label (submission_name);
        file_name.set_label (file_info.get_string_member ("_sFile"));
        
        url = file_info.get_string_member ("_sDownloadUrl");
    }

    [GtkCallback]
    private void open_file () {
        var uri = "file://" + dest.get_path ();
        AppInfo.launch_default_for_uri_async.begin (uri, null, null);
    }

    private void copy_callback (int64 current_bytes, int64 total) {
        progress_bar.set_fraction ((double) current_bytes / total);
        progress_string.set_label (
            format_size (current_bytes, FormatSizeFlags.DEFAULT) + " of " +
            format_size (total, FormatSizeFlags.DEFAULT)
        );
        var now = new DateTime.now_local ();
        speed.set_label (format_size ((current_bytes / (now.to_unix () - start_time)), FormatSizeFlags.DEFAULT));
    }

    public void start_download (File _file) {
        dest = _file;
        var src = File.new_for_uri (url);

        src.copy_async.begin (dest, FileCopyFlags.OVERWRITE, Priority.DEFAULT, cancellable, copy_callback, (_, res) => {
            try {
                src.copy_async.end (res);
                download_finish ();

                open_btt.set_visible (true);
            } catch (Error e) {
                download_finish ();

                error_box.set_visible (true);
                error_label.set_label (e.message);
            }
        });
    }

    [GtkCallback]
    public void stop_download () {
        cancellable.cancel ();
        stop_btt.set_sensitive (false);
    }

    private void download_finish () {
        progress_bar.set_visible (false);
        progress_string.set_visible (false);
        speed.set_visible (false);

        stop_btt.set_visible (false);

        finish ();
    }
}

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/sidebar.ui")]
public class Vanana.Sidebar : Adw.NavigationPage {
    [GtkChild]
    private unowned Gtk.Button stop_all_btt;

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.ListBox downloads_box;

    [GtkChild]
    private unowned Gtk.ListBox finished_downloads_box;

    [GtkChild]
    private unowned Gtk.Box active_group;

    [GtkChild]
    private unowned Gtk.Box finished_group;

    private DownloadManager man;

    public Sidebar () {
        Object ();

        man = new DownloadManager ();
        man.download_added.connect (append_down);
        man.download_finish.connect (remove_down);
    }

    private void needs_placeholder_shown () {
        var active_first = downloads_box.get_first_child ();
        var finished_first = finished_downloads_box.get_first_child ();
        
        active_group.set_visible (active_first != null);
        finished_group.set_visible (finished_first != null);

        if (active_first == null && finished_first == null) {
            stack.set_visible_child_name ("placeholder");
        } else {
            if (stack.get_visible_child_name () != "main")
                stack.set_visible_child_name ("main");
        }
    }

    private void append_down (DownloadRow row) {
        downloads_box.append (row);
        needs_placeholder_shown ();
    }

    private void remove_down (DownloadRow row) {
        downloads_box.remove (row);
        finished_downloads_box.append (row);
        needs_placeholder_shown ();
    }
}