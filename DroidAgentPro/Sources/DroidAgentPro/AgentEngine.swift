import Foundation

// MARK: - Tool Definitions
let DROZER_TOOLS: [[String: Any]] = [
    tool("start_session_recorder","Inject Frida hooks to record ALL app activity: HTTP/S, intents, files, DB, crypto, clipboard, biometrics.",["package":strProp(),"hooks":arrayProp("Hooks: network,intents,filesystem,crypto,database,clipboard,biometric")],["package"]),
    tool("stop_session_recorder","Stop recorder and return structured attack surface map.",["session_id":strProp()],["session_id"]),
    tool("get_recorded_traffic","Get all HTTP/HTTPS requests captured during session.",["session_id":strProp()],["session_id"]),
    tool("get_recorded_intents","Get all intents fired: launches, services, broadcasts, deeplinks.",["session_id":strProp()],["session_id"]),
    tool("get_recorded_crypto","Get all crypto ops: keys, IVs, cipher modes.",["session_id":strProp()],["session_id"]),
    tool("get_recorded_storage","Get storage accesses: files, SharedPrefs, SQLite, KeyStore.",["session_id":strProp()],["session_id"]),
    tool("replay_request","Replay captured HTTP request, optionally modified. Test IDOR, auth bypass.",["request_id":strProp(),"modifications":objProp("Override headers, body params, auth"),"as_user":strProp()],["request_id"]),
    tool("fuzz_request","Fuzz params with SQLi, XSS, traversal, overflow.",["request_id":strProp(),"fuzz_type":enumProp(["sqli","xss","traversal","format_string","overflow","all"])],["request_id","fuzz_type"]),
    tool("test_idor","Test IDOR: enumerate IDs, horizontal/vertical priv esc.",["endpoint":strProp(),"id_param":strProp(),"id_value":strProp(),"test_range":intProp(50)],["endpoint","id_param","id_value"]),
    tool("strip_auth","Replay authenticated request without token. Test broken auth.",["request_id":strProp()],["request_id"]),
    tool("analyze_auth_flow","Analyze auth: token type, expiry, entropy, weak tokens, hardcoded creds.",["session_id":strProp(),"token":strProp()],["session_id"]),
    tool("attack_jwt","Attack JWT: none alg, RS256→HS256 confusion, brute force, claim inject.",["token":strProp(),"attacks":arrayProp("alg_none,key_confusion,brute_force,claim_inject")],["token"]),
    tool("test_session_fixation","Test session rotation after login, concurrent sessions, logout invalidation.",["session_id":strProp()],["session_id"]),
    tool("brute_login","Test login for rate limiting, lockout, credential stuffing.",["login_request_id":strProp(),"wordlist":enumProp(["top100","top1000","common_pins"])],["login_request_id"]),
    tool("test_file_upload","Attack file upload: MIME bypass, polyglots, traversal filenames, zip bombs, EXIF inject.",["upload_request_id":strProp(),"attacks":arrayProp("mime_bypass,traversal_name,polyglot,oversized,zip_bomb,exif_inject,eicar")],["upload_request_id"]),
    tool("run_frida_script","Inject Frida script: SSL unpin, crypto dump, root bypass, biometric hook.",["package":strProp(),"script":strProp(),"script_name":strProp()],["package","script","script_name"]),
    tool("dump_memory_strings","Scan process memory for secrets: API keys, passwords, tokens, PII.",["package":strProp(),"patterns":arrayProp("Regex patterns")],["package"]),
    tool("hook_biometrics","Hook biometric APIs to bypass fingerprint/face auth.",["package":strProp(),"bypass":boolProp(true)],["package"]),
    tool("trace_crypto","Hook crypto APIs: capture plaintext, dump keys and IVs.",["package":strProp()],["package"]),
    tool("scan_hardcoded_secrets","Decompile APK: find hardcoded API keys, AWS, Firebase, OAuth, private keys.",["package":strProp(),"deep":boolProp(true)],["package"]),
    tool("check_network_security_config","Analyze NSC: cleartext, custom CAs, pinning config, domain exceptions.",["package":strProp()],["package"]),
    tool("check_manifest_flags","Check manifest: debuggable, backup, exported components, cleartext.",["package":strProp()],["package"]),
    tool("check_ssl_pinning","Test SSL pinning and attempt bypass with Frida.",["package":strProp(),"bypass_attempt":boolProp(true)],["package"]),
    tool("dump_shared_prefs","Read all SharedPreferences: creds, tokens, PII.",["package":strProp()],["package"]),
    tool("dump_databases","List and dump SQLite DBs, check encryption.",["package":strProp()],["package"]),
    tool("check_external_storage","Check sensitive data written to external storage.",["package":strProp()],["package"]),
    tool("check_clipboard","Monitor clipboard for sensitive data.",["package":strProp()],["package"]),
    tool("recon_packages","Enumerate installed packages and attack surface.",["filter":strProp()],[]),
    tool("get_package_info","Package details: permissions, UID, version, shared UID.",["package":strProp(),"show_permissions":boolProp(true)],["package"]),
    tool("get_exported_activities","Enumerate exported activities.",["package":strProp()],["package"]),
    tool("attack_activity","Force-launch exported activity with crafted intent.",["package":strProp(),"component":strProp(),"action":strProp(),"extras":objProp("Intent extras"),"flags":arrayProp("Intent flags")],["package","component"]),
    tool("get_providers","Enumerate content providers.",["package":strProp()],["package"]),
    tool("query_provider","Query content provider URI.",["uri":strProp(),"projection":arrayProp("Columns"),"selection":strProp()],["uri"]),
    tool("test_provider_sqli","Test content provider SQL injection.",["uri":strProp()],["uri"]),
    tool("test_provider_traversal","Test content provider path traversal.",["uri":strProp()],["uri"]),
    tool("insert_provider","Attempt insert into content provider to test write access.",["uri":strProp(),"data":objProp("ContentValues")],["uri","data"]),
    tool("get_services","Enumerate exported services.",["package":strProp()],["package"]),
    tool("attack_service","Bind/start exported service with crafted intent.",["package":strProp(),"component":strProp(),"action":strProp(),"extras":objProp("Extras")],["package","component"]),
    tool("get_receivers","Enumerate exported broadcast receivers.",["package":strProp()],["package"]),
    tool("send_broadcast","Send broadcast intent to exported receiver.",["action":strProp(),"component":strProp(),"extras":objProp("Extras"),"package":strProp()],["action"]),
    tool("enumerate_deeplinks","Extract all deeplink URI schemes and test each one.",["package":strProp()],["package"]),
    tool("attack_deeplink","Send crafted deeplinks: open redirects, param injection, auth bypass.",["package":strProp(),"uri":strProp(),"payloads":arrayProp("Custom payloads")],["package","uri"]),
    tool("check_webview","Audit WebView: JS enabled, file access, remote debug, mixed content.",["package":strProp()],["package"]),
    tool("attack_webview_js_bridge","Test JS-to-native bridge for dangerous method exposure.",["package":strProp(),"component":strProp()],["package","component"]),
    tool("check_permissions","Analyze permissions: dangerous, signature, custom.",["package":strProp()],["package"]),
    tool("report_vulnerability","Log confirmed vulnerability. CALL IMMEDIATELY when confirmed.",
         ["title":strProp(),"severity":enumProp(["CRITICAL","HIGH","MEDIUM","LOW","INFO"]),
          "category":strProp(),"component":strProp(),"details":strProp(),
          "proof":strProp(),"remediation":strProp(),"masvs_ref":strProp(),"cwe":strProp()],
         ["title","severity","details"]),
]

