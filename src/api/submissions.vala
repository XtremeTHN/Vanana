using Soup;

enum SubmissionType {
    MOD,
    NEWS,
    WIP
}

enum SortType {
    NEW,
    DEFAULT,
    UPDATED
}

class Gamebanana.Submissions : Object {
    Session s_session;

    public Submissions () {
        Object ();

        s_session = new Session ();
    }

    private async Json.Node _get (string url) throws Error {
        var msg = new Soup.Message ("GET", GB_API + url);
        var stream = yield s_session.send_async (msg, Priority.DEFAULT, null);

        var parser = new Json.Parser ();
        yield parser.load_from_stream_async (stream, null);

        return parser.get_root ();
    }

    public async Json.Object? search (string query, SortType sort, int page = 1) throws Error {
        string method = "/Game/%i/Subfeed?_nPage=%i&_sSort=%s&_sName=%s".printf (GAME_ID, page, sort.to_string(), query);
        var json = yield _get(method);
        var obj = json.get_object ();

        warn_if_fail (obj != null); 

        return obj;
    }

    public async Json.Object? get_info (SubmissionType type, int id) throws Error {
        string method = "/%s/%i/ProfilePage".printf (type.to_string(), id);
        var json = yield _get (method);
        var obj = json.get_object ();

        warn_if_fail (obj != null);

        return obj;
    }

    public async PtrArray get_updates(SubmissionType type, int id) throws Error {
        var _results = new PtrArray ();
        int page = 1;

        while (true) {
            string method = "/%s/%i/ProfilePage";
            var json = yield _get (method.printf(type.to_string(), page));
            var obj = json.get_object ();

            assert_nonnull (obj);

            var meta = obj.get_object_member ("_aMetadata");
            bool completed = meta.get_boolean_member ("_bIsComplete");

            if (completed) {
                break;
            };

            _results.add (obj.get_array_member ("_aRecords"));

            page += 1;
        }

        return _results;
    }

    public async Json.Array? get_top() throws Error {
        string method = "/Game/%i/TopSubs".printf (GAME_ID);
        var json = yield _get (method);
        print("%s\n", json.get_node_type ().to_string ());
        var obj = json.get_array ();

        warn_if_fail (obj != null);
        return obj;
    }

    public async Json.Object? get_featured (int page = 1) throws Error {
        string method = "/Util/List/Featured?_nPage=%i&_idGameRow=%i".printf (page, GAME_ID);
        var json = yield _get (method);
        var obj = json.get_object ();

        warn_if_fail (obj != null);

        return obj;
    }
}