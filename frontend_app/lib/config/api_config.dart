class ApiConfig {
  // For Flutter Web testing on the same machine
  static const String webBaseUrl = "http://127.0.0.1:8000";
  
  // For Android Emulator testing
  // static const String androidBaseUrl = "http://10.0.2.2:8000";
  
  // For Real Android Phone testing
  // IMPORTANT: Replace this with your laptop's actual local IP address (e.g., 192.168.1.5)
  // Ensure both your phone and laptop are connected to the same WiFi network!
  static const String phoneBaseUrl = "http://192.168.31.193:8000"; 
  // For Production Cloud Backend
  // Replace this with your actual deployed backend URL (e.g., https://stress-care.onrender.com)
  static const String prodBaseUrl = "https://your-backend-app.onrender.com";
  
  // ACTIVE BASE URL
  // Change this depending on what device you are testing on!
  // Use webBaseUrl for Web, phoneBaseUrl for real Android phone, and prodBaseUrl for production.
  static const String baseUrl = phoneBaseUrl;
}
