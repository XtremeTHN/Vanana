namespace Utils {
    public string capitalize_first(string input) {
        if (input.length == 0)
            return input;

        string inp = input.ascii_down ();

        return inp.substring(0, 1).up () + inp.substring (1);
    }

    public void dump_json_obj (Json.Object obj) {
        foreach (var item in obj.get_members ()) {
            var s = obj.get_member (item);

            switch (s.get_node_type ()) {
                case Json.NodeType.OBJECT:
                    dump_json_obj (s.get_object ());
                    break;
                case Json.NodeType.VALUE:
                    switch (s.get_value_type ()) {
                        case GLib.Type.STRING:
                            message ("%s: %s", item, s.get_string ());
                            break;
                        case GLib.Type.BOOLEAN:
                            message ("%s: %b", item, s.get_boolean ());
                            break;
                        case GLib.Type.INT64:
                            message ("%s: %" + int64.FORMAT, item, s.get_int ());
                            break;
                        default:
                            message (item);
                            break;
                    }
                    break;
                case Json.NodeType.ARRAY:
                    message (item);
                    break;
            }
        }
    }
}