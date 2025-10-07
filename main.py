import base64
import json

def validate_pubsub(event, context):
    try:
        pubsub_message = base64.b64decode(event['data']).decode('utf-8')
        data = json.loads(pubsub_message)
        if "device_id" in data and "timestamp" in data:
            print(json.dumps({"status": "valid"}))
        else:
            print(json.dumps({"error": "Missing fields"}))
    except Exception:
        print(json.dumps({"error": "Invalid JSON"}))
