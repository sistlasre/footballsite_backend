import boto3
import uuid
import json
import os

dynamodb = boto3.resource('dynamodb')
teams_table = dynamodb.Table(os.environ['TEAMS_TABLE'])

def lambda_handler(event, context):
    team_captain_id = event['team_captain_id']
    team_name = event['team_name']
    parent_team_id = event.get('parent_team_id', None)
    team_id = str(uuid.uuid4())

    item = {
        'id': team_id,
        'name': team_name,
        'team_captain_id': team_captain_id,
        'members': [team_captain_id]  # Team captain is initially the only member
    }
    if parent_team_id:
        item['parent_team_id'] = parent_team_id

    # Insert into DynamoDB
    response = teams_table.put_item(Item=item)

    return {
        'statusCode': 200,
        'body': json.dumps({'result': 'success', 'response': response})
    }

