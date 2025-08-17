
namespace Vanana {
    delegate void CacheCallback (File? dest);

    void create_cache_dir () {
        var cache_dir = File.new_build_filename (Environment.get_user_cache_dir (), "vanana");
        if (cache_dir.query_exists ()) {
            return;
        }

        try {
            cache_dir.make_directory_with_parents (null);
        } catch (Error e) {
            warning ("Error while creating cache dir: %s", e.message);
        }
    }

    void cache_download (string url, CacheCallback callback, Cancellable cancel) {
        string cache_dir = Path.build_filename (Environment.get_user_cache_dir (), "vanana");

        string file_name = Utils.get_url_file_basename (url);

        var dest = File.new_build_filename (cache_dir, file_name);

        if (dest.query_exists ()) {
            callback (dest);
            return;
        }

        var src = File.new_for_uri (url);

        src.copy_async.begin (dest, GLib.FileCopyFlags.NONE, Priority.DEFAULT, cancel, null, (obj, res) => {
            try {
                src.copy_async.end (res);
                callback (dest);
            } catch (Error e) {
                if (e is IOError.CANCELLED)
                    return;

                callback (null);
                warning ("Error while caching image: %s", e.message);
            }
        });

    }
}