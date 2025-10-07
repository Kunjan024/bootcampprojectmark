from flask import Flask, request, jsonify


app = Flask(__name__)


@app.route('/', methods=['GET'])
def hello():
    return "Validator app running - Development", 200


@app.route('/', methods=['POST'])
def validate():
    try:
        data = request.get_json(force=True)
        if "device_id" in data and "timestamp" in data:
            return jsonify({"status": "valid"}), 200
        else:
            return jsonify({"error": "Missing fields"}), 400
    except Exception:
        return jsonify({"error": "Invalid JSON"}), 400


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
