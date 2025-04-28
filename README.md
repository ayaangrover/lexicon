# Lexicon

Lexicon is an AI‑powered study companion that helps you create, import, share and study flashcards. It features:

- Smart Flashcards with text‑to‑speech support.
- AI‑generated flashcards via OpenAI.  
- Quizlet set importer (Node + Puppeteer). 
- Multiple learning modes: multiple choice & written. 
- Built‑in AI Chat tutor. 
- User auth & profile via Firebase Auth & Firestore.
- Share & collaboration. 

---

## Testing the app

Just join the TestFlight at [https://testflight.apple.com/join/15cET7KM](https://testflight.apple.com/join/15cET7KM)!

## Manual Build

### iOS App

1. Clone the repo  
2. Open `Lexicon.xcodeproj` in Xcode  
3. Add your `GoogleService-Info.plist` to `Lexicon/Lexicon/Lexicon/GoogleService-Info.plist`  
4. Install Firebase SDK via SPM if needed
5. Build & run!

### Server (Quizlet Import)

`cd server`

`npm install`

`node main.js`


![Hackatime Badge](https://hackatime-badge.hackclub.com/U07C4TK524Q/lexicon?color=3FB79A)
