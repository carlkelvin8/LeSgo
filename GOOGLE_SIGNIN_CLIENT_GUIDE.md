# How to Enable Google Sign-In for LesGo

Hi! Para gumana ang "Sign in with Google" button sa LesGo app, kailangan lang kumuha ng isang Client ID from Google. Nakacode na lahat — config lang ang kulang.

Takes about 5 minutes. 👇

---

## Step 1: Open Google Cloud Console

Go to: https://console.cloud.google.com

Login gamit yung Google account na ginagamit mo for the project.

---

## Step 2: Select or Create a Project

Sa taas na dropdown, piliin yung project mo (or click "New Project" kung wala pa).

---

## Step 3: Enable the API

1. Sa left menu, click **APIs & Services** → **Library**
2. Search for **"Google Identity Services"** or **"People API"**
3. Click **People API** → click **Enable**

---

## Step 4: Setup OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** → click Create
3. Fill in:
   - App name: **LesGo**
   - User support email: yung email mo
   - Developer contact: yung email mo din
4. Click **Save and Continue** through the next pages (pwede skip yung scopes and test users for now)
5. Click **Publish App** if you want it available to everyone (or leave in testing mode muna)

---

## Step 5: Create the Client ID

1. Go to **APIs & Services** → **Credentials**
2. Click **+ Create Credentials** → **OAuth client ID**
3. Application type: **Web application**
4. Name: kahit ano like "LesGo Web Client"
5. Leave the redirect URIs blank for now
6. Click **Create**

Lalabas yung **Client ID** — copy mo to. Ganito ang format:
```
937689509907-abcdefghijk12345.apps.googleusercontent.com
```

---

## Step 6: Send It to Me

Just send me that Client ID string. I'll plug it into the app and tapos na!

---

## That's It! ✅

Once I have the Client ID:
- Users can sign in/sign up with their Google account
- No password needed
- Profile photo auto-loads from Google
- Works for both new and existing users

---

## FAQ

**Q: Magkano ba to?**
A: Free! Google Sign-In is free forever, walang bayad.

**Q: May limit ba sa number of users?**
A: Wala. Unlimited users for Google Sign-In.

**Q: Safe ba?**
A: Oo. Google ang nag-hahandle ng security. Yung app natin gets lang ng name at email — walang password na naka-store.

**Q: Kailangan ko pa ba i-verify yung app?**
A: Hindi muna for now. Pag production na at maraming users, may simple verification na kailangan but di naman mahirap.

---

## Summary

| Step | Action | Time |
|------|--------|------|
| 1 | Open Google Cloud Console | 30 sec |
| 2 | Enable People API | 1 min |
| 3 | Setup OAuth consent screen | 2 min |
| 4 | Create Web Client ID | 1 min |
| 5 | Send Client ID to developer | 30 sec |

**Total: ~5 minutes** ⏱️

After that, Google Sign-In works on the app! 🎉
