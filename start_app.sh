#!/bin/bash
echo "Starting Backend..."
cd backend
pkill -f uvicorn
source venv/bin/activate
uvicorn main:app --host 0.0.0.0 --port 8000 --reload &
sleep 2

echo "Starting Frontend on EXACTLY port 3000..."
cd ../frontend_app
flutter run -d chrome --web-port=3000
