public class Screenshot : Gtk.Frame {
    private LoadingWidget loader;
    public Gtk.Picture pic;

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

public class ScreenshotView : Adw.Bin{
    public Screenshot widget;

    construct {
        var ovr = new Gtk.Overlay ();

        widget = new Screenshot ();
        ovr.set_child (widget);

        var view_button = new HoverButton ();
        view_button.parent = this;
        view_button.set_css_classes ({"osd", "circular"});
        view_button.set_halign (Gtk.Align.CENTER);
        view_button.set_valign (Gtk.Align.CENTER);

        view_button.set_icon_name ("external-link-symbolic");
        view_button.clicked.connect (on_view_clicked);

        ovr.add_overlay (view_button);

        set_child (ovr);
    }

    void on_view_clicked () {
        var diag = new ImageViewDialog ();
        diag.present (Utils.get_parent_window (this));
        diag.set_from_file (widget.pic.get_file ());
    }
}