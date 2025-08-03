import boto3
import json
import os

dynamodb = boto3.resource('dynamodb')
teams_table = dynamodb.Table(os.environ['TEAMS_TABLE'])

def lambda_handler(event, context):
    """
    Lambda function to get all teams for a specific user (team captain)
    Expected path parameters: userId
    """

    try:
        # Extract userId from path parameters
        user_id = event.get('pathParameters', {}).get('userId')

        if not user_id:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({'error': 'userId path parameter is required'})
            }

        # Query DynamoDB using the team_captain_id-index
        response = teams_table.query(
            IndexName='team_captain_id-index',
            KeyConditionExpression='team_captain_id = :captain_id',
            ExpressionAttributeValues={
                ':captain_id': user_id
            }
        )

        all_teams = response.get('Items', [])
        teams = [team for team in all_teams if not team.get('parent_team_id')]
        sub_teams = {}
        for team in all_teams:
            if team.get('parent_team_id'):
                sub_teams[team['parent_team_id']] = [*sub_teams.get(team['parent_team_id'], []), team['id']]
        for team in teams:
            if sub_teams.get(team['id']):
                team['subTeams'] = sub_teams[team['id']]

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'teams': teams,
                'count': len(teams),
                'team_captain_id': user_id
            }, default=str)  # Use default=str to handle any special types
        }

    except Exception as e:
        print(f"Error: {str(e)}")  # This will appear in CloudWatch logs
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': f'Internal server error: {str(e)}'})
        }
