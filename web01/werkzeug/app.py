#!/usr/bin/env python3
"""Internal analytics dashboard — debug mode intentionally left on."""

from flask import Flask, jsonify, redirect

app = Flask(__name__)


@app.route('/')
def index():
    return redirect('/console')


@app.route('/api/status')
def status():
    return jsonify({"status": "ok", "version": "2.1.0", "env": "production"})


@app.route('/api/data')
def data():
    return jsonify({"records": 1042, "processed": 987, "pending": 55})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
