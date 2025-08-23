using Utils;

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/downloadable-page.ui")]
public class DownloadablePage : DownloadableSubmissionPage {
    [GtkChild]
    private override unowned Gtk.Label downloads {get;}

    [GtkChild]
    private override unowned Gtk.Button download_btt {get;}

    public override SubmissionType? submission_type { get; set; }

    public DownloadablePage (SubmissionType type, int64 id) {
        Object ();

        submission_type = type;
        submission_id = id;
        init ();    
    }
}