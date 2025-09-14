using Soup;
using Utils;

public enum SubmissionType {
    MOD,
    NEWS,
    WIP,
    TOOL,
    QUESTION,
    QUESTIONS,
    TUTORIAL,
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
            case "tutorial":
                return SubmissionType.TUTORIAL;
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
            case TUTORIAL:
                return "Tutorial";
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

namespace Gamebanana.Submissions {
    public async Json.Object? search (string query, SortType sort, int page = 1, Cancellable? cancellable = null) throws Error {
        string method = "/Game/%i/Subfeed?_nPage=%i&_sSort=%s&_sName=%s".printf (GAME_ID, page, sort.to_string().ascii_down (), query);
        var json = yield _get(method, cancellable);
        var obj = json.get_object ();

        warn_if_fail (obj != null); 

        return obj;
    }

    public async Json.Object? get_info (SubmissionType type, int64 id, Cancellable? cancellable = null) throws Error {
        string method = ("/%s/%" + int64.FORMAT + "/ProfilePage").printf (type.to_string(), id);
        var json = yield _get (method, cancellable);
        var obj = json.get_object ();

        warn_if_fail (obj != null);

        if (obj.has_member ("_sErrorMessage")) {
            throw Utils.get_error_from_json(obj);
        }

        return obj;
    }

    private async List<Json.Array> get_all_pages (string method, Cancellable? cancellable = null) throws Error {
        var _results = new List<Json.Array> ();
        int page = 1;

        while (true) {
            string _method = method.printf (page);
            var json = yield _get (_method, cancellable);
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

    public async List<Json.Array> get_updates(SubmissionType type, int64 id, Cancellable? cancellable = null) throws Error {
        string method = "/" + type.to_string () + "/" + id.to_string () + "/Updates?_nPage=%i_nPerpage=10";

        return yield get_all_pages (method, cancellable);
    }

    public async Json.Array? get_top (Cancellable? cancellable = null) throws Error {
        string method = "/Game/%i/TopSubs".printf (GAME_ID);
        var json = yield _get (method, cancellable);
        var obj = json.get_array ();

        warn_if_fail (obj != null);
        return obj;
    }

    public async Json.Object? get_featured (int page = 1, Cancellable? cancellable = null) throws Error {
        string method = "/Util/List/Featured?_nPage=%i&_idGameRow=%i".printf (page, GAME_ID);
        var json = yield _get (method, cancellable);
        var obj = json.get_object ();

        warn_if_fail (obj != null);

        return obj;
    }

    public async Json.Object? get_posts_feed (SubmissionType type, int64 id, int page = 1, Cancellable? cancellable = null, PostsFeedSort sort = PostsFeedSort.NEWEST) throws Error {
        string method = "/%s/%s/Posts?_nPage=%i&_nPerpage=5&_sSort=%s".printf(type.to_string (), id.to_string (), page, sort.to_string ());

        var json = yield _get (method, cancellable);
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
    public async List<Json.Array> get_post_replies (int64 post_id, int page = 1, Cancellable? cancellable = null) throws Error {
        string method = "/Post/" + post_id.to_string () + "/Posts?_nPage=%i&_nPerpage=5";
        return yield get_all_pages (method, cancellable);
    }
}