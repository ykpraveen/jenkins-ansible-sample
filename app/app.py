import os

from flask import Flask, jsonify

app = Flask(__name__)

APP_VERSION = os.environ.get("APP_VERSION", "dev")
GIT_SHA = os.environ.get("GIT_SHA", "unknown")
SIMULATE_FAILURE = os.environ.get("SIMULATE_FAILURE", "false").lower() == "true"


@app.route("/health")
def health():
    if SIMULATE_FAILURE:
        return jsonify(status="unhealthy"), 500
    return jsonify(status="ok"), 200


@app.route("/version")
def version():
    return jsonify(version=APP_VERSION, git_sha=GIT_SHA), 200
