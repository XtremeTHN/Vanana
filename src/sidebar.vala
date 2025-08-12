[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/sidebar.ui")]
public class Vanana.Sidebar : Adw.NavigationPage {
    [GtkChild]
    private unowned Gtk.Button stop_all_btt;

    [GtkChild]
    private unowned Gtk.Stack stack;

    [GtkChild]
    private unowned Gtk.ListBox downloads_box;

    public Sidebar () {
        Object ();

    }
}