from flask import Flask, request, render_template_string
import sqlite3
from datetime import datetime

app = Flask(__name__)

# === DB Initialization ===
def init_db():
    conn = sqlite3.connect('machines.db')
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS machines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mac TEXT NOT NULL,
            ip TEXT NOT NULL,
            hostname TEXT NOT NULL,
            roll_number TEXT,
            status TEXT DEFAULT 'Pending',
            last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    ''')
    conn.commit()
    conn.close()

init_db()  # Run on app start

# === Register Endpoint ===
@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    mac = data.get('mac')
    ip = data.get('ip')
    hostname = data.get('hostname')
    roll_number = data.get('roll_number', '')
    status = data.get('status', 'Booted')
    timestamp = datetime.now()

    conn = sqlite3.connect('machines.db')
    c = conn.cursor()

    # Insert new record without replacing existing
    c.execute('''
        INSERT INTO machines (mac, ip, hostname, roll_number, status, last_seen)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (mac, ip, hostname, roll_number, status, timestamp))

    conn.commit()
    conn.close()
    return 'Registered Successfully', 200

# === Status Dashboard ===
@app.route('/')
def index():
    conn = sqlite3.connect('machines.db')
    c = conn.cursor()
    c.execute("SELECT mac, ip, hostname, roll_number, status, last_seen FROM machines ORDER BY last_seen DESC")
    rows = c.fetchall()
    conn.close()

    html = '''
    <!DOCTYPE html>
    <html>
    <head>
        <title>PXE Client Status</title>
        <style>
            body { font-family: Arial, sans-serif; background: #f2f2f2; }
            h2 { text-align: center; color: #003366; }
            table {
                margin: auto;
                border-collapse: collapse;
                width: 90%;
                background-color: #ffffff;
                box-shadow: 0 0 10px rgba(0,0,0,0.1);
            }
            th, td {
                border: 1px solid #cccccc;
                padding: 12px;
                text-align: center;
            }
            th {
                background-color: #003366;
                color: white;
            }
            tr:nth-child(even) { background-color: #f9f9f9; }
            tr:hover { background-color: #e0f7fa; }
        </style>
    </head>
    <body>
        <h2>PXE Client Status Dashboard</h2>
        <table>
            <tr>
                <th>MAC Address</th>
                <th>IP</th>
                <th>Hostname</th>
                <th>Roll Number</th>
                <th>Status</th>
                <th>Last Seen</th>
            </tr>
            {% for row in rows %}
            <tr>
                <td>{{ row[0] }}</td>
                <td>{{ row[1] }}</td>
                <td>{{ row[2] }}</td>
                <td>{{ row[3] or '-' }}</td>
                <td>{{ row[4] }}</td>
                <td>{{ row[5] }}</td>
            </tr>
            {% endfor %}
        </table>
    </body>
    </html>
    '''
    return render_template_string(html, rows=rows)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
