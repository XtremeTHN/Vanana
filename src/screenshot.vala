[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/screenshot.ui")]
public class Screenshot : Gtk.Frame {
    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.Picture pic;

    public Screenshot () {
        Object ();
    }

    public void set_file (File? img) {
        if (img == null) {
            warning ("screenshot file object is null");
            return;
        }
        Idle.add (() => {
            pic.set_file (img);
            return false;
        }, Priority.DEFAULT);
        stack.set_visible_child_name ("main");
    }
}