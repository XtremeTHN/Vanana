public class LoadingWidget: Adw.Bin {
    public Gtk.Stack stack = new Gtk.Stack ();

    Gtk.Widget? _content;
    public Gtk.Widget? content {
        get {
            return _content;
        }
        set {
            _content = value;
            stack.add_named (value, "content");
        }
    }

    Gtk.Label placeholder_label;
    public string placeholder_title {
        set {
            placeholder_label.set_label (value);
        }
    }

    construct {
        set_child (stack);

        var loader = new Adw.Spinner ();
        stack.add_named (loader, "loader");

        placeholder_label = new Gtk.Label ("Failed to load");
        stack.add_named (placeholder_label, "placeholder");
    }

    public void start_loading () {
        stack.set_visible_child_name ("loader");
    }

    public void finish_loading () {
        stack.set_visible_child_name ("content");
    }

    public void finish_with_error () {
        stack.set_visible_child_name ("placeholder");
    }

    public bool get_is_finished () {
        return stack.get_visible_child_name () != "loader";
    }
}