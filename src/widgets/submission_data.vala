public class SubmissionData : Object {

    private Json.Object? info;

    public Json.Object? preview {
        get {
            return info.get_object_member ("_aPreviewMedia");
        }
    }

    public bool should_blur {
        get {
            return info.get_string_member ("_sInitialVisibility") != "show";
        }
    }

    public bool has_preview { get; set; }

    public File? cover { get; set; }
    public string name {
        get {
            return info.get_string_member ("_sName");
        }
    }

    public string sub_type {
        get {
            return info.get_string_member ("_sModelName");
        }
    }

    private string __upload_date;
    public string upload_date {
        get {
            __upload_date = Utils.format_relative_time (info.get_int_member ("_tsDateAdded"));
            return __upload_date;
        }
    }

    private string __update_date;
    public string update_date {
        get {
            __update_date = Utils.format_relative_time (info.get_int_member ("_tsDateModified"));
            return __update_date;
        }
    }

    private string __likes;
    public string likes {
        get {
            __likes = info.get_int_member ("_nLikeCount").to_string ();
            return __likes;
        }
    }

    private string __views;
    public string views {
        get {
            __views = info.get_int_member ("_nViewCount").to_string ();
            return __views;
        }
    }

    private void set_file (File? f) {
        cover = f;
    }

    public SubmissionData (Json.Object? info) {
        Object ();
        this.info = info;

        if (preview.has_member ("_aImages")) {
            var images = preview.get_array_member ("_aImages");
            var first_image = images.get_element (0).get_object ();

            Vanana.cache_download (Utils.build_image_url (first_image, Utils.ImageQuality.MEDIUM), set_file, null);
            has_preview = true;
        } else {
            has_preview = false;
        }
    }
}