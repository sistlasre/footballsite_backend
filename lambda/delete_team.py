import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
teams_table = dynamodb.Table(os.environ['TEAMS_TABLE'])

def lambda_handler(event, context):
    team_id = event.get('pathParameters', {}).get('teamId')
    if 'body' in event:
        if isinstance(event['body'], str):
            body = json.loads(event['body'])
        else:
            body = event['body']
    else:
        body = event

    team_captain_id = body['team_captain_id']

    if not team_id or not team_captain_id:
        return {
            'statusCode': 400,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'DELETE, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                    'error': 'team_id and team_captain_id are both required'
            })
        }

    # First, verify that the requesting user is the team captain
    try:
        get_response = teams_table.get_item(Key={'id': team_id})
        if 'Item' not in get_response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Team not found'})
            }

        team = get_response['Item']
        if team['team_captain_id'] != team_captain_id:
            return {
                'statusCode': 403,
                'body': json.dumps({'error': 'Unauthorized: Only team captain can delete the team'})
            }

        # Delete the team
        response = teams_table.delete_item(Key={'id': team_id})

        return {
            'statusCode': 200,
            'body': json.dumps({'result': 'success', 'response': response})
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
