public class HoverButton : Gtk.Button {
    public Gtk.Widget? parent {
        set {
            var motion = new Gtk.EventControllerMotion ();
            motion.enter.connect (on_hover);
            motion.leave.connect (on_hover_lost);
            value.add_controller (motion);
        }
    }

    private void on_hover () {
        set_visible (true);
    }

    private void on_hover_lost () {
        set_visible (false);
    }
}