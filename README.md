# DisasterHelp - Emergency Response Management System

A comprehensive disaster management application that helps connect citizens with suppliers during natural disasters.

## Features

### Citizen Features
- Phone number-based authentication with OTP
- Real-time location sharing during disasters
- SMS notifications and updates
- Emergency mode activation

### Supplier Features
- Real-time cluster visualization on Google Maps
- AI-powered supply calculation
- Interactive chatbot for assistance
- Resource management dashboard

## Tech Stack

### Frontend
- Flutter (Dart)
- Google Maps API
- Twilio SMS Integration

### Backend
- Python Flask
- MongoDB
- Twilio Middleware
- AI/ML for clustering and supply calculation

## Setup Instructions

### Prerequisites
- Flutter SDK
- Python 3.8+
- MongoDB
- Twilio Account
- Google Maps API Key

### Installation

1. Clone the repository
2. Install Flutter dependencies:
   ```bash
   cd disaster_help_app
   flutter pub get
   ```
3. Install Python dependencies:
   ```bash
   cd backend
   pip install -r requirements.txt
   ```
4. Set up environment variables:
   - Create `.env` file in backend directory
   - Add required API keys and credentials

### Running the Application

1. Start MongoDB service
2. Start Flask backend:
   ```bash
   cd backend
   python app.py
   ```
3. Run Flutter app:
   ```bash
   cd disaster_help_app
   flutter run
   ```

## Project Structure

```
disaster_help/
├── disaster_help_app/          # Flutter frontend
│   ├── lib/
│   │   ├── screens/
│   │   ├── widgets/
│   │   ├── models/
│   │   └── services/
│   └── pubspec.yaml
├── backend/                    # Flask backend
│   ├── app.py
│   ├── config.py
│   ├── models/
│   ├── routes/
│   └── services/
└── README.md
```

## License

MIT License 