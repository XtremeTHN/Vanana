[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/screenshot.ui")]
public abstract class ScreenshotWidget : Gtk.Frame {
    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.Picture pic;

    public Gtk.ContentFit content_fit {
        set {
            pic.set_content_fit (value);
        }
    }

    public bool blur;


    protected override void snapshot (Gtk.Snapshot snap) {
        if (blur)
            snap.push_blur (10);
            
        base.snapshot (snap);

        if (blur)
            snap.pop ();
    }

    public void set_no_preview () {
        stack.set_visible_child_name ("no-preview");
    }

    public void set_file (File? img) {
        if (img == null) {
            stack.set_visible_child_name ("no-preview");
            return;
        }
        pic.set_file (img);
        stack.set_visible_child_name ("main");
    }
}


public class Screenshot : ScreenshotWidget {
    public Screenshot () {
        Object ();
    }
}