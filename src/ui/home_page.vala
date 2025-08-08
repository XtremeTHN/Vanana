
[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/home-page.ui")]
public class Home.Page : Adw.Bin {
    [GtkChild]
    private unowned Adw.NavigationView nav_view;

    [GtkChild]
    private unowned Gtk.SearchBar search_bar;

    [GtkChild]
    private unowned Gtk.SearchEntry search_entry;

    [GtkChild]
    private unowned Gtk.Stack stack;

    //  [GtkChild]
    //  private unowned HomePage home_page;

    //  [GtkChild]
    //  private unowned SearchPage search_page;

    //  [GtkChild]
    //  private unowned DownloadsPage down_page;

    [GtkCallback]
    public void on_downloads_clicked () {
        
    }

    [GtkCallback]
    public void on_search_btt_clicked () {}

    [GtkCallback]
    public void on_search_changed () {}

    public Window () {
        Object ();

        search_entry.set_key_capture_widget (this);
        present ();
    }
}