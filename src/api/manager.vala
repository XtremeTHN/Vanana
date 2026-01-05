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

    void start_row (DownloadRow row, File save_file) {
        row.start_download (save_file);
        row.finish.connect (on_download_finish);

        downloads.append (row);
        download_added (row);
    }

    public void add_download (string title, string filename, string url, File save_file) {
        var row = new DownloadRow (title, filename, url);
        start_row (row, save_file);
    }

    public void add_download_from_json (Json.Object file_info, File save_file, string submission_name) {
        var row = DownloadRow.from_json (file_info, submission_name);
        start_row (row, save_file);
    }

    public void stop_downloads () {
        downloads.foreach ((row) => {
            row.stop_download ();
            downloads.remove (row);
        });
    }
}