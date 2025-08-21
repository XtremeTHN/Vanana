
enum DifficultyLevel {
    BEGINNER,
    INTERMEDIATE,
    ADVANCED;

    public static DifficultyLevel? from_string (string state) {
        switch (state.ascii_down ()) {
            case "beginner":
                return BEGINNER;
            case "intermediate":
                return INTERMEDIATE;
            case "advanced":
                return ADVANCED;
            default:
                message (state);
                return null;
        }
    }
}

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/tutorial-page.ui")]
public class TutorialPage : SubmissionPage {
    [GtkChild]
    private override unowned Gtk.Frame license_frame { get; }

    [GtkChild]
    private override unowned Adw.PreferencesGroup updates_group {get;}

    [GtkChild]
    private override unowned Adw.PreferencesGroup credits_group {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_title {get;}

    [GtkChild]
    private unowned Gtk.Label submission_description {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_caption {get;}

    [GtkChild]
    private override unowned Gtk.Picture submission_icon {get;}

    [GtkChild]
    private override unowned Gtk.Stack submission_icon_stack {get;}

    [GtkChild]
    private override unowned Gtk.Box scrolled_box {get;}
    
    [GtkChild]
    private override unowned Gtk.Stack stack {get;}

    [GtkChild]
    private override unowned Adw.Carousel screenshots_carousel {get;}

    [GtkChild]
    private override unowned Gtk.Label upload_date {get;}

    [GtkChild]
    private override unowned Gtk.Label update_date {get;}

    [GtkChild]
    private override unowned Gtk.Label likes {get;}

    [GtkChild]
    private override unowned Gtk.Label views {get;}

    [GtkChild]
    private override unowned Adw.StatusPage loading_status {get;}

    [GtkChild]
    private override unowned Adw.StatusPage trashed_status {get;}

    [GtkChild]
    private override unowned Gtk.Button open_gb_btt {get;}

    [GtkChild]
    private override unowned Gtk.Button continue_btt {get;}

    [GtkChild]
    private override unowned Adw.StatusPage rating_status {get;}

    [GtkChild]
    private override unowned Adw.CarouselIndicatorDots screenshots_carousel_dots {get;}

    [GtkChild]
    private override unowned Gtk.ListBoxRow comments_placeholder_row {get;} 

    [GtkChild]
    private override unowned Gtk.ListBox comment_list {get;}

    [GtkChild]
    private unowned Gtk.Label difficulty_label;

    [GtkChild]
    private override unowned Gtk.Stack comments_stack {get;}

    [GtkChild]
    private override unowned Gtk.Button load_more_comments_btt {get;}


    private override Vanana.HtmlView submission_text {get; set;}

    public override SubmissionType? submission_type { get; set; }

    public TutorialPage (int64 id) {
        cancellable = new Cancellable ();
        submission_type = SubmissionType.TUTORIAL;
        submission_id = id;
        has_updates = true;
        has_license = true;

        init ();
    }

    public override void populate_extra_widgets (Json.Object info) {
        set_difficulty_level (info);

        if (info.has_member ("_sDescription")) {
            submission_description.set_label (info.get_string_member ("_sDescription"));
        }
    }

    private void set_difficulty_level (Json.Object info) {
        var difficulty = DifficultyLevel.from_string (info.get_string_member ("_akDifficultyLevel"));

        if (difficulty == null) {
            warning ("unknown difficulty");
            return;
        }
        
        switch (difficulty) {
            case DifficultyLevel.BEGINNER:
                difficulty_label.set_label ("Beginner");
                difficulty_label.add_css_class ("green");
                break;
            case DifficultyLevel.INTERMEDIATE:
                difficulty_label.set_label ("Intermediate");
                difficulty_label.add_css_class ("blue");
                break;
            case DifficultyLevel.ADVANCED:
                difficulty_label.set_label ("Advanced");
                difficulty_label.add_css_class ("red");
                break;
        }
    }
}