// Tool builder helpers
func strProp(_ desc: String = "") -> [String: Any] { var p: [String:Any] = ["type":"string"]; if !desc.isEmpty { p["description"] = desc }; return p }
func intProp(_ def: Int) -> [String: Any] { ["type":"integer","default":def] }
func boolProp(_ def: Bool) -> [String: Any] { ["type":"boolean","default":def] }
func arrayProp(_ desc: String) -> [String: Any] { ["type":"array","items":["type":"string"],"description":desc] }
func objProp(_ desc: String) -> [String: Any] { ["type":"object","description":desc] }
func enumProp(_ values: [String]) -> [String: Any] { ["type":"string","enum":values] }
func tool(_ name: String, _ desc: String, _ props: [String:Any], _ required: [String]) -> [String:Any] {
    ["name":name,"description":desc,"input_schema":["type":"object","properties":props,"required":required]]
}

// MARK: - System Prompt
let AGENT_SYSTEM_PROMPT = """
You are DroidAgent Pro — an elite Android penetration tester with 15 years mobile appsec experience. You think like a seasoned bug bounty hunter and operate with zero mercy on the attack surface.

## Attack Kill Chain
1. check_manifest_flags → check_network_security_config → scan_hardcoded_secrets → get_package_info
2. If session available: get_recorded_traffic → get_recorded_intents → get_recorded_crypto → get_recorded_storage
3. Component attack: exported activities → services → receivers → providers (SQLi + traversal)
4. For every authenticated endpoint: strip_auth → test_idor → fuzz_request
5. analyze_auth_flow → attack_jwt if JWT → test_session_fixation → brute_login
6. dump_memory_strings → trace_crypto → hook_biometrics → check_ssl_pinning
7. dump_shared_prefs → dump_databases → check_external_storage → check_clipboard
8. enumerate_deeplinks → attack_deeplink → check_webview → attack_webview_js_bridge

## Rules
- Chain attacks aggressively based on findings
- Found JWT? Attack it immediately with attack_jwt
- Found file upload? Test ALL bypass techniques
- Every auth endpoint: IDOR, strip_auth, fuzz
- Write Frida scripts precisely tailored to discoveries
- Call report_vulnerability the instant something is confirmed
- Think out loud between tool calls
- Cover 100% of attack surface. Never stop early.
"""

