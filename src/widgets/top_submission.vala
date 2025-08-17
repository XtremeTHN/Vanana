using Utils;

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/top-submission.ui")]
public class TopSubmission : Adw.Bin {
    [GtkChild]
    private unowned Gtk.Picture submission_preview;

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.Button open_btt;

    [GtkChild]
    private unowned Gtk.Label submission_feature_type;

    [GtkChild]
    private unowned Gtk.Image submission_submitter;

    [GtkChild]
    private unowned Gtk.Label submission_name;

    [GtkChild]
    private unowned Gtk.Label submission_caption;

    public int64 submission_id;
    public SubmissionType? submission_type;

    private Cancellable cancellable = new Cancellable ();

    private void on_destroy () {
        cancellable.cancel ();
    }


    public TopSubmission (Json.Object info) {
        Object ();
        destroy.connect (on_destroy);
        
        var motion = new Gtk.EventControllerMotion ();
        motion.enter.connect (on_hover);
        motion.leave.connect (on_hover_lost);
        add_controller (motion);

        var sub_info = info.get_object_member ("_aSubmitter");
        var period = info.get_string_member ("_sPeriod");

        submission_id = info.get_int_member ("_idRow");

        submission_submitter.set_tooltip_text (sub_info.get_string_member ("_sName"));
        submission_feature_type.set_label (capitalize_first (get_formatted_period (period)));
        submission_name.set_label (info.get_string_member ("_sName"));
        if (info.has_member ("_sDescription"))
            submission_caption.set_label (info.get_string_member ("_sDescription"));
        else
            submission_caption.set_visible (false);

        submission_type = SubmissionType.from_string (info.get_string_member ("_sModelName"));

        switch (submission_type) {
            case SubmissionType.NEWS:
            case SubmissionType.WIP:
                open_btt.set_icon_name ("external-link-symbolic");
                break;

            case SubmissionType.MOD:
            case SubmissionType.TOOL:
                open_btt.set_icon_name ("folder-download-symbolic");
                break;
        }

        Vanana.cache_download (info.get_string_member ("_sImageUrl"), set_cover, cancellable);
        Vanana.cache_download (sub_info.get_string_member ("_sAvatarUrl"), set_submitter_pfp, cancellable);
    }

    [GtkCallback]
    private void show_submission_page () {
        Utils.show_submission_page (this, submission_type, submission_id);
    }

    private string get_formatted_period (string period) {
        switch (period) {
            case "today":
                return "today";
            case "week":
                return "this week";
            case "month":
                return "this month";
            case "3month":
                return "this 3 months";
            case "6month":
                return "this 6 months";
            case "year":
                return "this year";
            case "alltime":
                return "all time";
            default:
                warning ("Unknown period: %s", period);
                return "unknown";
        }
    }

    private void on_hover () {
        open_btt.set_visible (true);
    }

    private void on_hover_lost () {
        open_btt.set_visible (false);
    }

    private void set_submitter_pfp (File? pfp) {
        return_if_fail (pfp != null);
        try {
            var texture = Gdk.Texture.from_file (pfp);
            submission_submitter.set_from_paintable (texture);
        } catch (Error e) {
            warning ("Couldn't set submitter profile page: %s", e.message);
            return;
        }
    }

    private void set_cover (File? image) {
        return_if_fail (image != null);
        stack.set_visible_child_name ("main");

        submission_preview.set_file (image);
    }
}
