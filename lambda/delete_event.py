import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])

def lambda_handler(event, context):
    event_id = event.get('pathParameters', {}).get('eventId')
    if 'body' in event:
        if isinstance(event['body'], str):
            body = json.loads(event['body'])
        else:
            body = event['body']
    else:
        body = event

    organizer_id = body['organizer_id']

    if not event_id or not organizer_id:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                    'error': 'event_id and organizer_id are both required'
            })
        }


    # First, verify that the requesting user is the organizer
    try:
        get_response = events_table.get_item(Key={'id': event_id})
        if 'Item' not in get_response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Event not found'})
            }

        event_item = get_response['Item']
        # Check if the organizer id that was passed in matches the one for this event
        if organizer_id != event_item['organizer_id']:
            return {
                'statusCode': 403,
                'body': json.dumps({'error': 'Unauthorized: Only event organizer can delete the event'})
            }

        # Delete the event
        response = events_table.delete_item(Key={'id': event_id})

        return {
            'statusCode': 200,
            'body': json.dumps({'result': 'success', 'response': response})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
