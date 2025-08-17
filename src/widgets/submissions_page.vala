using Utils;

public class Vanana.SubmissionPage : Adw.NavigationPage {
    private unowned Adw.PreferencesGroup updates_group;
    private unowned Adw.PreferencesGroup credits_group;

    private unowned Gtk.Picture submission_icon;
    private unowned Gtk.Label submission_title;
    private unowned Gtk.Label submission_caption;
    //  private unowned HtmlView submission_description;

    private unowned Gtk.ScrolledWindow scrolled_html;
    
    private unowned Gtk.Stack stack;
    private unowned Gtk.Stack submission_icon_stack;

    private unowned Adw.Carousel screenshots_carousel;

    private unowned Gtk.Label likes;
    private unowned Gtk.Label views;
    private unowned Gtk.Label downloads;

    private unowned Adw.StatusPage loading_status;
    private unowned Adw.StatusPage trashed_status;

    private Gamebanana.Submissions api;
    public Json.Object? info;

    public SubmissionType submission_type;
    public int64 submission_id;

    public SubmissionPage () {
        Object ();
        
        api = new Gamebanana.Submissions ();

        var spinner = new Adw.SpinnerPaintable (loading_status);
        loading_status.set_paintable (spinner);
    }

    public void populate_extra_widgets () {}

    private void add_update_row (Json.Array _, uint pos, Json.Node elem) {
        var update = elem.get_object ();
        if (update.has_member ("_aChangeLog")) {
            var changes = update.get_array_member ("_aChangeLog");
            var row = new Adw.ExpanderRow ();
            row.set_title (remove_html_tags (update.get_string_member ("_sName")));
            row.set_subtitle (remove_html_tags (update.get_string_member ("_sText")));
            
            foreach (var item in changes.get_elements ()) {
                var change = item.get_object ();
                var change_row = new Adw.ActionRow ();
                change_row.add_css_class ("property");
                change_row.set_title (remove_html_tags (change.get_string_member ("cat")));
                change_row.set_subtitle (remove_html_tags (change.get_string_member ("text")));
            }

            updates_group.add (row);
        } else {
            var row = new Adw.ActionRow ();
            row.set_title (remove_html_tags (update.get_string_member ("_sName")));
            row.set_subtitle (remove_html_tags (update.get_string_member ("_sText")));
            
            updates_group.add (row);
        }
    }

    public void populate_updates () {
        api.get_updates.begin (submission_type, (int) submission_id, (obj, res) => {
            try {
                var results = api.get_updates.end (res);

                // TODO: change this if the placeholder is not visible
                if (results.length () == 0) {
                    var placeholder = new Adw.ActionRow ();
                    placeholder.set_title ("No updates");
                    updates_group.add (placeholder);
                    return;
                }

                results.foreach ((array) => {
                    array.foreach_element (add_update_row);
                });
            } catch (Error e) {
                warning ("Couldn't get submission updates: %s", e.message);
            }
        });
    }

    public void populate_credits (Json.Array? credits) {
        if (credits == null) {
            warning ("No credits");
            return;
        }

        if (credits.get_length () == 0) {
            var placeholder = new Adw.ActionRow ();
            placeholder.set_title ("No credits");
            credits_group.add (placeholder);
            return;
        }

        foreach (var item in credits.get_elements ()) {
            var _type = item.get_object ();

            var group_name = remove_html_tags (_type.get_string_member ("_sGroupName"));
            var authors = _type.get_array_member ("_aAuthors");

            var row = new Adw.ExpanderRow ();
            row.set_title (group_name);

            foreach (var a_item in authors.get_elements ()) {
                var author_info = a_item.get_object ();
                var author = author_info.get_string_member_with_default ("_sName", "Unknown author");
                var author_row = new Adw.ActionRow ();
                
                string role = author_info.get_string_member_with_default ("_sRole", "Unknown role");;
                
                author_row.add_css_class ("property");
                author_row.set_title (remove_html_tags (role));
                author_row.set_subtitle (remove_html_tags (author));

                row.add_row (author_row);
            }
        }
    }

    public void populate_images () {
        // TODO: maybe add a button to open youtube videos?
        var preview_media = info.get_object_member ("_aPreviewMedia").get_array_member ("_aImages");

        if (preview_media.get_length () == 0) {
            warning ("No preview media");
            return;
        }

        var cover = preview_media.get_element (0).get_object ();
        cache_download (Utils.build_image_url (cover, Utils.ImageQuality.SIZE_100), (img) => {
            return_if_fail (img != null);
            submission_icon.set_file (img);
            submission_icon_stack.set_visible_child_name ("main");
        });

        foreach (var item in preview_media.get_elements ()) {
            var img = item.get_object ();
            cache_download (Utils.build_image_url (img, Utils.ImageQuality.SIZE_220), (file) => {
                var screenshot = new Screenshot (file);
                screenshots_carousel.append (screenshot);
            });
        }

    }

    public void populate () {
        var submitter = info.get_object_member ("_aSubmitter");
        submission_title.set_label (info.get_string_member ("_sName"));
        if (submitter != null)
            submission_caption.set_label (submitter.get_string_member ("_sName"));
        
        
        likes.set_label (("%" + int64.FORMAT).printf(info.get_int_member ("_nLikeCount")));
        likes.set_label (("%" + int64.FORMAT).printf(info.get_int_member ("_nViewCount")));

        if (submission_type == SubmissionType.MOD || submission_type == SubmissionType.TOOL)
            likes.set_label (("%" + int64.FORMAT).printf(info.get_int_member ("_nLikeCount")));
    
        populate_updates ();
        populate_credits (submitter.get_array_member ("_aCredits"));
        populate_extra_widgets ();

        stack.set_visible_child_name ("main");

        populate_images ();
    }

    public void show_if_trashed () {
        if (!info.get_boolean_member_with_default ("_bIsTrashed", true))
            return;

        var trash_info = info.get_object_member ("_aTrashInfo");
        var reason = trash_info.get_string_member_with_default ("_sReason", "No reason");
        trashed_status.set_description (reason);

        stack.set_visible_child_name ("trashed");
    }

    public void request_info () {
        api.get_info.begin (submission_type, (int) submission_id, (obj, res) => {
            try {
                var response = api.get_info.end (res);
                if (response == null) {
                    warning ("couldn't get response object");
                    return;
                }

                this.info = response;

                show_if_trashed ();
                populate ();
            } catch (Error e) {
                warning ("Error while trying to get submission (%"+ int64.FORMAT + ") info: %s", submission_id, e.message);
            }
        });
    }
}