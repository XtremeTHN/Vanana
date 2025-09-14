[SingleInstance]
public class Gamebanana.CurrentUser : Object {
    public string user_name {get; set;}
    public int64 user_id {get; set;}
    public File? pfp {get; set;}

    public Json.Object? user_info;
    private Settings settings; 

    public CurrentUser () {
        Object ();

        settings = new Settings ("com.github.XtremeTHN.Vanana");

        settings.bind ("user-id", this, "user_id", GLib.SettingsBindFlags.SET);
        var conf_user_id = settings.get_int64 ("user-id");
        if (conf_user_id > 0)
            set_user.begin (user_id);
    }

    public async void set_user (int64 id) throws Error {
        var res = yield _get ("/Member/" + id.to_string () + "/ProfilePage", null);
        user_info = res.get_object ();

        warn_if_fail (user_info != null);

        if (user_info.has_member ("_sErrorMessage"))
            throw Utils.get_error_from_json (user_info);

        user_id = user_info.get_int_member ("_idRow");
        user_name = user_info.get_string_member ("_sName");

        
        //  var prev_media = user_info.get_object_member ("_aPreviewMedia");

        //  foreach (var elem in prev_media.get_members ()) {
        //      var item = prev_media.get_object_member (elem);
        //      if (item.get_string_member ("_sType") == "avatar") {
        //          Vanana.cache_download (item.get_string_member ("_sUrl"), _set_pfp, new Cancellable ());
        //      }
        //  }
    }

    private void _set_pfp (File? pfp) {
        return_if_fail (pfp != null);

        this.pfp = pfp;
    }
}