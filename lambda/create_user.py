import json
import boto3
import os
import uuid
import hashlib
from datetime import datetime
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_TABLE'])

def lambda_handler(event, context):
    try:
        # Parse the request body
        if 'body' in event:
            if isinstance(event['body'], str):
                body = json.loads(event['body'])
            else:
                body = event['body']
        else:
            body = event

        # Extract username and password from request
        username = body.get('username')
        password = body.get('password')
        extra_info = body.get('extra_info', {})

        # Validate required fields
        if not username or not password:
            return {
                'statusCode': 400,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'error': 'Username and password are required'
                })
            }

        # Check if username already exists using GSI
        try:
            response = table.query(
                IndexName='username-index',
                KeyConditionExpression=Key('username').eq(username)
            )
            if response['Items']:
                return {
                    'statusCode': 409,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type'
                    },
                    'body': json.dumps({
                        'error': 'Username already exists'
                    })
                }
        except Exception as e:
            print(f"Error checking username: {str(e)}")

        # Generate unique user ID
        user_id = str(uuid.uuid4())

        # Hash the password (in production, use bcrypt or similar)
        password_hash = hashlib.sha256(password.encode()).hexdigest()

        # Create user item
        user_item = {
            'user_id': user_id,
            'username': username,
            'password': password_hash,
            'extra_info': extra_info,
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat()
        }

        # Put item in DynamoDB
        table.put_item(Item=user_item)

        # Return success response (don't include password hash)
        response_user = {
            'user_id': user_id,
            'username': username,
            'extra_info': extra_info,
            'created_at': user_item['created_at']
        }

        return {
            'statusCode': 201,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'message': 'User created successfully',
                'user': response_user
            })
        }

    except Exception as e:
        print(f"Error creating user: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST, OPTIONS',
                'Access-Control-Allow-Headers': 'Content-Type'
            },
            'body': json.dumps({
                'error': 'Internal server error',
                'details': str(e)
            })
        }
