import St from 'gi://St';
import GLib from 'gi://GLib';
import Soup from 'gi://Soup?version=3.0';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import * as PanelMenu from 'resource:///org/gnome/shell/ui/panelMenu.js';
import * as PopupMenu from 'resource:///org/gnome/shell/ui/popupMenu.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const AGENT_URL = 'http://localhost:8765/ask';

class AskKibriaIndicator extends PanelMenu.Button {
    _init() {
        super._init(0.0, 'Ask-Kibria');

        const icon = new St.Icon({
            icon_name: 'dialog-question-symbolic',
            style_class: 'system-status-icon',
        });
        this.add_child(icon);

        const item = new PopupMenu.PopupBaseMenuItem({reactive: false, can_focus: false});

        const box = new St.BoxLayout({
            vertical: true,
            style_class: 'ask-kibria-box',
        });

        this._entry = new St.Entry({
            hint_text: 'Ask Kibria…',
            style_class: 'ask-kibria-entry',
            can_focus: true,
        });

        const row = new St.BoxLayout({style_class: 'ask-kibria-row'});
        this._sendBtn = new St.Button({
            label: 'Ask',
            style_class: 'ask-kibria-send-btn',
        });
        row.add_child(this._sendBtn);

        this._responseLabel = new St.Label({
            text: '',
            style_class: 'ask-kibria-response',
        });
        this._responseLabel.clutter_text.line_wrap = true;

        box.add_child(this._entry);
        box.add_child(row);
        box.add_child(this._responseLabel);
        item.add_child(box);
        this.menu.addMenuItem(item);

        this._sendBtn.connect('clicked', this._onSend.bind(this));
        this._entry.clutter_text.connect('activate', this._onSend.bind(this));
    }

    _onSend() {
        const prompt = this._entry.get_text().trim();
        if (!prompt) return;

        this._responseLabel.set_text('Thinking…');
        this._sendBtn.set_reactive(false);

        const payload = new GLib.Bytes(new TextEncoder().encode(
            JSON.stringify({prompt, stream: false})
        ));
        const session = new Soup.Session();
        const message = Soup.Message.new('POST', AGENT_URL);
        message.set_request_body_from_bytes('application/json', payload);

        session.send_and_read_async(message, GLib.PRIORITY_DEFAULT, null, (src, result) => {
            try {
                const bytes = src.send_and_read_finish(result);
                const text = new TextDecoder().decode(bytes.get_data());
                const data = JSON.parse(text);
                this._responseLabel.set_text(data.response || 'No response');
            } catch (_e) {
                this._responseLabel.set_text('Agent offline — start kibria-agent.service');
            } finally {
                this._sendBtn.set_reactive(true);
            }
        });
    }
}

export default class AskKibriaExtension extends Extension {
    enable() {
        this._indicator = new AskKibriaIndicator();
        Main.panel.addToStatusArea(this.uuid, this._indicator);
    }

    disable() {
        this._indicator?.destroy();
        this._indicator = null;
    }
}
