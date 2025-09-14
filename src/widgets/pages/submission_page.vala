using Utils;

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/submission-page.ui")]
public abstract class SubmissionPage : Adw.NavigationPage {
    [GtkChild]
    public unowned Adw.PreferencesGroup? updates_group {get;}

    [GtkChild]
    public unowned Adw.PreferencesGroup? credits_group {get;}

    [GtkChild]
    public unowned Adw.WrapBox wrap_box {get;}

    private Gtk.Widget _extra_heading_widget;
    public Gtk.Widget heading_widget {
        get {
            return _extra_heading_widget;
        }
        set {
            if (_extra_heading_widget != null)
                heading_box.remove (_extra_heading_widget);

            _extra_heading_widget = value;
            heading_box.append (_extra_heading_widget);
        }
    }

    private Gtk.Box _extra_submission_data;
    public Gtk.Box extra_submission_data {
        get {
            return _extra_submission_data;
        }
        set {
            wrap_box.append (value);
            _extra_submission_data = value;
        }
    }

    [GtkChild]
    private unowned Gtk.Box extra_data_box {get;}

    [GtkChild]
    private unowned Gtk.Box heading_box {get;}

    [GtkChild]
    public unowned Screenshot submission_icon {get;}
    
    [GtkChild]
    public unowned Gtk.Label submission_title {get;}
    
    [GtkChild]
    public unowned Gtk.Label submission_caption {get;}
    
    [GtkChild]
    public unowned Gtk.Box scrolled_box {get;}
    
    [GtkChild]
    public unowned Gtk.Stack stack {get;}
    
    [GtkChild]
    public unowned Gtk.Button continue_btt {get;}
    
    [GtkChild]
    public unowned Gtk.Button open_gb_btt {get;}

    [GtkChild]
    public unowned Adw.Clamp screenshots_clamp {get;}

    [GtkChild]
    public unowned Adw.Carousel screenshots_carousel {get;}
    
    [GtkChild]
    public unowned Adw.CarouselIndicatorDots screenshots_carousel_dots {get;}
    
    [GtkChild]
    public unowned Gtk.Label submission_description {get;}
    
    public Vanana.HtmlView submission_text {get; set;}
    
    public Vanana.HtmlView submission_license {get; set;}
    
    [GtkChild]
    public unowned Gtk.Label upload_date {get;}
    
    [GtkChild]
    public unowned Gtk.Label update_date {get;}
    
    [GtkChild]
    public unowned Gtk.Label likes {get;}
    
    [GtkChild]
    public unowned Gtk.Label views {get;}
    
    [GtkChild]
    public unowned Adw.StatusPage loading_status {get;}
    
    [GtkChild]
    public unowned Adw.StatusPage trashed_status {get;}

    [GtkChild]
    public unowned Adw.StatusPage private_status {get;}
    
    [GtkChild]
    public unowned Gtk.Label license_label {get;}

    [GtkChild]
    public unowned Gtk.Frame license_frame {get;}
    
    [GtkChild]
    public unowned Adw.StatusPage rating_status {get;}
    
    [GtkChild]
    private unowned Gtk.ListBoxRow comments_placeholder_row {get;}
    
    [GtkChild]
    private unowned Gtk.ListBox comment_list {get;}
    
    [GtkChild]
    private unowned Gtk.Stack comments_stack {get;}
    
    [GtkChild]
    private unowned Gtk.Button load_more_comments_btt {get;}

    public Cancellable cancellable {get; set;}

    public abstract SubmissionType? submission_type {get; set;}

    private bool _has_updates;
    public bool has_updates {
        get {
            return _has_updates;
        }
        set {
            updates_group.visible = value;
            _has_updates = value;
        }
    }

    private bool _has_license;
    public bool has_license {
        get {
            return _has_license;
        }
        set {
            license_label.visible = value;
            license_frame.visible = value;
            _has_license = value;
        }
    }

    public string? submission_url {get; set;}
    public string submission_name {get; set;}
    public int64 submission_id {get; set;}

    private int current_comments_page = 1;

