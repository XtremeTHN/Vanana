/* application.vala
 *
 * Copyright 2025 Axel Andres Valles Gonzalez
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

public class Vanana.Application : Adw.Application {
    public Application () {
        Object (
            application_id: "com.github.XtremeTHN.Vanana",
            flags: ApplicationFlags.DEFAULT_FLAGS,
            resource_base_path: "/com/github/XtremeTHN/Vanana"
        );

    }

    construct {
        ActionEntry[] action_entries = {
            { "about", this.on_about_action },
            { "preferences", this.on_preferences_action },
            { "quit", this.quit }
        };
        this.add_action_entries (action_entries, this);
        this.set_accels_for_action ("app.quit", {"<primary>q"});
    }

    public SimpleAction create_action (string name, VariantType? type = null) {
        var action = new SimpleAction (name, type);
        add_action (action);
        return action;
    }

    public override void activate () {
        base.activate ();

        create_cache_dir ();

        var provider = new Gtk.CssProvider ();
        provider.load_from_resource ("/com/github/XtremeTHN/Vanana/style.css");

        Gtk.StyleContext.add_provider_for_display (Gdk.Display.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_USER);

        var win = new Window (this);
        add_window (win);
        win.present ();
    }

    private void on_about_action () {
        string[] developers = { "Axel Andres Valles Gonzalez" };
        var about = new Adw.AboutDialog () {
            application_name = "vanana",
            application_icon = "com.github.XtremeTHN.Vanana",
            developer_name = "Axel Andres Valles Gonzalez",
            translator_credits = _("translator-credits"),
            version = "0.1.0",
            developers = developers,
            copyright = "© 2025 Axel Andres Valles Gonzalez",
        };

        about.present (this.active_window);
    }

    private void on_preferences_action () {
        message ("app.preferences action activated");
    }
}
