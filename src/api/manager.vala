[SingleInstance]
public class DownloadManager : Object {
    public signal void download_added (DownloadRow row);
    public signal void download_finish (DownloadRow row);

    public List<DownloadRow> downloads;

    public DownloadManager () {
        downloads = new List<DownloadRow> ();
    }

    public void on_download_finish (DownloadRow row) {
        downloads.remove (row);
        download_finish (row);
    }

    public void add_download (Json.Object file_info, File save_file, string submission_name) {
        var row = new DownloadRow (file_info, submission_name);
        row.start_download (save_file);
        row.finish.connect (on_download_finish);

        downloads.append (row);
        download_added (row);
    }

    public void stop_downloads () {
        downloads.foreach ((row) => {
            row.stop_download ();
            downloads.remove (row);
        });
    }
}