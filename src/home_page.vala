[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/home-page.ui")]
public class HomePage : Adw.NavigationPage {
    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    [GtkChild]
    public unowned Gtk.SearchBar search_bar;

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

    private Gamebanana.Submissions api;
    public int current_page = 1;

    public HomePage () {
        Object ();

        var spin = new Adw.SpinnerPaintable (loading_page);
        loading_page.set_paintable (spin);
        api = new Gamebanana.Submissions ();

        api.get_top.begin ((obj, res) => {
            try {
                var subs = api.get_top.end (res);
                populate_carousel (subs);
            } catch (Error e) {
                warning ("Couldn't populate the submission carousel: %s", e.message);
            }
        });
    }

    public void toggle_searchbar () {
        search_bar.set_search_mode (!search_bar.search_mode_enabled);
    }

    private void request_featured_submissions (bool remove_all = true) {
        if (remove_all) {
            current_page = 1;
            submission_list.remove_all ();
        }

        api.get_featured.begin (current_page, (obj, res) => {
            try {
                var subs = api.get_featured.end (res);
                return_if_fail (subs.has_member ("_aRecords"));

                populate_submission_list (subs);
            } catch (Error e) {
                warning ("Couldn't populate the submission list: %s", e.message);
            }
        });
    }

    private void search (string query, bool remove_all = true) {
        api.search.begin (query, SortType.DEFAULT, current_page, (obj, res) => {
            try {
                var response = api.search.end (res);
                populate_search (response, remove_all);

            } catch (Error e) {
                warning ("Error while querying submissions: %s", e.message);
            }
        });
    }

    [GtkCallback]
    private void on_search_changed () {
        var query = search_entry.get_text ();

        if (query.length == 0) {
            current_page = 1;
            if (stack.get_visible_child_name () != "main") {
                stack.set_visible_child_name ("main");
            }

            top_submissions.set_visible (true);
            request_featured_submissions ();
            return;
        }

        if (query.length > 0) {
            top_submissions.set_visible (false);
        }

        if (query.length < 3) {
            stack.set_visible_child_name ("too-short");
            return;
        }

        current_page = 1;
        stack.set_visible_child_name ("loading");
        search (query);
    }

    [GtkCallback]
    private void on_load_clicked () {
        current_page += 1;

        // in search mode
        if (search_entry.text.length > 0) {
            search (search_entry.text, false);
        } else { // normal mode
            request_featured_submissions (false);
        }

    }

    private void populate_search (Json.Object? response, bool remove_all) {
        if (response == null) {
            warning ("query response is null");
            return;
        }
        var metadata = response.get_object_member ("_aMetadata");

        if (metadata == null) {
            warning ("metadata is null");
            return;
        }

        var submissions = response.get_array_member ("_aRecords");

        if (submissions.get_length () == 0) {
            stack.set_visible_child_name ("no-results");
            return;
        }

        load_btt.set_sensitive (!metadata.get_boolean_member_with_default ("_bIsComplete", true));

        if (remove_all)
            submission_list.remove_all ();

        foreach (var item in submissions.get_elements ()) {
            var sub = item.get_object ();

            var widget = new SubmissionItem (sub);
            submission_list.append (widget);
        }

        stack.set_visible_child_name ("main");
    }

    private void populate_carousel (Json.Array? submissions) {
        foreach (var sub in submissions.get_elements ()) {
            var top = new TopSubmission (sub.get_object ());
            top_submissions.append (top);
        }

        stack.set_visible_child_name ("main");
    }

    private void populate_submission_list (Json.Object? response) {
        var metadata = response.get_object_member ("_aMetadata");
        load_btt.set_sensitive (!metadata.get_boolean_member_with_default ("_bIsComplete", true));

        var submissions = response.get_array_member ("_aRecords");
        foreach (var sub in submissions.get_elements ()) {
            var top = new SubmissionItem (sub.get_object ());
            submission_list.append (top);
        }
    }
}