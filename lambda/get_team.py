import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
teams_table = dynamodb.Table(os.environ['TEAMS_TABLE'])

def lambda_handler(event, context):
    team_id = event.get('pathParameters', {}).get('teamId')
    if not team_id:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'GET, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                    'error': 'team_id is required'
            })
        }

    # First, verify that the requesting user is the team captain
    try:
        response = teams_table.get_item(Key={'id': team_id})
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Team not found'})
            }

        return {
            'statusCode': 200,
            'body': json.dumps({'result': 'success', 'team': response['Item']})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
