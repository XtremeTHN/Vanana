[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/submission-item.ui")]
public class SubmissionItem : Gtk.ListBoxRow {
    [GtkChild]
    private unowned Gtk.Picture submission_icon;

    [GtkChild]
    private unowned Gtk.Label submission_name;

    [GtkChild]
    private unowned Gtk.Label submission_type;

    [GtkChild]
    private unowned Gtk.Label submission_upload_date;

    [GtkChild]
    private unowned Gtk.Label submission_update_date;

    [GtkChild]
    private unowned Gtk.Label submission_likes;

    [GtkChild]
    private unowned Gtk.Label submission_views;

    [GtkChild]
    private unowned Gtk.Stack stack;

    public int64 submission_id;
    public SubmissionType? type;

    public SubmissionItem (Json.Object info) {
        Object ();

        var fmt = "%" + int64.FORMAT;
        submission_id = info.get_int_member ("_idRow");
        type = SubmissionType.from_string (info.get_string_member ("_sModelName"));

        submission_name.set_label (info.get_string_member ("_sName"));
        submission_type.set_label (info.get_string_member ("_sModelName"));

        submission_upload_date.set_label (format_relative_time (info.get_int_member ("_tsDateAdded")));
        submission_update_date.set_label (format_relative_time (info.get_int_member ("_tsDateModified")));
        submission_likes.set_label (fmt.printf (info.get_int_member_with_default ("_nLikeCount", 0)));
        submission_views.set_label (fmt.printf (info.get_int_member ("_nViewCount")));

        var preview = info.get_object_member ("_aPreviewMedia");
        if (preview.has_member ("_aImages")) {
            var images = preview.get_array_member ("_aImages");

            var first_image = images.get_element (0).get_object ();

            string url = first_image.get_string_member ("_sBaseUrl") + "/" + first_image.get_string_member ("_sFile220");

            Vanana.cache_download (url, set_preview_icon);
        }
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
        } else if (diff < 31536000) {
            return "%dd".printf ( (int) (diff / 86400)); // days
        } else {
            return "%dy".printf ((int) (diff / 31536000));
        }
    }

    private void set_preview_icon (File? prev) {
        return_if_fail (prev != null);

        stack.set_visible_child_name ("main");
        submission_icon.set_file (prev);
    }
}