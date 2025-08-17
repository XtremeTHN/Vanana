[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/comment.ui")]
public class Comment : Gtk.ListBoxRow {
    [GtkChild]
    private unowned Adw.Avatar poster_avatar;

    [GtkChild]
    private unowned Gtk.Label user_name;

    [GtkChild]
    private unowned Gtk.Label user_title;

    [GtkChild]
    private unowned Gtk.Label upload_date;

    [GtkChild]
    private unowned Gtk.Button edit_btt;

    [GtkChild]
    private unowned Gtk.Button trash_btt;

    [GtkChild]
    private unowned Gtk.ScrolledWindow scrolled_html;

    [GtkChild]
    private unowned Gtk.Button load_replies_btt;

    private Cancellable cancellable = new Cancellable ();
    public bool is_reply;
    private int64 post_id;

    public Comment (Json.Object post_info, bool is_reply) {
        Object ();

        var text = post_info.get_string_member ("_sText");

        var html_view = new Vanana.HtmlView (false);
        scrolled_html.set_child (html_view);

        html_view.set_html (text);

        if (text == "[trashed]")
            return;

        destroy.connect (on_destroy);

        this.is_reply = is_reply;
        this.post_id = post_info.get_int_member ("_idRow");

        load_replies_btt.set_visible (post_info.get_int_member ("_nReplyCount") > 0);
        
        var poster = post_info.get_object_member ("_aPoster");

        user_name.set_label (poster.get_string_member ("_sName"));

        if (poster.has_member ("_sAvatarUrl"))
            Vanana.cache_download (poster.get_string_member ("_sAvatarUrl"), set_poster_avatar, cancellable);
        
        if (poster.has_member ("_sUserTitle")) {
            user_title.set_label (poster.get_string_member ("_sUserTitle"));
            user_title.set_visible (true);
        }

        upload_date.set_label (
            Utils.format_relative_time (post_info.get_int_member ("_tsDateAdded"))
        );

        if (post_info.has_member ("_aAccess")) {
            var access = post_info.get_object_member ("_aAccess");

            edit_btt.set_visible (access.get_boolean_member ("Post_Edit"));
            trash_btt.set_visible (access.get_boolean_member ("Post_Trash"));
        }

    }

    [GtkCallback] // TODO
    private void start_edit_comment () {
        warning ("edit not implemented");
    }

    [GtkCallback] // TODO
    private void trash_comment () {
        warning ("trash not implemented");
    }

    [GtkCallback] // TODO
    private void load_replies () {
        warning ("load not implemented");
    }

    private void on_destroy () {
        cancellable.cancel ();
    }

    private void set_poster_avatar (File? file) {
        if (file == null) {
            warning ("failed to set poster avatar: file is null");
            return;
        }
        
        if (file.get_basename () == "avatar.gif")
            return;
        
        try {
            var paintable = Gdk.Texture.from_file (file);
            poster_avatar.set_custom_image (paintable);
        } catch (Error e) {
            warning ("failed to set poster avatar: %s", e.message);
        }
    }
}