#!/usr/bin/env python3
"""Internal analytics dashboard — debug mode intentionally left on."""

from flask import Flask, jsonify

app = Flask(__name__)


@app.route('/')
def index():
    return (
        '<h1>Internal Analytics Dashboard</h1>'
        '<p>Status: <strong>operational</strong></p>'
        '<ul>'
        '<li><a href="/api/status">/api/status</a></li>'
        '<li><a href="/api/data">/api/data</a></li>'
        '</ul>'
    )


@app.route('/api/status')
def status():
    return jsonify({"status": "ok", "version": "2.1.0", "env": "production"})


@app.route('/api/data')
def data():
    return jsonify({"records": 1042, "processed": 987, "pending": 55})


@app.route('/crash')
def crash():
    # Intentionally throws to surface the Werkzeug interactive debugger
    raise RuntimeError("debug endpoint triggered")


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
