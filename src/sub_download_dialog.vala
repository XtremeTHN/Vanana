//  public class FileRow : Adw
enum FileRowType {
    FILE,
    ALT
}

private class FileRow : Adw.ActionRow {
    public Json.Object? info {get; set construct;}

    public FileRowType type;

    string file_name;
    string submission_name;

    public FileRow (string submission_name, Json.Object file_info) {
        Object (activatable: true);
        this.submission_name = submission_name;

        if (file_info.has_member ("url") == false) {
            type = FileRowType.FILE;
            info = file_info;

            file_name = file_info.get_string_member ("_sFile");
            set_title (file_name);

            string size = format_size (file_info.get_int_member ("_nFilesize"), FormatSizeFlags.DEFAULT);
            if (file_info.has_member ("_sDescription")) {
                set_subtitle (
                    file_info.get_string_member ("_sDescription") +
                    " (%s)".printf (size)
                );
            } else {
                set_subtitle (size);
            }
        } else {
            type = FileRowType.ALT;
            set_title (file_info.get_string_member ("description"));
            set_subtitle (file_info.get_string_member ("url"));
        }

        activated.connect (on_activate);
    }

    private void on_save_finish (Object? obj, AsyncResult res) {
        if (obj == null)
            return;
        try {
            File path = ((Gtk.FileDialog) obj).save.end (res);
            var man = new DownloadManager ();
            man.add_download (info, path, submission_name);
        } catch (Error e) {
            if ((e is Gtk.DialogError.DISMISSED) == false) {
                Utils.warn (this, "Error while showing save dialog: %s".printf (e.message));
            }
        }
    }

    private void on_activate () {
        var win = (Vanana.Window) get_root ();

        if (type == FileRowType.FILE) {
            var diag = new Gtk.FileDialog ();
            diag.title = info.get_string_member ("_sFile");
            diag.initial_name = file_name;
            diag.initial_folder = File.new_for_path (Environment.get_user_special_dir (UserDirectory.DOWNLOAD));

            diag.save.begin (win, null, on_save_finish);
        } else {
            var launcher = new Gtk.UriLauncher (subtitle);
            launcher.launch.begin (win, null);
        }
    }
}

[GtkTemplate (ui = "/com/github/XtremeTHN/Vanana/download-dialog.ui")]
public class DownloadDialog : Adw.Dialog {
    [GtkChild]
    private unowned Adw.PreferencesGroup files_group;

    [GtkChild]
    private unowned Adw.PreferencesGroup alt_files_group;

    [GtkChild]
    private unowned Adw.PreferencesGroup archived_files_group;

    string submission_name;

    public DownloadDialog (string submission_name, Json.Array? files, Json.Array? alt_files = null, Json.Array? archived_files = null) {
        Object ();

        this.submission_name = submission_name;
        if (files != null)
            populate_group (files, files_group);

        if (alt_files != null)
            populate_group (alt_files, alt_files_group);
        
        if (archived_files != null)
            populate_group (archived_files, archived_files_group);
    }

    private void populate_group (Json.Array list, Adw.PreferencesGroup group) {
        foreach (var item in list.get_elements ()) {
            var file = item.get_object ();
            var row = new FileRow (submission_name, file); 
            group.add (row);
        }
        group.set_visible (true);
    }
}