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

        submission_upload_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateAdded")));
        submission_update_date.set_label (Utils.format_relative_time (info.get_int_member ("_tsDateModified")));
        submission_likes.set_label (fmt.printf (info.get_int_member_with_default ("_nLikeCount", 0)));
        submission_views.set_label (fmt.printf (info.get_int_member ("_nViewCount")));

        var preview = info.get_object_member ("_aPreviewMedia");
        if (preview.has_member ("_aImages")) {
            var images = preview.get_array_member ("_aImages");

            var first_image = images.get_element (0).get_object ();

            Vanana.cache_download (Utils.build_image_url (first_image, Utils.ImageQuality.SIZE_220), set_preview_icon);
        }
    }

    private void set_preview_icon (File? prev) {
        return_if_fail (prev != null);

        stack.set_visible_child_name ("main");
        submission_icon.set_file (prev);
    }
}