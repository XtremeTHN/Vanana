using Soup;

namespace Gamebanana {
    int GAME_ID = 8694;
    const string GB_API = "https://gamebanana.com/apiv11";
    public Session? gb_session;

    errordomain LoginErrors {
        MUST_BE_GUEST,
        INVALID_PASSWORD,
        INVALID_USER,
        UNKNOWN
    }

    public Session? get_session () {
        if (gb_session == null) {
            // user agent fixes the need of a recaptcha when logging
            gb_session = new Session.with_options ("max_conns", 30, "timeout", 5, "user_agent", "Mozilla/5.0 (X11; Linux x86_64; rv:142.0) Gecko/20100101 Firefox/142.0");
            var cookie_man = new CookieJarDB ("vanana_xd", false);
            gb_session.add_feature (cookie_man);
        }

        return gb_session;
    }

    private async Json.Node request (Soup.Message msg, Cancellable? cancellable) throws Error {
        var stream = yield get_session ().send_async (msg, Priority.DEFAULT, cancellable);
        var parser = new Json.Parser ();
        yield parser.load_from_stream_async (stream, cancellable);

        return parser.get_root ();
    }


    /**
     * Authenticates a user with the GameBanana API using the provided username and password.
     *
     * Sends a JSON request to the API endpoint to verify the user's credentials.
     * Throws specific LoginErrors based on the error code or error data returned by the API:
     *   - LoginErrors.MUST_BE_GUEST: If the user must be a guest to authenticate.
     *   - LoginErrors.INVALID_USER: If the username does not exist.
     *   - LoginErrors.INVALID_PASSWORD: If the password is invalid.
     *   - LoginErrors.UNKNOWN: For any other error codes returned by the API.
     *
     * It should return a json object with this body:
     *  "_sStatus": string
     *  "_idRow": int64 (the id of the user)
     *  "_sUsername": string
     *
     * @param user The username to authenticate.
     * @param password The password for the given username.
     * @param cancellable Optional Cancellable object to cancel the operation.
     *
     * @return Json.Object The JSON response object from the API if authentication is successful.
     * @throws Error If a network or API error occurs, or if authentication fails.
     */
    public async Json.Object login (string user, string password, Cancellable? cancellable) throws Error {
        message (GB_API + "/Member/Authenticate");
        var msg = new Message ("POST", GB_API + "/Member/Authenticate");
        
        string body = "{\"_sUsername\": \"%s\", \"_sPassword\": \"%s\"}".printf (user, password);
        var encoded = new Bytes (body.data);
        msg.set_request_body_from_bytes ("application/json", encoded);

        var response = yield request (msg, cancellable);

        var json_res = response.get_object ();

        if (json_res.has_member ("_sErrorCode")) {
            var err_code = json_res.get_string_member ("_sErrorCode");
            if (json_res.has_member ("_sErrorMessage")) 
                throw new LoginErrors.UNKNOWN (json_res.get_string_member ("_sErrorMessage"));

            var err_data = json_res.get_object_member ("_aErrorData");

            if (err_data.has_member ("_sUsername")) {
                throw new LoginErrors.INVALID_USER ("This account doesn't exists");
            }

            if (err_data.has_member ("_sPassword")) {
                throw new LoginErrors.INVALID_PASSWORD ("Password was invalid");
            }

            throw new LoginErrors.UNKNOWN (err_code);
        }

        return json_res;
    }
}