import json
import os

def lambda_handler(event, context):
    """
    Lambda function that returns HTML showing all available API endpoints
    """

    # Get the base URL from the event context
    domain_name = event.get('requestContext', {}).get('domainName', 'your-api-domain.com')
    stage = event.get('requestContext', {}).get('stage', 'dev')
    base_url = f"https://{domain_name}/{stage}"

    # Define all your endpoints with sample curl commands
    endpoints = [
        {
            "method": "GET",
            "path": "/endpoints",
            "description": "View this endpoints dashboard",
            "content_type": "text/html",
            "curl_sample": f"curl -X GET {base_url}/endpoints"
        },
        # User Management Endpoints
        {
            "method": "POST", 
            "path": "/user",
            "description": "Create a new user with first_name, last_name, email, phone_number",
            "content_type": "application/json",
            "curl_sample": f'''curl -X POST {base_url}/user -H "Content-Type: application/json" -d '{{"username": "john_doe", "first_name": "John", "last_name": "Doe", "email": "john@example.com", "phone_number": "+1234567890"}}' '''
        },
        {
            "method": "POST", 
            "path": "/user/signin",
            "description": "Sign in an existing user",
            "content_type": "application/json",
            "curl_sample": f'''curl -X POST {base_url}/user/signin -H "Content-Type: application/json" -d '{{"username": "john_doe", "password": "your_password"}}' '''
        },
        # Event Management Endpoints
        {
            "method": "POST", 
            "path": "/event",
            "description": "Create a new event as an organizer",
            "content_type": "application/json",
            "curl_sample": f'''curl -X POST {base_url}/event -H "Content-Type: application/json" -d '{{"organizer_id": "user123", "event_name": "Soccer Tournament", "date_start": "2024-06-01", "date_end": "2024-06-03", "location": "Central Park", "additional_info": "Bring your own water bottle"}}' '''
        },
        {
            "method": "DELETE", 
            "path": "/event/{{eventId}}",
            "description": "Delete an event (only by organizer)",
            "content_type": "application/json",
            "curl_sample": f'''curl -X DELETE {base_url}/event/event123 -H "Content-Type: application/json" -d '{{"organizer_id": "user123"}}' '''
        },
        # Team Management Endpoints
        {
            "method": "POST", 
            "path": "/team",
            "description": "Create a new team as a team captain",
            "content_type": "application/json",
            "curl_sample": f'''curl -X POST {base_url}/team -H "Content-Type: application/json" -d '{{"team_captain_id": "user123", "team_name": "Lightning Bolts", "parent_team_id": "parent_team456"}}' '''
        },
        {
            "method": "DELETE", 
            "path": "/team/{{teamId}}",
            "description": "Delete a team (only by team captain)",
            "content_type": "application/json",
            "curl_sample": f'''curl -X DELETE {base_url}/team/team123 -H "Content-Type: application/json" -d '{{"team_captain_id": "user123"}}' '''
        },
        # Event Registration Endpoints (placeholder)
        {
            "method": "POST", 
            "path": "/event-registration",
            "description": "Register a team for an event",
            "content_type": "application/json",
            "curl_sample": f'''curl -X POST {base_url}/event-registration -H "Content-Type: application/json" -d '{{"event_id": "event123", "team_id": "team456", "event_name": "Soccer Tournament", "team_name": "Lightning Bolts"}}' '''
        },
    ]

    # Generate HTML using template substitution instead of f-strings
    html_template = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>API Endpoints Dashboard</title>
        <style>
            body {{
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
                line-height: 1.6;
                color: #333;
                max-width: 1200px;
                margin: 0 auto;
                padding: 20px;
                background-color: #f5f5f5;
            }}
            .container {{
                background: white;
                padding: 30px;
                border-radius: 10px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            }}
            h1 {{
                color: #2c3e50;
                text-align: center;
                margin-bottom: 30px;
                border-bottom: 3px solid #3498db;
                padding-bottom: 10px;
            }}
            .base-url {{
                background: #ecf0f1;
                padding: 15px;
                border-radius: 5px;
                margin-bottom: 30px;
                text-align: center;
                font-family: 'Courier New', monospace;
                font-size: 14px;
                color: #555;
            }}
            .endpoint {{
                background: #f8f9fa;
                border: 1px solid #e9ecef;
                border-radius: 8px;
                padding: 20px;
                margin-bottom: 20px;
                transition: transform 0.2s;
            }}
            .endpoint:hover {{
                transform: translateY(-2px);
                box-shadow: 0 4px 15px rgba(0,0,0,0.1);
            }}
            .method {{
                display: inline-block;
                padding: 4px 12px;
                border-radius: 4px;
                font-weight: bold;
                font-size: 12px;
                text-transform: uppercase;
                margin-right: 10px;
            }}
            .method.get {{ background: #27ae60; color: white; }}
            .method.post {{ background: #3498db; color: white; }}
            .method.put {{ background: #f39c12; color: white; }}
            .method.delete {{ background: #e74c3c; color: white; }}
            .path {{
                font-family: 'Courier New', monospace;
                font-size: 16px;
                font-weight: bold;
                color: #2c3e50;
                margin-bottom: 8px;
            }}
            .description {{
                color: #555;
                margin-bottom: 8px;
            }}
            .content-type {{
                font-size: 12px;
                color: #7f8c8d;
                font-style: italic;
            }}
            .full-url {{
                font-family: 'Courier New', monospace;
                font-size: 12px;
                color: #7f8c8d;
                background: #ecf0f1;
                padding: 5px 8px;
                border-radius: 3px;
                margin-top: 10px;
                word-break: break-all;
            }}
            .curl-sample {{
                background: #2c3e50;
                color: #ecf0f1;
                padding: 10px;
                border-radius: 5px;
                margin-top: 10px;
                font-family: 'Courier New', monospace;
                font-size: 11px;
                white-space: pre-wrap;
                word-break: break-all;
                position: relative;
            }}
            .curl-sample:before {{
                content: '$ ';
                color: #3498db;
                font-weight: bold;
            }}
            .curl-label {{
                font-size: 11px;
                color: #7f8c8d;
                margin-top: 8px;
                margin-bottom: 2px;
                font-weight: bold;
            }}
            .footer {{
                text-align: center;
                margin-top: 40px;
                padding-top: 20px;
                border-top: 1px solid #e9ecef;
                color: #7f8c8d;
                font-size: 14px;
            }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🔗 API Endpoints Dashboard</h1>

            <div class="base-url">
                <strong>Base URL:</strong> {base_url}
            </div>

            <div class="endpoints">
                {endpoints_html}
            </div>

            <div class="footer">
                <p>Generated by OCR Label App API Gateway</p>
                <p>Last updated: <span id="timestamp"></span></p>
            </div>
        </div>

        <script>
            document.getElementById('timestamp').textContent = new Date().toLocaleString();
        </script>
    </body>
    </html>
    """

    # Generate endpoints HTML
    endpoints_html = ""
    for endpoint in endpoints:
        method_class = endpoint['method'].lower()
        full_url = f"{base_url}{endpoint['path']}"
        curl_sample = endpoint['curl_sample']

        endpoints_html += f"""
                <div class="endpoint">
                    <div class="method {method_class}">{endpoint['method']}</div>
                    <div class="path">{endpoint['path']}</div>
                    <div class="description">{endpoint['description']}</div>
                    <div class="content-type">Content-Type: {endpoint['content_type']}</div>
                    <div class="full-url">{full_url}</div>
                    <div class="curl-label">📋 Sample cURL Command:</div>
                    <div class="curl-sample">{curl_sample}</div>
                </div>
        """

    # Fill in the template
    html_content = html_template.format(base_url=base_url, endpoints_html=endpoints_html)

    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'text/html',
            'Cache-Control': 'no-cache'
        },
        'body': html_content
    }
