namespace Github {
    const string GITHUB_API = "https://api.github.com";
    
    public async Json.Array? get_releases (string owner, string repo) throws Error {
        var rq = new Requests ();
        rq.create_session ();
        rq.s_session.user_agent = "Vanana-App-XtremeTHN";
        
        var json = yield rq.fetch_json ("%s/repos/%s/%s/releases".printf (GITHUB_API, owner, repo), null);
        return json.get_array ();
    }
}