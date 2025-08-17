
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
    private override unowned Gtk.Label submission_title {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_caption {get;}

    [GtkChild]
    private override unowned Gtk.Picture submission_icon {get;}

    [GtkChild]
    private override unowned Gtk.Stack submission_icon_stack {get;}

    [GtkChild]
    private override unowned Gtk.ScrolledWindow scrolled_html {get;}
    
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
    private unowned Gtk.Label question_state;

    [GtkChild]
    private override unowned Gtk.ListBoxRow comments_placeholder_row {get;} 

    [GtkChild]
    private override unowned Gtk.ListBox comment_list {get;}

    [GtkChild]
    private unowned Gtk.CenterBox question_state_box;

    [GtkChild]
    private override unowned Gtk.Stack comments_stack {get;}

    [GtkChild]
    private override unowned Gtk.Button load_more_comments_btt {get;}

    private override Vanana.HtmlView submission_description {get; set;}

    private override Vanana.HtmlView submission_license {get; set;}

    public override SubmissionType? submission_type { get; set; }

    private QuestionState state;

    public QuestionPage (int64 id) {
        cancellable = new Cancellable ();
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