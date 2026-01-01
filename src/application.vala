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

namespace Vanana {
    bool print_html;
    
    public class Application : Adw.Application {

        public Application () {
            Object (
                application_id: "com.github.XtremeTHN.Vanana",
                flags: ApplicationFlags.HANDLES_COMMAND_LINE,
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

        protected override int command_line (ApplicationCommandLine cmd) {
            string[] args = cmd.get_arguments ();
            var ctx = new OptionContext ();

            OptionEntry[] entries = {
                { "print-html", 'p', OptionFlags.NONE, OptionArg.NONE, ref print_html, "Prints the HTML string provided to an HtmlView widget." }
            };

            ctx.add_main_entries (entries, null);

            try {
                ctx.parse_strv (ref args);
            } catch (Error e) {
                cmd.printerr ("Couldn't parse arguments: %s", e.message);
                return 1;
            }

            init ();

            return 0;
        }

        public SimpleAction create_action (string name, VariantType? type = null) {
            var action = new SimpleAction (name, type);
            add_action (action);
            return action;
        }

        public void init () {
            create_cache_dir ();

            // register custom widgets
            new LoadingBtt ();

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
}