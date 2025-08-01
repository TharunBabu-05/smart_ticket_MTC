# 🔍 Session Debugging Guide

## Current Issue: Realtime Database Not Updating

### Expected Session Data:
```
gyro_sessions/
  ├── sess_1753973822_XXXX/
  │   ├── sessionId: "sess_1753973822_XXXX"
  │   ├── ticketId: "TKT_175397382226206515"
  │   ├── userId: "FH5pSFPHxgbJL55lpEJ2Ac9GAIg1"
  │   ├── fromStop: "Central Station"
  │   ├── toStop: "Tambaram" 
  │   ├── startTime: 1753973822000
  │   ├── status: "active"
  │   └── sensorData: {...}
```

### Debugging Steps:

1. **Refresh Firebase Console**
   - Go to Realtime Database
   - Press F5 or refresh page
   - Look for newer session IDs

2. **Check Session Path**
   - Look for sessions starting with `sess_17539738`
   - These should match your current ticket time

3. **Verify App Logs**
   - Look for: "✅ Session created in Gyro App for cross-platform detection"
   - If missing, session creation is failing

### If Session Creation is Failing:

#### Possible Causes:
1. **Firebase Rules Issue** - Our recent rule changes might be too restrictive
2. **App Permission Issue** - Secondary Firebase app might not have proper permissions  
3. **Path Mismatch** - Session being created in different location
4. **Silent Failure** - Error not being caught/logged

#### Quick Fix:
Try booking another ticket and immediately check:
1. Firebase Console Realtime Database
2. Look for sessions with current timestamp
3. If still showing old data, there's a session creation bug

### Manual Test:
Book a new ticket and check if you see:
- New session in `gyro_sessions/sess_[NEW_TIMESTAMP]_XXX`
- Session data matching your current route
- Active status for new session only
