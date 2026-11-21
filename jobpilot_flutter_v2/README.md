# JobPilot AI — Flutter Android App

This is the native Flutter Android client for the supplied JobPilot project. The existing Django backend is preserved and called through its REST API.

## What is included

- Email/password sign-in and account registration
- Dashboard metrics and AI readiness
- Job search and saved-job actions
- Application tracker
- PDF/DOCX resume upload and analysis action
- AI Career Agent using the existing conversation/message API
- Interview, skills roadmap, reminders and profile entry points
- Runtime backend URL configuration on the login screen
- GitHub Actions workflow to build a release APK without Android Studio

## Build the APK without installing Android Studio

1. Put the contents of this folder into a GitHub repository (or use the existing private `jobpilot` repository).
2. Open the repository's **Actions** tab.
3. Select **Build JobPilot Android APK**.
4. Click **Run workflow** and wait for it to finish.
5. Open the completed workflow run and download the `JobPilot-Android-APK` artifact.
6. Extract the artifact ZIP. It contains `app-release.apk`.

A GitHub Actions runner supplies Flutter and Android build tools. No Android Studio is needed on your Windows computer.

## Connect your hosted backend after installing

1. Host the existing Django backend using the original project's deployment configuration.
2. Open JobPilot AI on the phone.
3. In the **JobPilot server** field, enter the public HTTPS base URL only, for example:
   `https://your-jobpilot-server.example`
4. Do not append `/api` — the app adds `/api` automatically.
5. Sign in or create an account.

The app does not contain a hard-coded local `localhost` URL. The server URL is saved securely in the app's preferences and can be edited from the sign-in screen.

## Important AI note

The original backend uses Ollama when it is reachable and falls back to its built-in rules when Ollama is unavailable. A model running only on your personal PC is not automatically reachable by a hosted backend. To get full free-form AI responses in the released app, Ollama must be made available to the hosted backend through a secure, reachable service. Do not expose Ollama directly to the public internet without authentication and network protection.

## Important data note

The original Django backend stores uploaded resumes under its media directory. Before real users upload important documents, configure persistent media storage and database backups on the hosting provider. A temporary container filesystem can lose uploaded files on redeploy/restart.

## Project relationship

- `lib/`: Flutter app
- `lib/services/api.dart`: API client, token storage and editable backend URL
- `.github/workflows/build-apk.yml`: cloud Android release build
- The original Django backend remains in the original `jobpilot` project ZIP; it is not duplicated in this Flutter-only folder.