    private void on_hidden () {
        cancellable.cancel ();
        message ("destroyed");
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
        hidden.connect (on_hidden);

        submission_text = new Vanana.HtmlView ();

        scrolled_box.append (submission_text);

        if (has_license) {
            submission_license = new Vanana.HtmlView (true);
            submission_license.set_margins (10);
            license_frame.set_child (submission_license);
        }
        
        open_gb_btt.clicked.connect (open_gb_page);
        continue_btt.clicked.connect (on_continue_clicked);
        load_more_comments_btt.clicked.connect (request_comments);

        loading_status.set_description (loading_status.description.printf (submission_type.to_string ()));
        //  trashed_status.set_description (trashe)

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
        Gamebanana.Submissions.get_info.begin (submission_type, submission_id, cancellable, (obj, res) => {
            try {
                var info = Gamebanana.Submissions.get_info.end (res);

                if (handle_info (info)) 
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
        Gamebanana.Submissions.get_posts_feed.begin (submission_type, submission_id, current_comments_page, cancellable, PostsFeedSort.POPULAR, (_, res) => {
            try {
                var response = Gamebanana.Submissions.get_posts_feed.end (res);
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
    
    public virtual bool handle_info (Json.Object info) {
        if (info.has_member ("_aTrashInfo")) {
            populate_trash_status (info.get_object_member ("_aTrashInfo"));
            stack.set_visible_child_name ("trashed");
            return false;
        }

        if (info.get_boolean_member_with_default ("_bIsPrivate", false)) {
            private_status.set_description (private_status.description.printf (submission_type.to_string ()));
            stack.set_visible_child_name ("private");
            return false;
        }

        submission_name = info.get_string_member ("_sName");
        submission_url = info.get_string_member ("_sProfileUrl");
        open_gb_btt.sensitive = true;

        set_title ("%s - %s".printf (submission_name, submission_type.to_string ()));
        return true;
    }

    public void populate_trash_status (Json.Object trash_info) {
        string description = "This %s has been trashed ".printf (submission_type.to_string ()); // TODO: make translatable all strings
        if (trash_info.get_boolean_member ("_bIsTrashedByOwner")) {
            description += "by the owner." 
            + "\nReason: " + trash_info.get_string_member ("_sReason");

            if (trash_info.has_member ("_sDetails")) {
                description += "\nDetails: " + remove_html_tags (trash_info.get_string_member ("_sDetails"));
            }
        } else {
            var rule_info = trash_info.get_object_member ("_aRuleViolated");
            description += "for a rule violation.\n"
            + rule_info.get_string_member ("_sCode") + ": "
            + remove_html_tags (rule_info.get_string_member ("_sText"));
        }

        trashed_status.set_description (description);
    }

    public virtual async void populate (Json.Object info) {
        populate_labels (info);
        
        if (info.has_member ("_aCredits"))
            populate_credits (info.get_array_member ("_aCredits"));
        else
            credits_group.visible = false;

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

    public void populate_images (Json.Object? preview_info) {
        if (preview_info == null || preview_info.has_member ("_aImages") == false) {
            warning ("No preview media");
            screenshots_clamp.visible = false;
            screenshots_carousel_dots.visible = false;
            submission_icon.set_no_preview ();

            return;
        }

        var images = preview_info.get_array_member ("_aImages");

        var sub_img = images.get_element (0).get_object ();
        
        Vanana.cache_download (build_image_url (sub_img, Utils.ImageQuality.MEDIUM), submission_icon.set_file, cancellable);
        
        if (images.get_length () == 1) {
            screenshots_clamp.visible = false;
            screenshots_carousel_dots.visible = false;

            return;
        }

        foreach (var item in images.get_elements ()) {
            var img = item.get_object ();
            var screen = new Screenshot ();
            screenshots_carousel.append (screen);
            Vanana.cache_download (Utils.build_image_url (img, Utils.ImageQuality.HIGH), screen.set_file, cancellable);
        }
    }

    public async void populate_updates () {
        try {
            var response = yield Gamebanana.Submissions.get_updates (submission_type, submission_id);

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

    public override bool handle_info (Json.Object info) {
        if (info.has_member ("_nDownloadCount"))
            downloads.set_label (info.get_int_member ("_nDownloadCount").to_string ());

        if (info.has_member ("_aFiles"))
            files = info.get_array_member ("_aFiles");

        if (info.has_member ("_aAlternateFileSources"))
            alt_files = info.get_array_member ("_aAlternateFileSources");

        if (info.has_member ("_aArchivedFiles"))
            archived_files = info.get_array_member ("_aArchivedFiles");

        if (files == null && alt_files == null && archived_files == null)
            download_btt.set_sensitive (false);

        return base.handle_info (info);
    }
}