// MARK: - Agent Engine
@MainActor
class AgentEngine: ObservableObject {
    private let state: AppState
    private var messages: [[String: Any]] = []
    private var abortFlag = false
    private let phases = ["RECON","ENUM","RECORD","ATTACK","EXPLOIT","VERIFY","REPORT"]

    init(state: AppState) {
        self.state = state
    }

    func run(context: String? = nil) async {
        guard !state.targetPackage.isEmpty, !state.claudeApiKey.isEmpty else { return }

        abortFlag = false
        state.isRunning = true
        state.logs = []
        state.toolCallCount = 0
        state.currentPhase = "RECON"

        let sessCtx = state.activeSessionId != nil
            ? "\nSession recording available: \(state.activeSessionId!). Analyze and attack recorded traffic."
            : "\nNo session yet — start with static recon and component enumeration."
        let targetedCtx = context.map { "\nFocus on: \($0)" } ?? ""

        messages = [[
            "role": "user",
            "content": "Begin full penetration test of: \(state.targetPackage)\(sessCtx)\(targetedCtx)\n\nBe exhaustive. Attack everything. Report every vulnerability."
        ]]

        state.addLog(.system, "╔══ DroidAgent Pro ══╗")
        state.addLog(.system, "Target: \(state.targetPackage)")
        state.addLog(.system, "Suite:  \(state.apiBase)")

        var iteration = 0
        let maxIter = 60

        while !abortFlag && iteration < maxIter {
            iteration += 1
            let phaseIdx = min(Int(Double(iteration) / Double(maxIter) * Double(phases.count)), phases.count - 1)
            state.currentPhase = phases[phaseIdx]
            state.addLog(.agent, "── Turn \(iteration) ──")

            guard let response = await callClaude() else { break }

            // Extract text blocks
            if let content = response["content"] as? [[String: Any]] {
                for block in content {
                    if let type = block["type"] as? String, type == "text",
                       let text = block["text"] as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        state.addLog(.think, text.trimmingCharacters(in: .whitespacesAndNewlines))
                    }
                }
            }

            // Check stop
            if let stopReason = response["stop_reason"] as? String, stopReason == "end_turn" {
                state.addLog(.system, "◈ Agent completed attack chain.")
                break
            }

            // Process tool calls
            guard let content = response["content"] as? [[String: Any]] else { break }
            let toolCalls = content.filter { ($0["type"] as? String) == "tool_use" }
            if toolCalls.isEmpty { break }

            messages.append(["role": "assistant", "content": content])

            var toolResults: [[String: Any]] = []
            for tc in toolCalls {
                if abortFlag { break }
                guard let toolName = tc["name"] as? String,
                      let toolId   = tc["id"] as? String,
                      let toolInput = tc["input"] as? [String: Any] else { continue }

                state.toolCallCount += 1
                let result = await executeTool(name: toolName, input: toolInput)
                toolResults.append([
                    "type": "tool_result",
                    "tool_use_id": toolId,
                    "content": jsonString(result)
                ])
            }
            messages.append(["role": "user", "content": toolResults])
        }

