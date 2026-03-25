#!/bin/bash
# 1. Update the server and install Python dependencies + Apache
apt-get update -y
apt-get install python3-pip apache2 python3-requests python3-boto3 -y

# 2. Start Apache and set a temporary loading screen
systemctl start apache2
systemctl enable apache2
echo "<h1>Loading UniEvent API Processor...</h1>" > /var/www/html/index.html

# 3. Write the Python logic to a file
cat << 'EOF' > /home/ubuntu/fetch_events.py
import requests
import boto3
from io import BytesIO

def fetch_and_store_event():
    # REPLACE THESE TWO LINES WITH YOUR ACTUAL DETAILS!
    api_key = "YOUR_TICKETMASTER_KEY"
    bucket_name = "unievent-media-bucket-YOURNAME" 
    
    url = f"https://app.ticketmaster.com/discovery/v2/events.json?apikey={api_key}&size=1"
    s3_client = boto3.client('s3', region_name='ap-southeast-2') 

    response = requests.get(url)
    if response.status_code == 200:
        event = response.json().get('_embedded', {}).get('events', [])[0]
        event_title = event.get("name", "Unknown Event")
        image_url = event.get("images", [{}])[0].get("url")
        
        # Upload poster to S3
        if image_url:
            image_response = requests.get(image_url)
            if image_response.status_code == 200:
                file_name = f"posters/{event_title.replace(' ', '_')}.jpg"
                s3_client.upload_fileobj(BytesIO(image_response.content), bucket_name, file_name)

        # Generate the dynamic webpage dashboard
        html_content = f"""
        <html>
        <head>
            <title>UniEvent API</title>
            <style>
                body {{ font-family: Arial, sans-serif; text-align: center; margin-top: 50px; background-color: #f4f4f9; }}
                .event-box {{ border: 2px solid #007bff; padding: 30px; display: inline-block; background-color: white; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.1); }}
                h1 {{ color: #333; }}
                h2 {{ color: #007bff; }}
            </style>
        </head>
        <body>
            <h1>University Events Dashboard</h1>
            <div class="event-box">
                <h2>Next Event: {event_title}</h2>
                <p>Status: Event data successfully processed.</p>
                <p>Storage: Media securely stored in Amazon S3.</p>
            </div>
        </body>
        </html>
        """
        
        # Overwrite the default Apache page with our new dynamic HTML
        with open('/var/www/html/index.html', 'w') as file:
            file.write(html_content)

fetch_and_store_event()
EOF

# 4. Run the script once immediately on startup
/usr/bin/python3 /home/ubuntu/fetch_events.py