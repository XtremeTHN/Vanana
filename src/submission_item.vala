[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/submission-item.ui")]
public class SubmissionItem : Gtk.ListBoxRow {
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
    private unowned Gtk.Overlay cover_overlay;

    private Cancellable cancellable = new Cancellable ();
    public int64 submission_id;
    public SubmissionType? type;

    private void on_destroy () {
        cancellable.cancel ();
    }

    public SubmissionItem (Json.Object info) {
        Object ();
        destroy.connect (on_destroy);

        var cover = new Screenshot ();
        cover_overlay.add_overlay (cover);

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
            if (info.get_string_member ("_sInitialVisibility") != "show")
                cover.blur = true;

            var images = preview.get_array_member ("_aImages");

            var first_image = images.get_element (0).get_object ();

            Vanana.cache_download (Utils.build_image_url (first_image, Utils.ImageQuality.MEDIUM), cover.set_file, cancellable);
        } else {
            cover.set_no_preview ();
        }
    }
}