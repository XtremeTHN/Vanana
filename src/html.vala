
public class Vanana.HtmlView : Gtk.TextView {
    private Gdk.RGBA red_adw;
    private Gdk.RGBA green_adw;
    private Gdk.RGBA accent;

    public HtmlView (bool background_visible = false) {
        Object (editable: false,  cursor_visible: false, wrap_mode: Gtk.WrapMode.WORD_CHAR);

        var manager = Adw.StyleManager.get_default ();
        accent = manager.get_accent_color_rgba ();

        red_adw.parse ("#e62d42");
        green_adw.parse ("#3a944a");

        var click_controller = new Gtk.GestureClick ();
        var motion_controller = new Gtk.EventControllerMotion ();

        click_controller.released.connect (on_released);
        motion_controller.motion.connect (on_motion);

        add_controller (click_controller);
        add_controller (motion_controller);

        if (background_visible == false)
            set_css_classes ({});
    }

    public void set_html (string html) {
        Gtk.TextBuffer buff = get_formatted_buffer (html);
        set_buffer (buff);
    }

    public void set_margins (int margin) {
        set_top_margin (margin);
        set_bottom_margin (margin);
        set_left_margin (margin);
        set_right_margin (margin);
    }

    private void on_motion (Gtk.EventControllerMotion _, double dx, double dy) {
        int tx, ty;
        int x = (int) dx;
        int y = (int) dy;

        Gtk.TextIter iter;

        window_to_buffer_coords (Gtk.TextWindowType.WIDGET,  x, y, out tx, out ty);

        if (get_iter_at_location (out iter, x, y) == false)
            return;

        foreach (var tag in iter.get_tags ()) {
            string? url = tag.get_data<string?> ("url");
            if (url != null)
                set_cursor_from_name ("pointer");
                return;
        }
        set_cursor_from_name ("text");
    }

    private void on_released (Gtk.GestureClick gesture, int n_press, double dx, double dy) {
        Gtk.TextIter iter;
        int tx, ty;
        int x = (int) dx;
        int y = (int) dy;
         
        if (gesture.get_button () > 1)
            return;
        
        window_to_buffer_coords (Gtk.TextWindowType.WIDGET, x, y, out tx, out ty);
        
        if (buffer == null)
            return;
        
        if (get_iter_at_location (out iter, tx, ty) == false)
            return;

        foreach (var tag in iter.get_tags ()) {
            string? url = tag.get_data<string?> ("url");
            if (url != null) {
                AppInfo.launch_default_for_uri_async.begin (url, null, null);
            }
        }
    }


    private void insert_with_tags (Gtk.TextBuffer buff, string text, ref Gtk.TextIter iter, List<Gtk.TextTag> tags) {
        int offset = iter.get_offset ();
        Gtk.TextIter start;

        buff.insert(ref iter, text, -1);

        buff.get_iter_at_offset (out start, offset);

        foreach (var tag in tags) {
            buff.apply_tag(tag, start, iter);
        }
    }

