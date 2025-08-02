import boto3
import uuid
import json
import os

dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])

def lambda_handler(event, context):
    organizer_id = event['organizer_id']
    event_name = event['event_name']
    date_start = event.get('date_start', None)
    date_end = event.get('date_end', None)
    parent_event_id = event.get('parent_event_id', None)
    location = event.get('location', None)
    additional_info = event.get('additional_info', None)
    event_id = str(uuid.uuid4())

    item = {
        'id': event_id,
        'name': event_name,
        'organizer_id': organizer_id,
        'status': 'unpublished'  # Default status
    }
    if date_start:
        item['date_start'] = date_start
    if date_end:
        item['date_end'] = date_end
    if parent_event_id:
        item['parent_event_id'] = parent_event_id
    if location:
        item['location'] = location
    if additional_info:
        item['additional_info'] = additional_info

    # Insert into DynamoDB
    response = events_table.put_item(Item=item)

    return {
        'statusCode': 200,
        'body': json.dumps({'result': 'success', 'response': response})
    }

