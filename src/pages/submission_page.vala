using Utils;

public abstract class SubmissionPage : Adw.NavigationPage {
    public virtual unowned Adw.PreferencesGroup updates_group {get;}
    public virtual unowned Adw.PreferencesGroup credits_group {get;}

    public virtual unowned Gtk.Picture submission_icon {get;}
    public abstract unowned Gtk.Label submission_title {get;}
    public abstract unowned Gtk.Label submission_caption {get;}

    public abstract unowned Gtk.ScrolledWindow scrolled_html {get;}

    public abstract unowned Gtk.Stack stack {get;}
    public virtual unowned Gtk.Stack submission_icon_stack {get;}

    public abstract unowned Gtk.Button continue_btt {get;}
    public abstract unowned Gtk.Button open_gb_btt {get;}

    public abstract unowned Adw.Carousel screenshots_carousel {get;}

    public abstract Vanana.HtmlView submission_description {get; set;}
    public virtual Vanana.HtmlView submission_license {get; set;}
    
    public abstract unowned Gtk.Label upload_date {get;}
    public abstract unowned Gtk.Label update_date {get;}
    public abstract unowned Gtk.Label likes {get;}
    public abstract unowned Gtk.Label views {get;}
    public abstract unowned Adw.StatusPage loading_status {get;}
    public abstract unowned Adw.StatusPage trashed_status {get;}

    public virtual unowned Gtk.Frame license_frame {get;}

    public abstract unowned Adw.StatusPage rating_status {get;}

    public Cancellable cancellable {get; set;}
    public Gamebanana.Submissions api {get; set;}

    public abstract SubmissionType? submission_type {get; set;}

    public string? submission_url {get; set;}
    public string submission_name {get; set;}
    public int64 submission_id {get; set;}

    private void on_destroy () {
        cancellable.cancel ();
    }

    /**
     * Sets required properties. Call this when constructing subclass
     * 
     * You need to set submission_id and submission_type before calling this method;
     */
    public virtual void init () {
        if (submission_type == null)
            error ("submission type should not be null"); 
        if (submission_id == 0)
            error ("submission id should not be 0");

        set_title (submission_type.to_string ());
        cancellable = new Cancellable ();
        destroy.connect (on_destroy);

        submission_description = new Vanana.HtmlView ();

        api = new Gamebanana.Submissions ();

        var spinner = new Adw.SpinnerPaintable (loading_status);
        loading_status.set_paintable (spinner);

        scrolled_html.set_child (submission_description);

        if (license_frame != null) {
            submission_license = new Vanana.HtmlView (true);
            submission_license.set_margins (10);
            license_frame.set_child (submission_license);
        }
        
        open_gb_btt.clicked.connect (open_gb_page);
        continue_btt.clicked.connect (on_continue_clicked);

        request_info ();
    }

    private void open_gb_page () {
        var s = new Gtk.UriLauncher (submission_url);
        var root = get_root ();

        if (root != null)
            s.launch.begin ((Vanana.Window) root, null);
        else
            Utils.warn (this, "Couldn't launch uri (root was null).");
    }

    private void on_continue_clicked () {
        stack.set_visible_child_name ("main");
    }

    public virtual void request_info () {
        api.get_info.begin (submission_type, submission_id, (obj, res) => {
            try {
                var info = api.get_info.end (res);

                handle_info (info);
                populate (info);
            } catch (Error e) {
                if (e.message == "Socket I/O timed out")
                    activate_action ("navigation.pop", null);

                Utils.show_toast (this, e.message);
                warning ("Error while obtaining submission info: %s", e.message);
            }
        });
    }
    public virtual void populate_extra_widgets (Json.Object info) {}
    
    public virtual void handle_info (Json.Object info) {
        submission_name = info.get_string_member ("_sName");
        submission_url = info.get_string_member ("_sProfileUrl");
        open_gb_btt.sensitive = true;

        set_title ("%s - %s".printf (submission_name, submission_type.to_string ()));
    }

    public virtual void populate (Json.Object info) {
        populate_labels (info);
        populate_credits (info.get_array_member ("_aCredits"));
        populate_updates.begin ((_, res) => {
            populate_updates.end (res);

            populate_extra_widgets (info);
            show_main (info);
            populate_images (info.get_object_member ("_aPreviewMedia"));
        });
    }

