[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/screenshot.ui")]
public class Screenshot : Gtk.Frame {
    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.Picture pic;

    public bool blur;

    protected override void snapshot (Gtk.Snapshot snap) {
        if (blur)
            snap.push_blur (10);
            
        base.snapshot (snap);

        if (blur)
            snap.pop ();
    }

    public Screenshot () {
        Object ();
    }

    public void set_no_preview () {
        stack.set_visible_child_name ("no-preview");
    }

    public void set_file (File? img) {
        if (img == null) {
            warning ("screenshot file object is null");
            return;
        }
        pic.set_file (img);
        stack.set_visible_child_name ("main");
    }
}
