using Utils;

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/downloadable-page.ui")]
public class DownloadablePage : DownloadableSubmissionPage {
    [GtkChild]
    private override unowned Adw.PreferencesGroup updates_group {get;}

    [GtkChild]
    private override unowned Adw.PreferencesGroup credits_group {get;}

    [GtkChild]
    private override unowned Gtk.Picture submission_icon {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_title {get;}

    [GtkChild]
    private override unowned Gtk.Label submission_caption {get;}

    [GtkChild]
    private override unowned Gtk.ScrolledWindow scrolled_html {get;}
    
    [GtkChild]
    private override unowned Gtk.Stack stack {get;}

    [GtkChild]
    private override unowned Gtk.Stack submission_icon_stack {get;}

    [GtkChild]
    private override unowned Adw.Carousel screenshots_carousel {get;}

    [GtkChild]
    private override unowned Adw.CarouselIndicatorDots screenshots_carousel_dots {get;}

    [GtkChild]
    private override unowned Gtk.Label upload_date {get;}

    [GtkChild]
    private override unowned Gtk.Label update_date {get;}

    [GtkChild]
    private override unowned Gtk.Label likes {get;}

    [GtkChild]
    private override unowned Gtk.Label views {get;}

    [GtkChild]
    private override unowned Gtk.Button continue_btt {get;}

    [GtkChild]
    private override unowned Gtk.Label downloads {get;}

    [GtkChild]
    private override unowned Adw.StatusPage loading_status {get;}

    [GtkChild]
    private override unowned Adw.StatusPage trashed_status {get;}

    [GtkChild]
    private override unowned Gtk.Frame license_frame {get;}

    [GtkChild]
    private override unowned Gtk.Button open_gb_btt {get;}

    [GtkChild]
    private override unowned Gtk.Button download_btt {get;}

    [GtkChild]
    private override unowned Adw.StatusPage rating_status {get;}

    [GtkChild]
    private override unowned Gtk.Stack comments_stack {get;}

    [GtkChild]
    private override unowned Gtk.ListBoxRow comments_placeholder_row {get;} 
    
    [GtkChild]
    private override unowned Gtk.ListBox comment_list {get;}

    [GtkChild]
    private override unowned Gtk.Button load_more_comments_btt {get;}

    private override Vanana.HtmlView submission_description {get; set;}
    private override Vanana.HtmlView submission_license {get; set;}

    public override SubmissionType? submission_type { get; set; }

    public DownloadablePage (SubmissionType type, int64 id) {
        Object ();

        submission_type = type;
        submission_id = id;

        init ();    
    }
}