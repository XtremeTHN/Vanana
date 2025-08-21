using Utils;

public abstract class SubmissionPage : Adw.NavigationPage {
    public virtual unowned Adw.PreferencesGroup updates_group {get;}
    public virtual unowned Adw.PreferencesGroup credits_group {get;}

    public virtual unowned Gtk.Picture submission_icon {get;}
    public abstract unowned Gtk.Label submission_title {get;}
    public abstract unowned Gtk.Label submission_caption {get;}

    public abstract unowned Gtk.Box scrolled_box {get;}

    public abstract unowned Gtk.Stack stack {get;}
    public virtual unowned Gtk.Stack submission_icon_stack {get;}

    public abstract unowned Gtk.Button continue_btt {get;}
    public abstract unowned Gtk.Button open_gb_btt {get;}

    public abstract unowned Adw.Carousel screenshots_carousel {get;}
    public abstract unowned Adw.CarouselIndicatorDots screenshots_carousel_dots {get;}

    public virtual Gtk.Label submission_description {get;}
    public abstract Vanana.HtmlView submission_text {get; set;}
    public virtual Vanana.HtmlView submission_license {get; set;}
    
    public abstract unowned Gtk.Label upload_date {get;}
    public abstract unowned Gtk.Label update_date {get;}
    public abstract unowned Gtk.Label likes {get;}
    public abstract unowned Gtk.Label views {get;}
    public abstract unowned Adw.StatusPage loading_status {get;}
    public abstract unowned Adw.StatusPage trashed_status {get;}

    public virtual unowned Gtk.Frame license_frame {get;}

    public abstract unowned Adw.StatusPage rating_status {get;}

    private abstract unowned Gtk.ListBoxRow comments_placeholder_row {get;}
    private abstract unowned Gtk.ListBox comment_list {get;}
    private abstract unowned Gtk.Stack comments_stack {get;}
    private abstract unowned Gtk.Button load_more_comments_btt {get;}

    public Cancellable cancellable {get; set;}
    public Gamebanana.Submissions api {get; set;}

    public abstract SubmissionType? submission_type {get; set;}

    public virtual bool has_updates {get; set;}
    public virtual bool has_license {get; set;}

    public string? submission_url {get; set;}
    public string submission_name {get; set;}
    public int64 submission_id {get; set;}

    private int current_comments_page = 1;

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

        submission_text = new Vanana.HtmlView ();

        api = new Gamebanana.Submissions ();

        var spinner = new Adw.SpinnerPaintable (loading_status);
        loading_status.set_paintable (spinner);

        scrolled_box.append (submission_text);

        if (has_license) {
            submission_license = new Vanana.HtmlView (true);
            submission_license.set_margins (10);
            license_frame.set_child (submission_license);
        }
        
        open_gb_btt.clicked.connect (open_gb_page);
        continue_btt.clicked.connect (on_continue_clicked);
        load_more_comments_btt.clicked.connect (request_comments);

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
                populate.begin (info);
            } catch (Error e) {
                if (e.message == "Socket I/O timed out")
                    activate_action ("navigation.pop", null);

                Utils.show_toast (this, e.message);
                warning ("Error while obtaining submission info: %s", e.message);
            }
        });
    }

    private void request_comments () { 
        load_more_comments_btt.set_sensitive (false);
        api.get_posts_feed.begin (submission_type, submission_id, current_comments_page, PostsFeedSort.POPULAR, (_, res) => {
            try {
                var response = api.get_posts_feed.end (res);
                var metadata = response.get_object_member ("_aMetadata");

                load_more_comments_btt.set_sensitive (!metadata.get_boolean_member ("_bIsComplete"));

                populate_comments (response);

                current_comments_page += 1;
            } catch (Error e) {
                Utils.warn (this, "Couldn't populate comments: " + e.message);
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

    public virtual async void populate (Json.Object info) {
        populate_labels (info);
        
        if (info.has_member ("_aCredits"))
            populate_credits (info.get_array_member ("_aCredits"));

        if (has_updates)
            yield populate_updates ();

        populate_extra_widgets (info);
        show_main (info);
        populate_images (info.get_object_member ("_aPreviewMedia"));
        request_comments ();
    }

    public virtual void populate_labels (Json.Object info) {
        var submitter = info.get_object_member ("_aSubmitter");
        submission_title.set_label (submission_name);

        if (submitter.has_member ("_sName")) {
            var name = submitter.get_string_member ("_sName");
            submission_caption.set_label (name);
        }

        if (info.has_member ("_sDescription")) {
            submission_description.set_label (info.get_string_member ("_sDescription"));
            submission_description.set_visible (true);
            var sep = submission_description.get_next_sibling ();
            sep.set_visible (true);
        }

        submission_text.set_html (info.get_string_member_with_default("_sText", "No description"));

        if (has_license)
            submission_license.set_html (info.get_string_member_with_default ("_sLicense", "No license"));

        upload_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateAdded")));
        update_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateModified")));
        likes.set_label (info.get_int_member ("_nLikeCount").to_string ());
        views.set_label (info.get_int_member ("_nViewCount").to_string ());
    }

    public void populate_ratings_warning (Json.Object ratings) {
        string label = rating_status.get_description ();
        foreach (var member in ratings.get_members ()) {
            var rating = ratings.get_string_member (member);
            label += "• " + rating + "\n";
        }

        label = label.replace ("&", "&amp;");
        rating_status.set_description (label.printf (submission_type.to_string ().ascii_down ()));
    }

    public void show_main (Json.Object info) {
        var visibility = info.get_string_member ("_sInitialVisibility");

        if (visibility == "show") {
            stack.set_visible_child_name ("main");
            return;
        }

        populate_ratings_warning (info.get_object_member ("_aContentRatings"));
        stack.set_visible_child_name ("rating-warning");
    }

    public void set_submission_icon (File? img) {
        if (img == null) {
            submission_icon_stack.set_visible_child_name ("no-preview");
            return;
        }

        submission_icon.set_file (img);
        submission_icon_stack.set_visible_child_name ("main");
    }

    public void populate_images (Json.Object? preview_info) {
        if (preview_info == null || preview_info.has_member ("_aImages") == false) {
            warning ("No preview media");
            screenshots_carousel.set_visible (false);
            screenshots_carousel_dots.set_visible (false);
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

    public async void populate_updates () {
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

    public void populate_credits (Json.Array? credits) {
        if (credits.get_length () == 0) {
            var row = new Adw.ActionRow ();
            row.set_title ("No credits");
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

    public virtual void populate_comments (Json.Object? response) {
        return_if_fail (response != null);

        var records = response.get_array_member ("_aRecords");
        
        if (records.get_length () != 0) {
            comments_placeholder_row.set_visible (false);

            foreach (var item in records.get_elements ()) {
                var post = item.get_object ();

                var post_widget = new Comment (post, false);
                comment_list.append (post_widget);
            }
        }

        comments_stack.set_visible_child_name ("main");
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