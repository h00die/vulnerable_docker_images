#!/usr/bin/env python3
"""Internal analytics dashboard — debug mode intentionally left on."""

from flask import Flask, jsonify
from werkzeug.debug import DebuggedApplication
from werkzeug.serving import run_simple

app = Flask(__name__)


@app.route('/api/status')
def status():
    return jsonify({"status": "ok", "version": "2.1.0", "env": "production"})


@app.route('/api/data')
def data():
    return jsonify({"records": 1042, "processed": 987, "pending": 55})


# Expose the interactive Python console at / with no PIN
application = DebuggedApplication(app, evalex=True, console_path='/', pin_security=False)

if __name__ == '__main__':
    run_simple('0.0.0.0', 5000, application, use_debugger=False, use_reloader=False)
