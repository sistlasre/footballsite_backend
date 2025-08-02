import json
import boto3
import os
import hashlib
import uuid
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['USER_TABLE'])

def generate_mock_jwt_token(user_data):
    """Generate a simple mock JWT token for testing"""
    import base64
    
    # Create a simple token structure without actual JWT signing
    payload = {
        'user_id': user_data['user_id'],
        'username': user_data['username'],
        'exp': int((datetime.utcnow() + timedelta(weeks=2)).timestamp())
    }
    
    # Simple base64 encoding (not secure, just for testing)
    token_data = json.dumps(payload)
    token = base64.b64encode(token_data.encode()).decode()
    
    return token, datetime.utcnow() + timedelta(weeks=2)

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

        # Hash the provided password to compare with stored hash
        password_hash = hashlib.sha256(password.encode()).hexdigest()

        # Query for user by username using GSI
        try:
            response = table.query(
                IndexName='username-index',
                KeyConditionExpression=Key('username').eq(username)
            )
            
            if not response['Items']:
                return {
                    'statusCode': 401,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type'
                    },
                    'body': json.dumps({
                        'error': 'Invalid username or password'
                    })
                }

            user_item = response['Items'][0]
            
            # Verify password hash
            if user_item.get('password') != password_hash:
                return {
                    'statusCode': 401,
                    'headers': {
                        'Content-Type': 'application/json',
                        'Access-Control-Allow-Origin': '*',
                        'Access-Control-Allow-Methods': 'POST, OPTIONS',
                        'Access-Control-Allow-Headers': 'Content-Type'
                    },
                    'body': json.dumps({
                        'error': 'Invalid username or password'
                    })
                }

            # Generate mock JWT token
            token, expiration_time = generate_mock_jwt_token(user_item)
            
            # Return successful sign-in response (don't include password hash)
            response_user = {
                'user_id': user_item['user_id'],
                'username': user_item['username'],
                'extra_info': user_item.get('extra_info', {}),
                'created_at': user_item.get('created_at'),
                'updated_at': user_item.get('updated_at')
            }

            return {
                'statusCode': 200,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type, Authorization'
                },
                'body': json.dumps({
                    'message': 'Sign-in successful',
                    'user': response_user,
                    'token': token,
                    'expires_at': expiration_time.isoformat()
                })
            }

        except Exception as e:
            print(f"Error querying user: {str(e)}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*',
                    'Access-Control-Allow-Methods': 'POST, OPTIONS',
                    'Access-Control-Allow-Headers': 'Content-Type'
                },
                'body': json.dumps({
                    'error': 'Internal server error during authentication',
                    'details': str(e)
                })
            }

    except Exception as e:
        print(f"Error in sign-in: {str(e)}")
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
