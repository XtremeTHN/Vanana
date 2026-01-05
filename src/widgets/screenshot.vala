public class Screenshot : Gtk.Frame {
    private LoadingWidget loader;
    private Gtk.Picture pic;

    public Gtk.ContentFit content_fit {
        set {
            pic.set_content_fit (value);
        }
    }

    public bool blur;

    construct {
        loader = new LoadingWidget ();
        pic = new Gtk.Picture ();
        pic.set_content_fit (Gtk.ContentFit.COVER);

        loader.placeholder_title = "No preview";
        loader.content = pic;
        set_child (loader);
    }

    protected override void snapshot (Gtk.Snapshot snap) {
        if (blur)
            snap.push_blur (10);
            
        base.snapshot (snap);

        if (blur)
            snap.pop ();
    }

    public void set_no_preview () {
        loader.finish_with_error ();
    }

    public void set_file (File? img) {
        if (img == null) {
            loader.finish_with_error ();
            return;
        }

        pic.set_file (img);
        loader.finish_loading ();
    }
}