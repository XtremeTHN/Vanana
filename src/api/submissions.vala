using Soup;

enum SubmissionType {
    MOD = "Mod",
    NEWS = "News",
    WIP = "Wip"
}

class Gamebanana.Submissions {
    Session s_session = new Session ();

    construct {}

    //  async Bytes? _get (string url) {
    //      var msg = new Soup.Message ("GET", url);
    //      var s = s_session.send_and_read_async (msg, 1, new Cancellable ());
    //  }

    async void query () {}

    async void get_info (SubmissionType type, int id) {}

    async void get_updates(SubmissionType type, int id) {}

    async void get_top() {}

    async void get_featured (int page = 1) {
        string method = "/Util/List/Featured?_nPage=%s&_idGameRow=%s".printf (page.to_string (), GAME_ID.to_string());
        var msg = new Soup.Message (
            "GET",
            GB_API
        );
        try {
            var cnts = yield s_session.send_and_read_async (msg, 1, null);
        } catch (Error e) {

        }
        //  get_session ().send_and_read_async (msg, , GLib.Cancellable? cancellable)
    }
}