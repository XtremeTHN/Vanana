
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
    private unowned Gtk.Label difficulty_label;
    
    public override SubmissionType? submission_type { get; set; }

    public TutorialPage (int64 id) {
        submission_type = SubmissionType.TUTORIAL;
        submission_id = id;

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