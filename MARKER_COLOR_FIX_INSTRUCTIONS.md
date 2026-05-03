# Marker Color Fix - Instructions

## Problem
The marker colors are showing CYAN instead of PURPLE/VIOLET for pickup because the browser has cached the old code.

## Solution
Both apps have been restarted with the correct marker colors:
- **Customer App**: Running on http://localhost:54005 (Terminal 28)
- **Rider App**: Running on http://localhost:54006 (Terminal 29)

## Steps to See the New Colors

1. **Open Chrome** and go to:
   - Customer: http://localhost:54005
   - Rider: http://localhost:54006

2. **Clear Browser Cache** by pressing:
   - **Ctrl + Shift + R** (Windows)
   - Or **Ctrl + F5**
   - This will do a hard refresh and clear the cached JavaScript

3. **Login** with your test account:
   - Email: carlkelvinmanahan014@gmail.com
   - Password: password123

4. **Go to Booking Screen** (LesGo or LesRide)

5. **Check the Markers**:
   - Pickup marker should be **PURPLE/VIOLET** (not cyan)
   - Destination marker should be **RED**
   - No routes/polylines should be visible

## What Was Changed

### Marker Colors (marker_utils.dart)
- Pickup: Purple/Violet `Color(0xFF7B1FA2)`
- Destination: Red `Color(0xFFEA4335)`
- Custom markers drawn with Canvas API (40x50px pin shape)
- No white circle, no border - solid colors only

### Routes Removed
- Both LesGo and LesRide maps now show `polylines: {}` (empty)
- Only markers are visible on the map

## If Colors Still Don't Change

1. **Close all Chrome tabs** for localhost:54005 and localhost:54006
2. **Clear all browser data**:
   - Chrome Settings → Privacy and Security → Clear browsing data
   - Select "Cached images and files"
   - Time range: "Last hour"
3. **Reopen** the app URLs

## Backend API
Backend is still running on Terminal 11:
- http://127.0.0.1:8000/api
