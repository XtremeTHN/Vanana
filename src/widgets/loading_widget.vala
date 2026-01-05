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

    construct {
        set_child (stack);

        var loader = new Adw.Spinner ();
        stack.add_named (loader, "loader");
    }

    public void start_loading () {
        stack.set_visible_child_name ("loader");
    }

    public void finish_loading () {
        stack.set_visible_child_name ("content");
    }

    public bool get_is_finished () {
        return stack.get_visible_child_name () != "loader";
    }
}