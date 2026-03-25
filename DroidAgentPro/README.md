# DroidAgent Pro — iOS Native App

Full autonomous Android pentest suite with session recording, AI agent, attack surface mapping, and findings dashboard. Native SwiftUI. Runs on jailbroken iPhone with no Apple Developer account needed.

## Build Pipeline (Free, No Mac Required)

### Step 1 — Push to GitHub
```bash
git init
git add .
git commit -m "DroidAgent Pro"
git remote add origin https://github.com/YOURNAME/droidagent.git
git push -u origin main
```

### Step 2 — GitHub Actions builds your IPA
- Go to your repo → **Actions** tab
- The `Build DroidAgent IPA` workflow runs automatically
- Wait ~5 minutes for the macOS runner to compile
- Download the `DroidAgentPro-unsigned` artifact (it's the `.ipa`)

### Step 3 — Install on Jailbroken Device

**Option A — Filza (easiest)**
1. Transfer `DroidAgentPro.ipa` to your device via SSH or AirDrop
2. Install **AppSync Unified** from Cydia/Sileo (bypasses signature check)
3. Open Filza → navigate to the `.ipa` → tap → Install

**Option B — SSH + command line**
```bash
# Make sure AppSync Unified is installed first
scp DroidAgentPro.ipa root@<device-ip>:/tmp/
ssh root@<device-ip>
# Install using appinst (install from Cydia: apt install appinst)
appinst /tmp/DroidAgentPro.ipa
```

**Option C — ideviceinstaller**
```bash
# From your computer (any OS)
pip install ideviceinstaller  # or brew install libimobiledevice
ideviceinstaller -i DroidAgentPro.ipa
```

### Step 4 — Configure the App
Open DroidAgent Pro → tap the gear icon:
- **Suite API**: Your pentest suite REST endpoint (e.g. `http://192.168.1.x:8080`)
- **Target Package**: e.g. `com.target.app`
- **Claude API Key**: Your `sk-ant-...` key

---

## Suite API Contract

Your suite needs to implement these endpoints:

```
POST /api/drozer/execute
Body: { "tool": "tool_name", "args": { ...tool_args } }
Response: { ...tool_result }

POST /api/recorder/start
Body: { "package": "com.target.app" }
Response: { "session_id": "..." }

GET /api/recorder/events/live
Response: { "events": [ { "type": "http", "summary": "...", "ts": "..." } ] }

POST /api/recorder/stop
Response: {
  "session_id": "...",
  "traffic":  [ { "method":"GET", "url":"...", "auth":true } ],
  "intents":  [ { "action":"...", "component":"..." } ]
}
```

---

## Project Structure

```
DroidAgentPro/
├── .github/workflows/build.yml     ← GitHub Actions CI
├── project.yml                      ← XcodeGen config
├── Sources/DroidAgentPro/
│   ├── DroidAgentProApp.swift       ← App entry point
│   ├── ContentView.swift            ← Tab container
│   ├── Models.swift                 ← All data models
│   ├── AgentEngine.swift            ← Claude API + tool execution
│   ├── DesignSystem.swift           ← Reusable UI components
│   ├── Info.plist
│   └── Views/
│       ├── DashboardView.swift      ← Home + stats
│       ├── RecorderView.swift       ← Session recording
│       ├── SurfaceView.swift        ← Attack surface map
│       ├── AgentView.swift          ← Live agent terminal
│       └── FindingsView.swift       ← Vulnerability findings
```

---

## Features

| Feature | Description |
|---|---|
| Session Recorder | Frida-based recording of all app activity during real user flows |
| Attack Surface Map | Auto-populated from recordings and recon, with per-item attack buttons |
| AI Agent Loop | Claude runs 60-turn autonomous attack chain with 44 drozer/Frida tools |
| JWT Attacks | Algorithm confusion, none-alg, brute force, claim injection |
| IDOR Testing | Enumeration, horizontal/vertical privilege escalation |
| Traffic Fuzzing | SQLi, XSS, traversal, format strings, overflow |
| File Upload Attacks | MIME bypass, polyglots, zip bombs, EXIF injection |
| Frida Integration | SSL unpin, crypto trace, biometric bypass, memory dump |
| Findings Dashboard | Severity-filtered, MASVS-mapped, PoC + remediation |
| JSON Report Export | Share pentest report via iOS share sheet |

---

## Jailbreak Requirements
- AppSync Unified (Cydia/Sileo) — allows unsigned IPA installation
- Optional: `appinst` package for CLI installation
- iOS 16+ recommended (SwiftUI features)
