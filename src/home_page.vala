[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/home-page.ui")]
public class HomePage : Adw.NavigationPage {
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Adw.StatusPage loading_page;

    [GtkChild]
    private unowned Adw.Carousel top_submissions;

    [GtkChild]
    private unowned Gtk.ListBox submission_list;

    [GtkChild]
    private unowned Gtk.Button load_btt;

    public int current_page = 1;

    public HomePage () {
        Object ();

        var spin = new Adw.SpinnerPaintable (loading_page);
        loading_page.set_paintable (spin);
        var api = new Gamebanana.Submissions ();

        api.get_top.begin ((obj, res) => {
            try {
                var subs = api.get_top.end(res);
                populate_carousel (subs);
            } catch (Error e) {
                warning ("Couldn't populate the submission carousel: %s", e.message);
            }
        });

        api.get_featured.begin (current_page, (obj, res) => {
            try {
                var subs = api.get_featured.end (res);
                return_if_fail (subs.has_member ("_aRecords"));

                populate_submission_list (subs.get_array_member ("_aRecords"));
            } catch (Error e) {
                warning ("Couldn't populate the submission list: %s", e.message);
            }
        });
    }

    [GtkCallback]
    private void on_search_changed () {
        var query = search_entry.get_text ();
        if (query.length != 0) {
            top_submissions.set_visible (false);
            return;
        }
        // TODO: implement search
    }

    [GtkCallback]
    private void on_load_clicked () {}

    private void populate_carousel (Json.Array? submissions) {
        foreach (var sub in submissions.get_elements ()) {
            var top = new TopSubmission (sub.get_object ());
            top_submissions.append (top);
        }

        stack.set_visible_child_name ("main");
    }

    private void populate_submission_list (Json.Array? submissions) {
        foreach (var sub in submissions.get_elements ()) {
            var top = new SubmissionItem (sub.get_object ());
            submission_list.append (top);
        }
    }
}