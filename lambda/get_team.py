import boto3
import json
import os

dynamodb = boto3.client('dynamodb')

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

    try:
        response = dynamodb.get_item(
            TableName=os.environ['TEAMS_TABLE'],
            Key={'id': {'S': team_id}}
        )
        if 'Item' not in response:
            return {
                'statusCode': 404,
                'body': json.dumps({'error': 'Team not found'})
            }

        team = response['Item']

        response = dynamodb.batch_get_item(
            RequestItems={
                os.environ['USER_TABLE']: {
                    'Keys': [{'user_id': {'S': id_['S']}} for id_ in team['members']['L']]
                }
            }
        )
        team_members = response['Responses'][os.environ['USER_TABLE']]

        response = dynamodb.query(
            TableName=os.environ['TEAMS_TABLE'],
            IndexName='parent_team_id-index',
            KeyConditionExpression='parent_team_id = :parent_team_id',
            ExpressionAttributeValues={':parent_team_id': {'S': team_id}}
        )
        sub_teams = response['Items']

        return {
            'statusCode': 200,
            'body': json.dumps({
                'team': {
                    'id': team['id']['S'],
                    'name': team['name']['S'],
                    'team_captain_id': team['team_captain_id']['S'],
                    'members': [{'id': member['user_id']['S'], 'name': member['first_name']['S'] + " " + member['last_name']['S']} for member in team_members],
                    'subTeams': [{'id': team['id']['S'], 'name': team['name']['S']} for team in sub_teams]
                }
            })
        }

    except Exception as e:
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
