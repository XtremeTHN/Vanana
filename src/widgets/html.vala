using Gtk;

// TODO: Replace libxml2 with another html parsing library
public class Vanana.HtmlView : TextView {
    private Gdk.RGBA red_adw;
    private Gdk.RGBA green_adw;
    private Gdk.RGBA accent;

    public HtmlView (bool background_visible = false) {
        Object (editable: false,  cursor_visible: false, wrap_mode: WrapMode.WORD_CHAR);

        var manager = Adw.StyleManager.get_default ();
        accent = manager.get_accent_color_rgba ();

        red_adw.parse ("#e62d42");
        green_adw.parse ("#3a944a");

        var click_controller = new GestureClick ();
        var motion_controller = new EventControllerMotion ();

        click_controller.released.connect (on_released);
        motion_controller.motion.connect (on_motion);

        add_controller (click_controller);
        add_controller (motion_controller);

        if (background_visible == false)
            set_css_classes ({});
    }

    public void set_html (string html) {
        TextBuffer buff = get_formatted_buffer (html);
        set_buffer (buff);
    }

    public void set_margins (int margin) {
        set_top_margin (margin);
        set_bottom_margin (margin);
        set_left_margin (margin);
        set_right_margin (margin);
    }

    private void on_motion (EventControllerMotion _, double dx, double dy) {
        int tx, ty;
        int x = (int) dx;
        int y = (int) dy;

        TextIter iter;

        window_to_buffer_coords (TextWindowType.WIDGET,  x, y, out tx, out ty);

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

    private void on_released (GestureClick gesture, int n_press, double dx, double dy) {
        TextIter iter;
        int tx, ty;
        int x = (int) dx;
        int y = (int) dy;
         
        if (gesture.get_button () > 1)
            return;
        
        window_to_buffer_coords (TextWindowType.WIDGET, x, y, out tx, out ty);
        
        if (buffer == null)
            return;
        
        if (get_iter_at_location (out iter, tx, ty) == false)
            return;

        foreach (var tag in iter.get_tags ()) {
            string? url = tag.get_data<string?> ("url");
            if (url == null) continue;

            bool is_img = tag.get_data<bool> ("is-img");
            if (is_img) {
                var diag = new ImageViewDialog ();
                diag.set_from_url (url);
                diag.present (Utils.get_parent_window (this));
                break;
            }

            AppInfo.launch_default_for_uri_async.begin (url, null, null);
        }
    }


    private void insert_with_tags (TextBuffer buff, string text, ref TextIter iter, List<TextTag> tags) {
        int offset = iter.get_offset ();
        TextIter start;

        buff.insert(ref iter, text, -1);

        buff.get_iter_at_offset (out start, offset);

        foreach (var tag in tags) {
            buff.apply_tag(tag, start, iter);
        }
    }

    private void walk_node (Xml.Node* node, ref Gtk.TextIter iter, List<Gtk.TextTag> tag_stack, Gtk.TextBuffer buffer, string suffix = "") {
        if (node == null) return;

        if (node->type == Xml.ElementType.TEXT_NODE) {
            string text = node->content + suffix;
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

        if (name == "br") {
            if (node->next != null)
                if (node->next->name == "ul" || node->next->name == "ol")
                    return;
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

            var link_tag = get_link_tag (buffer, src, true);
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
        
        // TODO: make a function that runs shared code. I think this can be reduced.
        if (name == "ul") {
            for (Xml.Node* child = node->children; child != null; child = child->next) {
                if (child->name != "li") continue;

                buffer.insert (ref iter, "\n• ", -1);
                for (Xml.Node* li_child = child->children; li_child != null; li_child = li_child->next) {
                    walk_node (li_child, ref iter, tag_stack, buffer);
                }
            }
            buffer.insert (ref iter, "\n", 1);

            return;
        }

        if (name == "ol") {
            int count = 1;
            for (Xml.Node* child = node->children; child != null; child = child->next) {
                if (child->name != "li" || child->children == null) continue;

                buffer.insert (ref iter, "\n%i. %s", -1);

                for (Xml.Node* li_child = child->children; li_child != null; li_child = li_child->next) {
                    walk_node (li_child, ref iter, tag_stack, buffer);
                }
                count += 1;
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
        
        for (Xml.Attr* attr = node->properties; attr != null; attr = attr->next) {
            if (attr->children == null)
                continue;

            if (attr->name == "class") {
                foreach (var _class in attr->children->content.split (" ")) {
                    var _tag = table.lookup (_class);

                    if (_tag == null)
                        continue;
                    new_stack.append (_tag);
                }
                break;
            }
        }

        for (Xml.Node* child = node->children; child != null; child = child->next) {
            walk_node (child, ref iter, new_stack, buffer, suffix);
        }

        if (name.length == 2 && name[0] == 'h' && name[1].isdigit ()) {
            buffer.insert (ref iter, "\n", -1);
        }
    }

    public TextBuffer get_formatted_buffer (string? text) {
        var buff = new TextBuffer (null);
        add_tags_to_buffer (buff);

        if (text == null)
            return buff;

        TextIter iter; 
        buff.get_start_iter (out iter);

        if (print_html)
            message ("HtmlView: %s", text);

        Html.Doc* parser = Html.Doc.read_memory ((char []) text, text.length, "", "utf-8", 0);
        
        var root = parser->get_root_element ();

        var stack = new List<TextTag> ();

        for (Xml.Node* x_iter = root->children; x_iter != null; x_iter = x_iter->next) {
            if (x_iter->name == "html")
                continue;
            
            walk_node (x_iter, ref iter, stack, buff);
        }

        delete parser;
        return buff;
    }

    private void add_tags_to_buffer (TextBuffer buff) {
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

    private TextTag get_link_tag (TextBuffer buff, owned string url, bool is_image = false) {
        var table = buff.get_tag_table ();
        
        var tag = new TextTag ();
        tag.weight = 500;
        tag.foreground_rgba = accent;
        tag.underline = Pango.Underline.SINGLE;
        tag.underline_rgba = accent;

        tag.set_data<string> ("url", url);
        tag.set_data<bool> ("is-img", is_image);

        table.add (tag);

        return tag;
    }
}