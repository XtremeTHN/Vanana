using Utils;

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/mod-page.ui")]
public class ModPage : Adw.NavigationPage {
    [GtkChild]
    private unowned Adw.PreferencesGroup updates_group;

    [GtkChild]
    private unowned Adw.PreferencesGroup credits_group;

    [GtkChild]
    private unowned Gtk.Picture submission_icon;

    [GtkChild]
    private unowned Gtk.Label submission_title;

    [GtkChild]
    private unowned Gtk.Label submission_caption;

    //  [GtkChild]
    //  private unowned HtmlView submission_description;

    [GtkChild]
    private unowned Gtk.ScrolledWindow scrolled_html;
    
    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.Stack submission_icon_stack;

    [GtkChild]
    private unowned Adw.Carousel screenshots_carousel;

    [GtkChild]
    private unowned Gtk.Label upload_date;

    [GtkChild]
    private unowned Gtk.Label update_date;

    [GtkChild]
    private unowned Gtk.Label likes;

    [GtkChild]
    private unowned Gtk.Label views;

    [GtkChild]
    private unowned Gtk.Label downloads;

    [GtkChild]
    private unowned Adw.StatusPage loading_status;

    [GtkChild]
    private unowned Adw.StatusPage trashed_status;

    [GtkChild]
    private unowned Gtk.Frame license_frame;

    [GtkChild]
    private unowned Gtk.Button open_gb_btt;

    [GtkChild]
    private unowned Gtk.Button download_btt;

    [GtkChild]
    private unowned Adw.StatusPage rating_status;

    private string _url;
    public string gb_url {
        get {
            return _url;
        }
        set {
            open_gb_btt.sensitive = value.length > 0;
            _url = value;
        }
    }

    private Vanana.HtmlView submission_description;
    private Vanana.HtmlView submission_license;

    public Cancellable cancellable;

    private Gamebanana.Submissions api;
    public Json.Array? files;
    public Json.Array? alt_files;
    public Json.Array? archived_files;

    public string submission_name;

    public SubmissionType submission_type = SubmissionType.MOD;
    public int64 submission_id;

    public ModPage (int64 id) {
        Object ();
        destroy.connect (on_destroy);
        set_title ("Mod");
        
        cancellable = new Cancellable ();
        submission_id = id;

        submission_description = new Vanana.HtmlView ();
        submission_license = new Vanana.HtmlView (true);
        submission_license.set_margins (10);

        api = new Gamebanana.Submissions ();

        var spinner = new Adw.SpinnerPaintable (loading_status);
        loading_status.set_paintable (spinner);

        scrolled_html.set_child (submission_description);
        license_frame.set_child (submission_license);

        request_info ();
    }

    private void on_destroy () {
        cancellable.cancel ();
    }

    private void request_info () {
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
        var s = new Gtk.UriLauncher (gb_url);
        var root = get_root ();

        if (root != null)
            s.launch.begin ((Vanana.Window) root, null);
        else
            Utils.warn (this, "Couldn't launch uri (root was null).");
    }

