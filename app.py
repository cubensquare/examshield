from flask import Flask, request, render_template_string, jsonify
from datetime import datetime
import sqlite3

app = Flask(__name__)
DB_FILE = 'pxe_status.db'

@app.route('/')
def index():
    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute("SELECT mac, ip, hostname, roll_number, status, last_seen FROM machines ORDER BY last_seen DESC")
    rows = c.fetchall()
    conn.close()

    html = '''
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <title>PXE Client Dashboard</title>
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
            body {
                background-color: #f2f2f2;
            }
            .container {
                margin-top: 40px;
            }
            .header {
                text-align: center;
                margin-bottom: 30px;
            }
            .table-card {
                background-color: #fff;
                padding: 25px;
                border-radius: 10px;
                box-shadow: 0 0 10px rgba(0,0,0,0.1);
            }
            .table th, .table td {
                text-align: center;
            }
            img.logo {
                width: 80px;
                margin-bottom: 10px;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <img class="logo" src="https://cdn-icons-png.flaticon.com/512/3135/3135755.png">
                <h2 class="fw-bold">Exam Center PXE Client Status</h2>
                <p class="text-muted">Live Monitoring of All Connected Systems</p>
            </div>
            <div class="table-card">
                <table class="table table-bordered table-hover">
                    <thead class="table-dark">
                        <tr>
                            <th>MAC Address</th>
                            <th>IP</th>
                            <th>Hostname</th>
                            <th>Roll Number</th>
                            <th>Status</th>
                            <th>Last Seen</th>
                        </tr>
                    </thead>
                    <tbody>
                        {% for row in rows %}
                        <tr>
                            {% for col in row %}
                            <td>{{ col }}</td>
                            {% endfor %}
                        </tr>
                        {% endfor %}
                    </tbody>
                </table>
            </div>
        </div>
    </body>
    </html>
    '''
    return render_template_string(html, rows=rows)

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    if not data:
        return jsonify({'error': 'No JSON received'}), 400

    conn = sqlite3.connect(DB_FILE)
    c = conn.cursor()
    c.execute('''
        CREATE TABLE IF NOT EXISTS machines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            mac TEXT,
            ip TEXT,
            hostname TEXT,
            roll_number TEXT,
            status TEXT,
            last_seen TEXT
        )
    ''')
    c.execute('''
        INSERT INTO machines (mac, ip, hostname, roll_number, status, last_seen)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (
        data.get('mac'),
        data.get('ip'),
        data.get('hostname'),
        data.get('roll_number', ''),
        'Ready',
        datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    ))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Machine registered successfully'})