    private void walk_node (Xml.Node* node, ref Gtk.TextIter iter, List<Gtk.TextTag> tag_stack, Gtk.TextBuffer buffer) {
        if (node == null) return;

        if (node->type == Xml.ElementType.TEXT_NODE) {
            string text = node->content;
            if (text.strip () != "") {
                insert_with_tags (buffer, text,  ref iter, tag_stack);
            }
            return;
        }

        if (node->type != Xml.ElementType.ELEMENT_NODE) {
            return;
        }

        string name = node->name;
        var table = buffer.get_tag_table ();

        // Special cases
        if (name == "br") {
            if (node->next->name != "ul" || node->next->name != "ol")
                buffer.insert (ref iter, "\n", -1);
            return;
        }

        if (name == "img") {
            // the user must define src right?, that's why they wrote an image tag 
            string? src = null;
            string alt = "Image";

            for (Xml.Attr* attr = node->properties; attr != null; attr = attr->next) {
                if (attr->name == "src") {
                    src = attr->children->content;
                }

                if (attr->name == "alt") {
                    alt = attr->children->content;
                }
            }

            var new_stack = new List<Gtk.TextTag> ();
            tag_stack.foreach ((j) => {new_stack.append(j);});

            var link_tag = get_link_tag (buffer, src);
            new_stack.append (link_tag);

            insert_with_tags (buffer, alt, ref iter, new_stack);
        }

        if (name == "a") {
            string? href = null;
            for (Xml.Attr* attr = node->properties; attr != null; attr = attr->next) {
                if (attr->name == "href") {
                    href = attr->children->content;
                    break;
                }
            }
            var link_tag = (href != null) ? get_link_tag (buffer, href) : null;
            var new_stack = new List<Gtk.TextTag> ();
            tag_stack.foreach ((j) => {new_stack.append(j);});

            if (link_tag != null) new_stack.append (link_tag);

            for (Xml.Node* child = node->children; child != null; child = child->next) {
                walk_node (child, ref iter, new_stack, buffer);
            }
            return;
        }

        if (name == "ul") {
            for (Xml.Node* child = node->children; child != null; child = child->next) {
                if (child->name == "li") {
                    var text = "\n- " + child->children->content;
                    buffer.insert_with_tags_by_name (ref iter, text, -1, "li");
                }
            }
            buffer.insert (ref iter, "\n", 1);

            return;
        }

        if (name == "ol") {
            int count = 1;
            for (Xml.Node* child = node->children; child != null; child = child->next) {
                if (child->name == "li") {
                    var text = "\n%i. %s".printf(count, child->children->content);
                    buffer.insert_with_tags_by_name (ref iter, text, -1, "li");
                    count += 1;
                }
            }
            buffer.insert (ref iter, "\n", 1);

            return;
        }

        // Normal tag handling
        var new_stack = new List<Gtk.TextTag> ();
        tag_stack.foreach ((j) => {new_stack.append(j);});

        var tag = table.lookup (name);
        if (tag != null) {
            new_stack.append (tag);
        }

        for (Xml.Node* child = node->children; child != null; child = child->next) {
            walk_node (child, ref iter, new_stack, buffer);
        }

        if (name.length == 2 && name[0] == 'h' && name[1].isdigit ()) {
            buffer.insert (ref iter, "\n", -1);
        }
    }

    public Gtk.TextBuffer get_formatted_buffer (string? text) {
        var buff = new Gtk.TextBuffer (null);
        if (text == null)
            return buff;

        add_tags_to_buffer (buff);

        Gtk.TextIter iter; 
        buff.get_start_iter (out iter);

        Html.Doc* parser = Html.Doc.read_memory ((char []) text, text.length, "", "utf-8", 0);
        
        var root = parser->get_root_element ();

        var stack = new List<Gtk.TextTag> ();

        for (Xml.Node* x_iter = root->children; x_iter != null; x_iter = x_iter->next) {
            if (x_iter->name == "html")
                continue;
            
            walk_node (x_iter, ref iter, stack, buff);
        }

        delete parser;
        return buff;
    }

    private void add_tags_to_buffer (Gtk.TextBuffer buff) {
        buff.create_tag ("strong", "weight", 700);
        buff.create_tag ("b", "weight", 700);

        buff.create_tag ("u", "underline", Pango.Underline.SINGLE);
        buff.create_tag ("del", "strikethrough", true);
        buff.create_tag ("a", "weight", 500, "foreground-rgba", accent);

        buff.create_tag ("italic", "style", Pango.Style.ITALIC);

        buff.create_tag ("li", "indent", 4);
        buff.create_tag ("h1", "scale", 1.6, "weight", 800);
        buff.create_tag ("h2", "scale", 1.4, "weight", 800);
        buff.create_tag ("h3", "scale", 1.2, "weight", 800);
        buff.create_tag ("h4", "scale", 1.0, "weight", 800);
        buff.create_tag ("code", "scale", 0.8, "weight", 600, "family", "Monospace");

        buff.create_tag ("RedColor", "foreground-rgba", red_adw);
        buff.create_tag ("GreenColor", "foreground-rgba", green_adw);
    }

    private Gtk.TextTag get_link_tag (Gtk.TextBuffer buff, owned string url) {
        var table = buff.get_tag_table ();
        
        var tag = new Gtk.TextTag ();
        tag.weight = 500;
        tag.foreground_rgba = accent;
        tag.underline = Pango.Underline.SINGLE;
        tag.underline_rgba = accent;

        tag.set_data<string> ("url", url);

        table.add (tag);

        return tag;
    }
}