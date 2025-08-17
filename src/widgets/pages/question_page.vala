
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
    private unowned Gtk.ListBoxRow placeholder_row; // TODO: move this to SubmissionPage when ready to implement comment to all submissions 

    [GtkChild]
    private unowned Gtk.ListBox comment_list; // TODO: move this to SubmissionPage when ready to implement comment to all submissions 

    [GtkChild]
    private unowned Gtk.CenterBox question_state_box;

    [GtkChild]
    private unowned Gtk.Stack comments_stack; // TODO: move this to SubmissionPage when ready to implement comment to all submissions 

    private override Vanana.HtmlView submission_description {get; set;}

    private override Vanana.HtmlView submission_license {get; set;}

    public override SubmissionType? submission_type { get; set; }

    private int current_comments_page = 1;

    private QuestionState state;

    public QuestionPage (int64 id) {
        cancellable = new Cancellable ();
        submission_type = SubmissionType.QUESTION;
        submission_id = id;

        init ();
    }

    public override void populate (Json.Object info) {
        populate_labels (info);

        set_question_data (info);
        show_main (info);

        populate_images (info.get_object_member ("_aPreviewMedia"));

        api.get_posts_feed.begin (SubmissionType.QUESTION, submission_id, 1, PostsFeedSort.POPULAR, (_, res) => {
            try {
                var response = api.get_posts_feed.end (res);
                populate_comments (response);
                //  if (response)
            } catch (Error e) {}
        }); // TODO: move this to SubmissionPage when ready to implement comment to all submissions 
    }

    // TODO: move this to SubmissionPage when ready to implement comments to all submissions 
    private void populate_comments (Json.Object? response) {
        return_if_fail (response != null);

        var records = response.get_array_member ("_aRecords");
        
        if (records.get_length () != 0) {
            placeholder_row.set_visible (false);

            foreach (var item in records.get_elements ()) {
                var post = item.get_object ();
                var post_widget = new Comment (post, false);

                comment_list.append (post_widget);
            }
        }

        comments_stack.set_visible_child_name ("main");
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