    private void handle_info (Json.Object info) {
        const string INT64_FMT = "%" + int64.FORMAT;

        gb_url = info.get_string_member ("_sProfileUrl");

        if (info.get_boolean_member ("_bIsTrashed")) {
            var trash_info = info.get_object_member ("_aTrashInfo");

            trashed_status.set_description ("This mod was trashed: %s".printf(trash_info.get_string_member ("_sReason")));
            stack.set_visible_child_name ("trashed");
            return;
        }

        var submitter = info.get_object_member ("_aSubmitter");
        submission_name = info.get_string_member ("_sName");
        submission_title.set_label (submission_name);
        set_title ("%s - Mod".printf (submission_name));

        if (submitter.has_member ("_sName")) {
            var name = submitter.get_string_member ("_sName");
            submission_caption.set_label (name);
        }

        submission_description.set_html (info.get_string_member_with_default("_sText", "No description"));
        submission_license.set_html (info.get_string_member_with_default ("_sLicense", "No license"));
        
        upload_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateAdded")));
        update_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateModified")));
        likes.set_label (INT64_FMT.printf (info.get_int_member ("_nLikeCount")));
        views.set_label (INT64_FMT.printf (info.get_int_member ("_nViewCount")));
        downloads.set_label (INT64_FMT.printf (info.get_int_member ("_nDownloadCount")));

        populate_credits (info.get_array_member ("_aCredits"));
        populate_updates.begin ((_, res) => {
            populate_updates.end (res);

            show_main (info);
            populate_images (info.get_object_member ("_aPreviewMedia"));
        });

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

    private void populate_ratings_warning (Json.Object ratings) {
        string label = rating_status.get_description ();
        foreach (var member in ratings.get_members ()) {
            var rating = ratings.get_string_member (member);
            label += rating + "\n";
        }

        label = label.replace ("&", "&amp;");
        rating_status.set_description (label.printf (SubmissionType.MOD.to_string ()));
    }

    private void show_main (Json.Object info) {
        var visibility = info.get_string_member ("_sInitialVisibility");

        if (visibility != "warn") {
            stack.set_visible_child_name ("main");
            return;
        }

        populate_ratings_warning (info.get_object_member ("_aContentRatings"));
        stack.set_visible_child_name ("rating-warning");
    }

    private void populate_credits (Json.Array? credits) {
        return_if_fail (credits != null);

        if (credits.get_length () == 0) {
            var row = new Adw.ActionRow ();
            row.set_title ("No updates");
            credits_group.add (row);
            return;
        }

        foreach (var item in credits.get_elements ()) {
            var credit = item.get_object ();

            string group_name = remove_html_tags (credit.get_string_member_with_default ("_sGroupName", "Unknown group"));
            var expander = new Adw.ExpanderRow ();
            expander.set_title (group_name);
            credits_group.add (expander);

            foreach (var a_item in credit.get_array_member ("_aAuthors").get_elements ()) {
                var author = a_item.get_object ();

                var row = new Adw.ActionRow ();
                row.add_css_class ("property");
                
                if (author.has_member ("_sRole"))
                    row.set_title (remove_html_tags (author.get_string_member ("_sRole")));

                row.set_subtitle (remove_html_tags (author.get_string_member ("_sName")));

                expander.add_row (row);
            }
        }
    }

    private async void populate_updates () {
        try {
            var response = yield api.get_updates (SubmissionType.MOD, submission_id);

            foreach (var update_array in response) {
                if (update_array.get_length () == 0) {
                    var row = new Adw.ActionRow ();
                    row.set_title ("No updates");
                    updates_group.add (row);
                    return;
                }
                
                foreach (var item in update_array.get_elements ()) {
                    var update = item.get_object ();

                    var name = remove_html_tags (update.get_string_member ("_sName"));
                    var text = remove_html_tags (update.get_string_member ("_sText"));

                    if (update.has_member ("_aChangeLog") == false) {
                        var row = new Adw.ActionRow ();
                        row.set_title (name);
                        row.set_subtitle (text);
                        updates_group.add (row);
                        continue;
                    }

                    var changelog = update.get_array_member ("_aChangeLog");
                    foreach (var c_item in changelog.get_elements ()) {
                        var change = c_item.get_object ();
                        var row = new Adw.ActionRow ();
                        
                        row.set_title (remove_html_tags (change.get_string_member ("cat")));
                        row.set_subtitle (remove_html_tags (change.get_string_member ("text")));
                        
                        updates_group.add (row);
                    }
                }
            }
        } catch (Error e) {
            warning ("Couldn't populate updates group: %s", e.message);
        }
    }

    private void populate_images (Json.Object? preview_info) {
        if (preview_info == null) {
            warning ("No preview media");
            return;
        }

        var images = preview_info.get_array_member ("_aImages");

        if (images.get_length () == 0) {
            warning ("No preview media");
            return;
        }

        var sub_img = images.get_element (0).get_object ();
        Vanana.cache_download (Utils.build_image_url (sub_img, Utils.ImageQuality.MEDIUM), set_submission_icon, cancellable);

        foreach (var item in images.get_elements ()) {
            var img = item.get_object ();
            var screen = new Screenshot ();
            screenshots_carousel.append (screen);
            Vanana.cache_download (Utils.build_image_url (img, Utils.ImageQuality.HIGH), screen.set_file, cancellable);
        }
    }

    private void set_submission_icon (File? img) {
        if (img == null) {
            warning ("submission icon image object is null");
            return;
        }

        submission_icon.set_file (img);
        submission_icon_stack.set_visible_child_name ("main");
    }
}