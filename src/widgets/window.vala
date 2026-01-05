[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/window.ui")]
public class Vanana.Window : Adw.ApplicationWindow {
    [GtkChild]
    private unowned Adw.ToastOverlay toast_ovr;

    [GtkChild]
    private unowned Adw.OverlaySplitView split_view;

    [GtkChild]
    public unowned Adw.NavigationView navigation_view;

    EngineDownloadsDialog engine_down_diag;

    public Window (Vanana.Application app) {
        Object ();
        var home = new HomePage (navigation_view);
        engine_down_diag = new EngineDownloadsDialog ();

        app.create_action ("toggle-sidebar").activate.connect (toggle_sidebar);
        app.create_action ("toggle-search").activate.connect (home.toggle_search_bar);
        app.create_action ("show-engines").activate.connect (show_engines);

        home.search_bar.set_key_capture_widget (this);

        split_view.set_sidebar (new Sidebar ());

        navigation_view.add (home);
    }

    void show_engines (Variant? _) {
        engine_down_diag.present (this);
    }
 
    public void show_message (string msg) {
        var toast = new Adw.Toast (msg);
        toast_ovr.add_toast (toast);
    }

    private void toggle_sidebar (Variant? _) {
        split_view.set_show_sidebar (!split_view.show_sidebar);
    }
}