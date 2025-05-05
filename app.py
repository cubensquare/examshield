from flask import Flask, request, jsonify
from datetime import datetime
import sqlite3

app = Flask(__name__)
DB = 'clients.db'

def init_db():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute('''
    CREATE TABLE IF NOT EXISTS machines (
        mac TEXT PRIMARY KEY,
        ip TEXT,
        hostname TEXT,
        status TEXT,
        last_seen TEXT
    )''')
    conn.commit()
    conn.close()

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute('''
        INSERT OR REPLACE INTO machines (mac, ip, hostname, status, last_seen)
        VALUES (?, ?, ?, ?, ?)
    ''', (
        data.get('mac'),
        data.get('ip'),
        data.get('hostname'),
        data.get('status'),
        datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    ))
    conn.commit()
    conn.close()
    return jsonify({'message': 'Registered'})

@app.route('/status', methods=['GET'])
def status():
    conn = sqlite3.connect(DB)
    c = conn.cursor()
    c.execute("SELECT * FROM machines")
    rows = c.fetchall()
    conn.close()
    return jsonify(rows)

from flask import Flask, request, jsonify

app = Flask(__name__)

@app.route('/test', methods=['POST'])
def test_post():
    data = request.get_json()
    return jsonify({"received": data}), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)
