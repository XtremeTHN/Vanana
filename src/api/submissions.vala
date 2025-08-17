using Soup;
using Utils;

public enum SubmissionType {
    MOD,
    NEWS,
    WIP,
    TOOL,
    QUESTION,
    QUESTIONS,
    UNKNOWN;

    public static SubmissionType? from_string (string value) {
        switch (value.ascii_down ()) {
            case "mod":
                return SubmissionType.MOD;
            case "news":
                return SubmissionType.NEWS;
            case "wip":
                return SubmissionType.WIP;
            case "tool":
                return SubmissionType.TOOL;
            case "question":
                return SubmissionType.QUESTION;
            default:
                return SubmissionType.UNKNOWN;
        }
    }

    public string to_string () {
        switch (this) {
            case MOD:
                return "Mod";
            case NEWS:
                return "News";
            case WIP:
                return "Wip";
            case TOOL:
                return "Tool";
            case QUESTION:
                return "Question";
            case QUESTIONS:
                return "Questions";
            default:
                return "Unknown";
        }
    }
}

public enum SortType {
    NEW,
    DEFAULT,
    UPDATED;

    public string to_string () {
        switch (this) {
            case SortType.NEW:
                return "new";
            case SortType.DEFAULT:
                return "default";
            case SortType.UPDATED:
                return "updated";
            default:
                return "default";
        }
    }
}

public enum PostsFeedSort {
    POPULAR,
    NEWEST;

    public string? to_string () {
        switch (this) {
            case POPULAR:
                return "popular";
            case NEWEST:
                return "newest";
            default:
                return null;
        }
    }
}

[SingleInstance]
public class Gamebanana.Submissions : Object {
    Session s_session;

    public Submissions () {
        Object ();

        s_session = new Session.with_options ("max_conns", 30, "timeout", 5);
    }

    private async Json.Node request (Soup.Message msg) throws Error {
        var stream = yield s_session.send_async (msg, Priority.DEFAULT, null);
        var parser = new Json.Parser ();
        yield parser.load_from_stream_async (stream, null);

        return parser.get_root ();
    }

    private async Json.Node _get (string url) throws Error {
        int retries = 0;

        try {
            return yield request (new Soup.Message ("GET", GB_API + url));
        } catch (Error e) {
            if (e.message == "Socket I/O timed out") {
                if (retries != 3) {
                    retries += 1;
                    return yield request (new Soup.Message ("GET", GB_API + url));
                }
                warning ("max retries reached");
            }

            throw e;
        }

    }

    public async Json.Object? search (string query, SortType sort, int page = 1) throws Error {
        string method = "/Game/%i/Subfeed?_nPage=%i&_sSort=%s&_sName=%s".printf (GAME_ID, page, sort.to_string().ascii_down (), query);
        var json = yield _get(method);
        var obj = json.get_object ();

        warn_if_fail (obj != null); 

        return obj;
    }

    public async Json.Object? get_info (SubmissionType type, int64 id) throws Error {
        string method = ("/%s/%" + int64.FORMAT + "/ProfilePage").printf (type.to_string(), id);
        var json = yield _get (method);
        var obj = json.get_object ();

        warn_if_fail (obj != null);

        if (obj.has_member ("_sErrorMessage")) {
            throw new Error (Quark.from_string (obj.get_string_member ("_sErrorCode")), 1, obj.get_string_member ("_sErrorMessage"));
        }

        return obj;
    }

    public async List<Json.Array> get_updates(SubmissionType type, int64 id) throws Error {
        var _results = new List<Json.Array> ();
        int page = 1;

        while (true) {
            string method = "/%s/%"+ int64.FORMAT +"/Updates?_nPage=%i&_nPerpage=10";
            var json = yield _get (method.printf(type.to_string (), id, page));
            var obj = json.get_object ();

            assert_nonnull (obj);

            if (obj.has_member ("_sErrorMessage")) {
                warning ("Error recieved from api: %s", obj.get_string_member ("_sErrorMessage"));
                return _results;
            }

            var meta = obj.get_object_member ("_aMetadata");
            bool completed = meta.get_boolean_member ("_bIsComplete");

            if (obj.has_member ("_aRecords"))
                _results.append (obj.get_array_member ("_aRecords"));

            if (completed)
                break;

            page += 1;
        }

        return _results;
    }

    public async Json.Array? get_top () throws Error {
        string method = "/Game/%i/TopSubs".printf (GAME_ID);
        var json = yield _get (method);
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

    public async Json.Object? get_posts_feed (SubmissionType type, int64 id, int page = 1, PostsFeedSort sort = PostsFeedSort.NEWEST) throws Error {
        string method = "/%s/%s/Posts?_nPage=%i&_nPerpage=5&_sSort=%s".printf(type.to_string (), id.to_string (), page, sort.to_string ());

        var json = yield _get (method);
        var obj = json.get_object ();
        warn_if_fail (obj != null);

        return obj;
    }

    /**
     * Undocumented api method.
     * Returns a paged response, with an array of post objects.
     * Relevant members:
     *  - _sText
     *  - _tsDateAdded and _tsDateModified
     *  - _nReplyCount
     *  - _aPoster : GenericProfile (Banana type name)
     *  - _aAccess : Json.Object
     *      - Post_Trash
     *      - Post_Edit
     *      - Post_Reply
     */
    public async Json.Object get_post_replies (int64 post_id, int page = 1) throws Error {
        string method = "/Post/%s/Posts?_nPage=%i&_nPerpage=5".printf (post_id.to_string (), page);
        var json = yield _get (method);
        var obj = json.get_object ();
        warn_if_fail (obj != null);

        return obj;
    }
}