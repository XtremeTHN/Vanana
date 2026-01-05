public class Requests {
    public Soup.Session? s_session;

    public void create_session () {
        if (s_session != null)
            s_session = null;
        
        s_session = new Soup.Session.with_options ("max_conns", 30, "timeout", 5);
    }

    public async Json.Node request (Soup.Message msg, Cancellable? cancellable) throws Error {
        var stream = yield s_session.send_async (msg, Priority.DEFAULT, cancellable);
    
        var parser = new Json.Parser ();
        yield parser.load_from_stream_async (stream, cancellable);

        return parser.get_root ();
    }

    public async Json.Node fetch_json (string url, Cancellable? cancellable) throws Error {
        int retries = 0;

        try {
            return yield request (new Soup.Message ("GET", url), cancellable);
        } catch (Error e) {
            if (e.message == "Socket I/O timed out") {
                if (retries != 3) {
                    retries += 1;
                    return yield request (new Soup.Message ("GET", url), cancellable);
                }
                warning ("max retries reached");
            }

            throw e;
        }
    }
}