from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_socketio import SocketIO
from dotenv import load_dotenv
import os
from twilio.rest import Client
from twilio.base.exceptions import TwilioRestException
from pymongo import MongoClient
from datetime import datetime
import json
from sklearn.cluster import DBSCAN
import numpy as np

# Load environment variables
load_dotenv()

app = Flask(__name__)
CORS(app)
socketio = SocketIO(app, cors_allowed_origins="*")

# MongoDB setup
mongo_client = MongoClient(os.getenv('MONGODB_URI'))
db = mongo_client['disaster_help']
users_collection = db['users']
locations_collection = db['locations']
supplies_collection = db['supplies']

# Twilio setup
twilio_client = Client(os.getenv('TWILIO_ACCOUNT_SID'), os.getenv('TWILIO_AUTH_TOKEN'))

@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    user_type = data.get('userType')  # 'citizen' or 'supplier'
    phone = data.get('phone')
    
    if not phone or not user_type:
        return jsonify({'error': 'Missing required fields'}), 400
    
    # Check if user already exists
    if users_collection.find_one({'phone': phone}):
        return jsonify({'error': 'User already exists'}), 400
    
    # Create new user
    user = {
        'phone': phone,
        'userType': user_type,
        'createdAt': datetime.utcnow()
    }
    
    users_collection.insert_one(user)
    return jsonify({'message': 'User registered successfully'}), 201

@app.route('/api/send-otp', methods=['POST'])
def send_otp():
    data = request.json
    phone = data.get('phone')
    
    if not phone:
        return jsonify({'error': 'Phone number is required'}), 400
    
    try:
        # Generate and send OTP via Twilio
        verification = twilio_client.verify.services(os.getenv('TWILIO_VERIFY_SERVICE_SID')) \
            .verifications.create(to=phone, channel='sms')
        return jsonify({'message': 'OTP sent successfully'}), 200
    except TwilioRestException as e:
        return jsonify({'error': str(e)}), 400

@app.route('/api/verify-otp', methods=['POST'])
def verify_otp():
    data = request.json
    phone = data.get('phone')
    otp = data.get('otp')
    
    if not phone or not otp:
        return jsonify({'error': 'Phone and OTP are required'}), 400
    
    try:
        verification_check = twilio_client.verify.services(os.getenv('TWILIO_VERIFY_SERVICE_SID')) \
            .verification_checks.create(to=phone, code=otp)
        
        if verification_check.status == 'approved':
            user = users_collection.find_one({'phone': phone})
            return jsonify({
                'message': 'OTP verified successfully',
                'userType': user['userType'] if user else None
            }), 200
        else:
            return jsonify({'error': 'Invalid OTP'}), 400
    except TwilioRestException as e:
        return jsonify({'error': str(e)}), 400

@app.route('/api/update-location', methods=['POST'])
def update_location():
    data = request.json
    phone = data.get('phone')
    location = data.get('location')
    disaster_mode = data.get('disasterMode', False)
    
    if not phone or not location:
        return jsonify({'error': 'Phone and location are required'}), 400
    
    location_data = {
        'phone': phone,
        'location': location,
        'disasterMode': disaster_mode,
        'timestamp': datetime.utcnow()
    }
    
    locations_collection.insert_one(location_data)
    
    if disaster_mode:
        # Send SMS notification
        try:
            twilio_client.messages.create(
                body=f"Emergency Alert: User {phone} has activated disaster mode at location {location}",
                from_=os.getenv('TWILIO_PHONE_NUMBER'),
                to=phone
            )
        except TwilioRestException as e:
            print(f"Failed to send SMS: {str(e)}")
    
    return jsonify({'message': 'Location updated successfully'}), 200

@app.route('/api/get-clusters', methods=['GET'])
def get_clusters():
    # Get all active disaster mode locations
    locations = list(locations_collection.find(
        {'disasterMode': True},
        {'location': 1, '_id': 0}
    ))
    
    if not locations:
        return jsonify({'clusters': []}), 200
    
    # Convert locations to numpy array for clustering
    coords = np.array([[loc['location']['latitude'], loc['location']['longitude']] 
                       for loc in locations])
    
    # Perform DBSCAN clustering
    clustering = DBSCAN(eps=0.01, min_samples=3).fit(coords)
    
    # Group locations by cluster
    clusters = {}
    for i, label in enumerate(clustering.labels_):
        if label not in clusters:
            clusters[label] = []
        clusters[label].append({
            'latitude': coords[i][0],
            'longitude': coords[i][1]
        })
    
    return jsonify({'clusters': clusters}), 200

@app.route('/api/calculate-supplies', methods=['POST'])
def calculate_supplies():
    data = request.json
    cluster_id = data.get('clusterId')
    
    # Get number of people in cluster
    cluster_locations = locations_collection.find({
        'disasterMode': True,
        'clusterId': cluster_id
    })
    
    num_people = cluster_locations.count()
    
    # Calculate required supplies (example calculations)
    supplies = {
        'water': num_people * 4,  # 4 liters per person
        'food': num_people * 3,   # 3 meals per person
        'medical_kits': num_people // 5,  # 1 kit per 5 people
        'blankets': num_people * 1.5,  # 1.5 blankets per person
        'tents': num_people // 4  # 1 tent per 4 people
    }
    
    return jsonify({'supplies': supplies}), 200

if __name__ == '__main__':
    socketio.run(app, debug=True, host='0.0.0.0', port=5000) 