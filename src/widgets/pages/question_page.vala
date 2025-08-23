
enum QuestionState {
    ANSWERED,
    SOLVED,
    UNANSWERED;

    public static QuestionState? from_string (string state) {
        switch (state.ascii_down ()) {
            case "answered":
                return ANSWERED;
            case "solved":
                return SOLVED;
            case "unanswered":
                return UNANSWERED;
            default:
                return null;
        }
    }
}

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/question-page.ui")]
public class QuestionPage : SubmissionPage {
    [GtkChild]
    private unowned Gtk.Label question_state;

    [GtkChild]
    private unowned Gtk.CenterBox question_state_box;

    public override SubmissionType? submission_type { get; set; }

    private QuestionState state;

    public QuestionPage (int64 id) {
        submission_type = SubmissionType.QUESTION;
        submission_id = id;

        init ();
    }

    public override void populate_extra_widgets (Json.Object info) {
        set_question_data (info);
    }

    private void set_question_data (Json.Object info) {
        state = QuestionState.from_string (info.get_string_member ("_sState"));
        
        switch (state) {
            case QuestionState.SOLVED:
                question_state.set_label ("Solved");
                question_state_box.add_css_class ("green");
                break;
            case QuestionState.ANSWERED:
                question_state.set_label ("Answered but unsolved");
                question_state_box.add_css_class ("blue");
                break;
            case QuestionState.UNANSWERED:
                question_state.set_label ("Unanswered");
                question_state_box.add_css_class ("red");
                break;
        }
    }
}