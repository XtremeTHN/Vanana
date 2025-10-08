[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/loading-btt.ui")]
public class LoadingBtt : Gtk.Button {
    [GtkChild]
    private unowned Gtk.Label lbl;

    [GtkChild]
    private unowned Gtk.Stack stack;

    public new string label {
        set {
            lbl.set_label (value);
        }
    }

    public LoadingBtt () {
        Object ();
    }

    public void set_loading (bool loading) {
        string name;

        if (loading)
            name = "spin";
        else
            name = "icon";

        stack.set_visible_child_name (name);
        set_sensitive (!loading);
    }
}