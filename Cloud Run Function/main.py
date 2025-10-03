import base64
import json
from google.cloud import bigquery

def pubsub_to_bigquery(event, context):
    client = bigquery.Client()
    table_id = "bootcampprojectmark.health_data.device_records"
    try:
        # Decode the message data
        message_data = base64.b64decode(event['data']).decode('utf-8')
        print(f"Received message: {message_data}")
        
        # Parse JSON
        msg = json.loads(message_data)
        
        row = [{
            "device_id": msg.get("device_id"),
            "timestamp": msg.get("timestamp"),
            "data": message_data
        }]
        
        errors = client.insert_rows_json(table_id, row)
        if errors:
            print("BigQuery insert error:", errors)
        else:
            print("Row inserted successfully")
    except Exception as e:
        print("Processing error:", str(e))
        print(f"Raw event data: {event}")
