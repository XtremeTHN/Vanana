using Utils;

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/mod-page.ui")]
public class ModPage : SubmissionPage {
    [GtkChild]
    private override unowned Adw.PreferencesGroup updates_group {get;}

    [GtkChild]
    private override unowned Adw.PreferencesGroup credits_group {get;}

    [GtkChild]
    private override unowned Gtk.Picture submission_icon {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_title {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_caption {get;}

    [GtkChild]
    private override unowned Gtk.ScrolledWindow scrolled_html {get;}
    
    [GtkChild]
    private override unowned Gtk.Stack stack {get;}

    [GtkChild]
    private override unowned Gtk.Stack submission_icon_stack {get;}

    [GtkChild]
    private override unowned Adw.Carousel screenshots_carousel {get;}

    [GtkChild]
    private override unowned Gtk.Label upload_date {get;}

    [GtkChild]
    private override unowned Gtk.Label update_date {get;}

    [GtkChild]
    private override unowned Gtk.Label likes {get;}

    [GtkChild]
    private override unowned Gtk.Label views {get;}

    [GtkChild]
    private override unowned Gtk.Label? downloads {get;}

    [GtkChild]
    private override unowned Adw.StatusPage loading_status {get;}

    [GtkChild]
    private override unowned Adw.StatusPage trashed_status {get;}

    [GtkChild]
    private override unowned Gtk.Frame license_frame {get;}

    [GtkChild]
    private override unowned Gtk.Button open_gb_btt {get;}

    [GtkChild]
    private unowned Gtk.Button download_btt;

    [GtkChild]
    private override unowned Adw.StatusPage rating_status {get;}

    private override Vanana.HtmlView submission_description {get; set;}
    private override Vanana.HtmlView submission_license {get; set;}

    public override SubmissionType submission_type { get; set construct; }

    public Json.Array? files;
    public Json.Array? alt_files;
    public Json.Array? archived_files;

    public ModPage (int64 id) {
        Object ();

        submission_type = SubmissionType.MOD;
        submission_id = id;

        init ();    
    }

    public override void request_info () {
        api.get_info.begin (SubmissionType.MOD, submission_id, (obj, res) => {
            try {
                var info = api.get_info.end (res);
                
                handle_info (info);
            } catch (Error e) {
                if (e.message == "Socket I/O timed out")
                    activate_action ("navigation.pop", null);

                Utils.show_toast (this, e.message);
                warning ("Error while obtaining submission info: %s", e.message);
            }
        });
    }

    [GtkCallback]
    private void on_download_clicked () {
        var window = (Vanana.Window) get_root();
        var dialog = new DownloadDialog (submission_name, files, alt_files, archived_files);

        dialog.present (window);
    }

    [GtkCallback]
    private void open_gb_page () {
        var s = new Gtk.UriLauncher (submission_url);
        var root = get_root ();

        if (root != null)
            s.launch.begin ((Vanana.Window) root, null);
        else
            Utils.warn (this, "Couldn't launch uri (root was null).");
    }

    public override void populate_extra_widgets (Json.Object info) {
        if (info.has_member ("_aFiles"))
            files = info.get_array_member ("_aFiles");

        if (info.has_member ("_aAlternateFileSources"))
            alt_files = info.get_array_member ("_aAlternateFileSources");

        if (info.has_member ("_aArchivedFiles"))
            archived_files = info.get_array_member ("_aArchivedFiles");

        if (files == null && alt_files == null && archived_files == null)
            download_btt.set_sensitive (false);
    }

    [GtkCallback]
    private void on_continue_clicked () {
        stack.set_visible_child_name ("main");
    }
}