    public virtual void populate_labels (Json.Object info) {
        var submitter = info.get_object_member ("_aSubmitter");
        submission_title.set_label (submission_name);

        if (submitter.has_member ("_sName")) {
            var name = submitter.get_string_member ("_sName");
            submission_caption.set_label (name);
        }

        submission_description.set_html (info.get_string_member_with_default("_sText", "No description"));

        if (submission_license != null)
            submission_license.set_html (info.get_string_member_with_default ("_sLicense", "No license"));

        upload_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateAdded")));
        update_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateModified")));
        likes.set_label (info.get_int_member ("_nLikeCount").to_string ());
        views.set_label (info.get_int_member ("_nViewCount").to_string ());
    }

    public virtual void populate_ratings_warning (Json.Object ratings) {
        string label = rating_status.get_description ();
        foreach (var member in ratings.get_members ()) {
            var rating = ratings.get_string_member (member);
            label += "• " + rating + "\n";
        }

        label = label.replace ("&", "&amp;");
        rating_status.set_description (label.printf (submission_type.to_string ().ascii_down ()));
    }

    public virtual void show_main (Json.Object info) {
        var visibility = info.get_string_member ("_sInitialVisibility");

        if (visibility != "warn") {
            stack.set_visible_child_name ("main");
            return;
        }

        populate_ratings_warning (info.get_object_member ("_aContentRatings"));
        stack.set_visible_child_name ("rating-warning");
    }

    public virtual void set_submission_icon (File? img) {
        if (img == null) {
            submission_icon_stack.set_visible_child_name ("no-preview");
            return;
        }

        submission_icon.set_file (img);
        submission_icon_stack.set_visible_child_name ("main");
    }

    public virtual void populate_images (Json.Object? preview_info) {
        if (preview_info == null || preview_info.has_member ("_aImages") == false) {
            warning ("No preview media");
            screenshots_carousel.set_visible (false);
            set_submission_icon (null);

            return;
        }

        var images = preview_info.get_array_member ("_aImages");

        if (images.get_length () == 0) {
            warning ("No preview media");
            return;
        }

        var sub_img = images.get_element (0).get_object ();
        
        if (submission_icon != null)
            Vanana.cache_download (build_image_url (sub_img, Utils.ImageQuality.MEDIUM), set_submission_icon, cancellable);

        foreach (var item in images.get_elements ()) {
            var img = item.get_object ();
            var screen = new Screenshot ();
            screenshots_carousel.append (screen);
            Vanana.cache_download (Utils.build_image_url (img, Utils.ImageQuality.HIGH), screen.set_file, cancellable);
        }
    }

    public virtual async void populate_updates () {
        if (updates_group == null)
            return;

        try {
            var response = yield api.get_updates (submission_type, submission_id);

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

    public virtual void populate_credits (Json.Array? credits) {
        return_if_fail (credits != null);
        if (credits_group == null)
            return;

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
}

public abstract class DownloadableSubmissionPage : SubmissionPage {
    public Json.Array? files;
    public Json.Array? alt_files;
    public Json.Array? archived_files;

    private abstract unowned Gtk.Label downloads {get;}
    private abstract unowned Gtk.Button download_btt {get;}

    public override void init () {
        base.init ();

        download_btt.clicked.connect (on_download_clicked);
    }

    private void on_download_clicked () {
        var window = (Vanana.Window) get_root();
        var dialog = new DownloadDialog (submission_name, files, alt_files, archived_files);

        dialog.present (window);
    }

    public override void handle_info (Json.Object info) {
        base.handle_info (info);

        downloads.set_label (info.get_int_member ("_nDownloadCount").to_string ());

        if (info.has_member ("_aFiles"))
            files = info.get_array_member ("_aFiles");

        if (info.has_member ("_aAlternateFileSources"))
            alt_files = info.get_array_member ("_aAlternateFileSources");

        if (info.has_member ("_aArchivedFiles"))
            archived_files = info.get_array_member ("_aArchivedFiles");

        if (files == null && alt_files == null && archived_files == null)
            download_btt.set_sensitive (false);
    }
}