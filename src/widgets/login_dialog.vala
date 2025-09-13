[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/login.ui")]
public class LoginDialog : Adw.Dialog {
    [GtkChild]
    private unowned Adw.EntryRow username_entry;

    [GtkChild]
    private unowned Adw.PasswordEntryRow password_entry;

    [GtkChild]
    private unowned Adw.ButtonRow us_log_btt;

    [GtkChild]
    private unowned Gtk.Revealer error_revealer;

    [GtkChild]
    private unowned Gtk.Label error_label;

    [GtkChild]
    private unowned Adw.EntryRow email_entry;

    [GtkChild]
    private unowned Adw.EntryRow code_row;

    public LoginDialog () {
        Object ();
    }

    [GtkCallback]
    private void login_with_username () {
        var user = username_entry.get_text ();
        var pass = password_entry.get_text ();

        us_log_btt.set_sensitive (false);
        Gamebanana.login.begin (user, pass, null, (_, res) => {
            try {
                Gamebanana.login.end(res);
            } catch (Error e) {
                error_revealer.set_reveal_child (true);
                error_label.set_label ("%s: %s".printf (e.domain.to_string (), e.message));
            }

            us_log_btt.set_sensitive (true);
        });
    }

    [GtkCallback]
    private void send_code () {}

    [GtkCallback]
    private void submit_code () {}

    [GtkCallback]
    private void close_diag () {
        close ();
    }
}