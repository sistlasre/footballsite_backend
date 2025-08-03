import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
events_table = dynamodb.Table(os.environ['EVENTS_TABLE'])

def lambda_handler(event, context):
    event_id = event.get('pathParameters', {}).get('eventId')
    if not event_id:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                    'error': 'event_id is required'
            })
        }

    # First, verify that the requesting user is the team captain
    try:
        response = events_table.get_item(Key={'id': event_id})
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Event not found'})
            }

        return {
            'statusCode': 200,
            'body': json.dumps({'event': response['Item']})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
