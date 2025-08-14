
class Vanana.HtmlView : Gtk.TextView {
    private Gdk.RGBA red_adw;
    private Gdk.RGBA green_adw;
    private Gdk.RGBA accent;

    public HtmlView () {
        Object (editable: false,  cursor_visible: false, wrap_mode: Gtk.WrapMode.WORD_CHAR);

        var manager = Adw.StyleManager.get_default ();
        accent = manager.get_accent_color_rgba ();

        red_adw.parse ("#e62d42");
        green_adw.parse ("#3a944a");

        set_css_classes ({});
    }

    private void insert_with_tags (Gtk.TextBuffer buff, string text, ref Gtk.TextIter iter, List<Gtk.TextTag> tags) {
        int offset = iter.get_offset ();
        Gtk.TextIter start;

        buff.insert(ref iter, text, -1); // Insert text first

        buff.get_iter_at_offset (out start, offset);

        // Apply tags manually to the inserted range
        foreach (var tag in tags) {
            buff.apply_tag(tag, start, iter);
        }
    }

    private void walk_node (Xml.Node* node, ref Gtk.TextIter iter, List<Gtk.TextTag> tag_stack, Gtk.TextBuffer buffer) {
        if (node == null) return;

        if (node->type == Xml.ElementType.TEXT_NODE) {
            string text = (string) node->content;
            if (text.strip () != "") {
                insert_with_tags (buffer, text,  ref iter, tag_stack);
                //  buffer.insert(ref iter, text, -1);
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
            buffer.insert (ref iter, "\n", -1);
            return;
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
            
            //  insert_node (x_iter, iter, stack, buff);
            walk_node (x_iter, ref iter, stack, buff);
        }

        delete parser;
        return buff;
    }

    private void add_tags_to_buffer (Gtk.TextBuffer buff) {
        buff.create_tag ("strong", "weight", 700);

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