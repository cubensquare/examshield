from flask import Flask, request, render_template_string, jsonify
import sqlite3
from datetime import datetime

app = Flask(__name__)
DB_FILE = 'pxe_clients.db'

# Create the database and table if not exists
def init_db():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS machines (
            mac TEXT PRIMARY KEY,
            ip TEXT,
            hostname TEXT,
            roll_number TEXT,
            status TEXT,
            last_seen TEXT
        )
    ''')
    conn.commit()
    conn.close()

init_db()

# Homepage: Show machine statuses
@app.route('/')
def index():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute("SELECT * FROM machines")
    rows = c.fetchall()
    conn.close()
    html = '''
    <h2>PXE Client Status</h2>
    <table border="1" cellpadding="5">
        <tr>
            <th>MAC</th><th>IP</th><th>Hostname</th>
            <th>Roll No</th><th>Status</th><th>Last Seen</th>
        </tr>
        {% for row in rows %}
        <tr>
            {% for col in row %}
            <td>{{ col }}</td>
            {% endfor %}
        </tr>
        {% endfor %}
    </table>
    '''
    return render_template_string(html, rows=rows)

# Registration endpoint for PXE clients
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Invalid JSON'}), 400

    mac = data.get('mac')
    ip = data.get('ip')
    hostname = data.get('hostname')
    roll_number = data.get('roll_number', '')
    status = data.get('status', 'ready')
    last_seen = datetime.now().strftime('%Y-%m-%d %H:%M:%S')

    if not mac or not ip or not hostname:
        return jsonify({'error': 'MAC, IP, and hostname required'}), 400

    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''
        INSERT OR REPLACE INTO machines (mac, ip, hostname, roll_number, status, last_seen)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (mac, ip, hostname, roll_number, status, last_seen))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Client registered'}), 200

# Simple test endpoint to check if server is up
@app.route('/test', methods=['GET'])
def test():
    return jsonify({'status': 'ok', 'message': 'PXE Admin Panel is running.'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
