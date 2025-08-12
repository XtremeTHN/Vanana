[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/window.ui")]
public class Vanana.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ToastOverlay toast_ovr;

    [GtkChild]
    private unowned Adw.OverlaySplitView split_view;

    [GtkChild]
    private unowned Adw.NavigationView navigation_view;

    public Window (Vanana.Application app) {
        Object ();
        get_type ().ensure ();

        app.create_action ("toggle-sidebar").activate.connect (toggle_sidebar);
        app.create_action ("message", new VariantType ("s")).activate.connect (show_message);
        
        split_view.set_sidebar (new Sidebar ());

        navigation_view.add (new HomePage ());
    }

    private void show_message (Variant? param) {
        var toast = new Adw.Toast (param.get_string ());
        toast_ovr.add_toast (toast);
    }

    private void toggle_sidebar (Variant? _) {
        split_view.set_show_sidebar(!split_view.show_sidebar);
    }
}