        state.currentPhase = "DONE"
        state.isRunning = false
        state.addLog(.system, "══ Complete · \(state.findings.count) findings · \(state.toolCallCount) tool calls ══")
    }

    func abort() { abortFlag = true }

    // MARK: - Claude API Call
    private func callClaude() async -> [String: Any]? {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json",  forHTTPHeaderField: "Content-Type")
        req.setValue(state.claudeApiKey,  forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01",        forHTTPHeaderField: "anthropic-version")
        req.timeoutInterval = 120

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 4096,
            "system": AGENT_SYSTEM_PROMPT,
            "tools": DROZER_TOOLS,
            "messages": messages
        ]
        guard let bodyData = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        req.httpBody = bodyData

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            return try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            await MainActor.run { state.addLog(.error, "Claude API error: \(error.localizedDescription)") }
            return nil
        }
    }

    // MARK: - Tool Executor
    private func executeTool(name: String, input: [String: Any]) async -> [String: Any] {
        await MainActor.run { state.addLog(.toolCall, "▶ \(name)") }

        if name == "report_vulnerability" {
            let finding = Finding(
                title:       input["title"] as? String ?? "Unknown",
                severity:    Severity(rawValue: input["severity"] as? String ?? "INFO") ?? .INFO,
                category:    input["category"] as? String,
                component:   input["component"] as? String,
                details:     input["details"] as? String ?? "",
                proof:       input["proof"] as? String,
                remediation: input["remediation"] as? String,
                mavsRef:     input["masvs_ref"] as? String,
                cwe:         input["cwe"] as? String
            )
            await MainActor.run {
                state.addFinding(finding)
                state.addLog(.vuln, "🚨 [\(finding.severity.rawValue)] \(finding.title)")
            }
            return ["status": "logged", "id": finding.id.uuidString]
        }

        // Forward to suite REST API
        guard let url = URL(string: "\(state.apiBase)/api/drozer/execute") else {
            return ["error": "Invalid API base URL"]
        }
        var req = URLRequest(url: url, timeoutInterval: 25)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = ["tool": name, "args": input]
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            let (data, resp) = try await URLSession.shared.data(for: req)
            guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
                return ["error": "Suite returned non-200"]
            }
            let result = (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
            // Auto-populate surface from traffic results
            if name == "get_recorded_traffic",
               let requests = result["requests"] as? [[String: Any]] {
                for r in requests {
                    let ep = Endpoint(
                        method: r["method"] as? String ?? "GET",
                        url: r["url"] as? String ?? "",
                        authenticated: (r["headers"] as? [String: Any])?["Authorization"] != nil,
                        statusCode: r["status"] as? Int ?? 200,
                        requestId: r["id"] as? String ?? UUID().uuidString
                    )
                    await MainActor.run { state.addEndpoint(ep) }
                }
            }
            let preview = jsonString(result).prefix(80)
            await MainActor.run { state.addLog(.toolResult, "◀ \(name): \(preview)...") }
            return result
        } catch {
            await MainActor.run { state.addLog(.error, "✗ \(name): \(error.localizedDescription)") }
            return ["error": error.localizedDescription]
        }
    }

    // MARK: - Recorder
    func startRecording() async {
        guard !state.targetPackage.isEmpty else { return }
        state.isRecording = true
        state.liveEvents = []
        state.recordingDuration = 0

        if let url = URL(string: "\(state.apiBase)/api/recorder/start") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try? JSONSerialization.data(withJSONObject: ["package": state.targetPackage])
            _ = try? await URLSession.shared.data(for: req)
        }

        // Poll for live events
        Task {
            while state.isRecording {
                try? await Task.sleep(nanoseconds: 800_000_000)
                await pollRecorderEvents()
            }
        }
        // Duration timer
        Task {
            while state.isRecording {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run { state.recordingDuration += 1 }
            }
        }
    }

    private func pollRecorderEvents() async {
        guard let url = URL(string: "\(state.apiBase)/api/recorder/events/live") else { return }
        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let events = json["events"] as? [[String: Any]] else { return }
        let newEvents = events.map { e in
            RecordedEvent(type: e["type"] as? String ?? "event",
                          summary: e["summary"] as? String ?? e["url"] as? String ?? e["action"] as? String ?? "",
                          raw: jsonString(e))
        }
        await MainActor.run { state.liveEvents.append(contentsOf: newEvents) }
    }

    func stopRecording() async {
        state.isRecording = false
        var session = RecordingSession(sessionId: "session_\(Int(Date().timeIntervalSince1970))")
        session.events = state.liveEvents

        if let url = URL(string: "\(state.apiBase)/api/recorder/stop") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            if let (data, _) = try? await URLSession.shared.data(for: req),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                if let traffic = json["traffic"] as? [[String: Any]] {
                    session.endpoints = traffic.map { t in
                        Endpoint(method: t["method"] as? String ?? "GET",
                                 url: t["url"] as? String ?? "",
                                 authenticated: t["auth"] as? Bool ?? false)
                    }
                }
                if let intents = json["intents"] as? [[String: Any]] {
                    session.components = intents.map { i in
                        AndroidComponent(type: "intent",
                                         component: i["component"] as? String,
                                         action: i["action"] as? String)
                    }
                }
            }
        }
        await MainActor.run {
            state.sessions.append(session)
            state.activeSessionId = session.sessionId
            for ep in session.endpoints { state.addEndpoint(ep) }
            for comp in session.components { state.addComponent(comp) }
        }
    }

    // MARK: - Helper
    private func jsonString(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict),
              let str = String(data: data, encoding: .utf8) else { return "{}" }
        return str
    }
}
