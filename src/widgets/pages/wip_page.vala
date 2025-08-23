[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/wip-page.ui")]
public class WipPage : SubmissionPage {
    [GtkChild]
    private unowned Gtk.Label completed_progress_label;

    [GtkChild]
    private unowned Gtk.LevelBar completed_progress;
    
    public override SubmissionType? submission_type { get; set; }

    public WipPage (int64 id) {
        submission_type = SubmissionType.WIP;
        submission_id = id;

        init ();
    }

    public override void populate_extra_widgets (Json.Object info) {
        completed_progress_label.label = "%s - %%%s finished".printf (
            info.get_string_member ("_sDevelopmentState"),
            info.get_int_member ("_iCompletionPercentage").to_string ()
        );
        completed_progress.set_value (
            info.get_int_member ("_iCompletionPercentage")
        );
    }
}