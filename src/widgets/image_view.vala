public class ImageView : Gtk.Widget {
    Gdk.Texture? _texture;
    public Gdk.Texture? texture {
        get {
            return _texture;
        }
        set {
            _texture = value;
            _scale = 1.0f;
            _filter = Gsk.ScalingFilter.LINEAR;

            notify_property ("scale");
            notify_property ("filter");

            queue_resize ();
        }
    }

    Gsk.ScalingFilter _filter = Gsk.ScalingFilter.LINEAR;
    public Gsk.ScalingFilter filter {
        get {
            return _filter;
        }
        set {
            _filter = value;
            queue_resize ();
        }
    }

    float _scale = 1.0f;
    public float scale {
        get {
            return _scale;
        }
        set {
            _scale = value;
            queue_resize ();
        }
    }

    public ImageView () {
        Object ();
        set_accessible_role (Gtk.AccessibleRole.IMG);
    }

    Graphene.Rect rect_init (float x, float y, float width, float height) {
        return Graphene.Rect ().init (x, y, width, height);
    }

    protected override void snapshot (Gtk.Snapshot snap) {
        float w, h, w2, h2;

        var width = get_width (); 
        var height = get_height ();

        w2 = w = scale * texture.get_width ();
        h2 = h = scale * texture.get_height ();

        int x = (int) (width - Math.ceil (w2)) / 2;
        int y = (int) (height - Math.ceil (h2)) / 2;

        snap.push_clip (rect_init (0, 0, width, height));
        snap.save ();

        snap.translate (Graphene.Point ().init (x,y));
        snap.translate (Graphene.Point ().init (w2 / 2, h2 / 2));
        snap.translate (Graphene.Point ().init (-w / 2, -h / 2));

        snap.append_scaled_texture (texture, filter, rect_init (0, 0, w, h));

        snap.restore ();
        snap.pop ();
    }

    protected override void measure (Gtk.Orientation orientation, int for_size, out int minimum, out int natural, out int minimum_baseline, out int natural_baseline) {
        int size;

        if (orientation == Gtk.Orientation.HORIZONTAL)
            size = texture.get_width ();
        else
            size = texture.get_height ();
        
        minimum = natural = (int) Math.ceil (scale * size);

        minimum_baseline = -1;
        natural_baseline = -1;
    }

    protected override void size_allocate (int width, int height, int baseline) {}
}

[GtkTemplate(ui = "/com/github/XtremeTHN/Vanana/image-view-dialog.ui")]
public class ImageViewDialog : Adw.Dialog {
    [GtkChild]
    unowned ImageView view;

    [GtkChild]
    unowned Gtk.Revealer rev;

    [GtkChild]
    unowned Gtk.Stack stack;

    public ImageViewDialog () {
        Object ();
    }

    public void set_from_file (File? img) {
        try {
            view.texture = Gdk.Texture.from_file (img);
            stack.set_visible_child_name ("view");
        } catch (Error e) {
            Utils.show_toast (this, "Couldn't display the image: " + e.message);
        }
    }

    [GtkCallback]
    void zoom_in () {
        view.scale = float.min (1024.0f, (float) (view.scale * Math.SQRT2));
    }

    [GtkCallback]
    void zoom_out () {
        view.scale = float.max (1.0f / 1024.0f, (float) (view.scale / Math.SQRT2));
    }

    [GtkCallback]
    void toggle_revealer () {
        rev.reveal_child = !rev.reveal_child;
    }
}