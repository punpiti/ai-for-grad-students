document.documentElement.classList.add("js");

function getCookie(name) {
  const prefix = `${encodeURIComponent(name)}=`;
  const item = document.cookie.split("; ").find((part) => part.startsWith(prefix));
  return item ? decodeURIComponent(item.slice(prefix.length)) : null;
}

function setCookie(name, value) {
  const secure = location.protocol === "https:" ? "; Secure" : "";
  document.cookie = `${encodeURIComponent(name)}=${encodeURIComponent(value)}; Max-Age=31536000; Path=/; SameSite=Lax${secure}`;
}

function getPreference(name) {
  return getCookie(name) || localStorage.getItem(name);
}

function setPreference(name, value) {
  setCookie(name, value);
  // Browsers do not persist cookies for file:// pages; this also provides a
  // fallback when cookies are blocked during local classroom testing.
  localStorage.setItem(name, value);
}

const researchProfileKey = "ai-research-profile:v1";
const researchProfileFields = [
  ["thai_name", "ชื่อภาษาไทย", "text"],
  ["english_name", "ชื่อภาษาอังกฤษ", "text"],
  ["affiliation", "สังกัด/หน่วยงาน", "text"],
  ["role", "บทบาทหรือระดับการศึกษา", "text"],
  ["field", "สาขาหรือความเชี่ยวชาญ", "text"],
  ["advisor", "อาจารย์ที่ปรึกษา (ถ้ามีและยินยอมระบุ)", "text"],
  ["research_topic", "หัวข้อวิจัยหรือประเด็นที่สนใจ", "textarea"],
  ["research_stage", "ระยะของงานตอนนี้", "text"],
  ["desired_output", "ผลงานที่อยากได้", "text"],
  ["target_venue", "วารสาร/การประชุม/แหล่งเผยแพร่ที่สนใจ", "text"],
  ["intended_audience", "กลุ่มผู้อ่านหรือผู้ใช้ผล", "text"],
  ["working_language", "ภาษาที่ต้องการใช้ทำงาน", "text"],
  ["constraints", "ข้อจำกัดด้านเวลา เครื่องมือ หรือข้อมูล", "textarea"],
  ["data_sensitivity", "ระดับความอ่อนไหวของข้อมูล", "text"],
];

function loadResearchProfile() {
  try { return JSON.parse(localStorage.getItem(researchProfileKey) || "{}"); }
  catch { return {}; }
}

function saveResearchProfile(profile) {
  localStorage.setItem(researchProfileKey, JSON.stringify(profile));
}

function hasResearchProfile(profile) {
  return researchProfileFields.some(([key]) => String(profile[key] || "").trim());
}

const profileKeysByModule = {
  1: researchProfileFields.map(([key]) => key),
  2: ["role", "affiliation", "field", "research_topic", "research_stage", "working_language", "data_sensitivity"],
  3: ["field", "research_topic", "research_stage", "desired_output", "intended_audience", "constraints", "data_sensitivity"],
  4: ["field", "research_topic", "target_venue", "intended_audience", "working_language", "data_sensitivity"],
  5: ["field", "research_topic", "research_stage", "target_venue", "intended_audience", "constraints", "data_sensitivity"],
  6: ["field", "research_topic", "research_stage", "target_venue", "constraints", "data_sensitivity"],
  7: ["field", "research_topic", "desired_output", "intended_audience", "constraints", "data_sensitivity"],
  8: ["affiliation", "field", "target_venue", "intended_audience", "desired_output", "working_language", "constraints", "data_sensitivity"],
  9: ["role", "field", "research_topic", "research_stage", "desired_output", "working_language", "constraints", "data_sensitivity"],
};

function currentModuleNumber() {
  if (location.pathname.endsWith("prepare.html")) return 1;
  const match = location.pathname.match(/module-(\d+)\.html$/);
  return match ? Number(match[1]) : 1;
}

function profileContextText(profile) {
  const allowed = new Set(profileKeysByModule[currentModuleNumber()] || []);
  const lines = researchProfileFields
    .filter(([key]) => allowed.has(key) && String(profile[key] || "").trim())
    .map(([key, label]) => `- ${label}: ${String(profile[key]).trim()}`);
  return lines.length ? `[RESEARCH_PROFILE_CONTEXT]\n${lines.join("\n")}\n[/RESEARCH_PROFILE_CONTEXT]` : "";
}

function renderResearchProfile(host, forceEdit = false) {
  const profile = loadResearchProfile();
  const hasProfile = hasResearchProfile(profile);
  const relevantKeys = new Set(profileKeysByModule[currentModuleNumber()] || []);
  const hasRelevantProfile = researchProfileFields.some(([key]) => relevantKeys.has(key) && String(profile[key] || "").trim());
  const editMode = forceEdit || host.dataset.mode === "edit" || !hasRelevantProfile;
  if (!editMode) {
    const rows = researchProfileFields
      .filter(([key]) => relevantKeys.has(key) && String(profile[key] || "").trim())
      .map(([key, label]) => `<div><dt>${label}</dt><dd>${String(profile[key]).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")}</dd></div>`)
      .join("");
    host.innerHTML = `<div class="profile-status"><div><p class="eyebrow">Saved research context</p><h3>โมดูลนี้จะใช้ข้อมูลที่คุณบันทึกไว้</h3><p>ข้อมูลมาจาก Research Profile ใน browser นี้ และเลือกใช้เฉพาะช่องที่เกี่ยวข้องกับโมดูล</p></div><div class="profile-summary-actions"><button type="button" class="button primary" data-profile-copy>คัดลอกบริบทให้ AI</button><button type="button" class="button secondary" data-profile-edit>แก้ไขข้อมูล</button><small aria-live="polite"></small></div></div><dl class="profile-summary">${rows}</dl>`;
    host.querySelector("[data-profile-edit]").addEventListener("click", () => renderResearchProfile(host, true));
    host.querySelector("[data-profile-copy]").addEventListener("click", async () => {
      await navigator.clipboard.writeText(profileContextText(profile));
      host.querySelector(".profile-summary-actions small").textContent = "คัดลอกแล้ว";
    });
    return;
  }
  const fields = researchProfileFields.map(([key, label, type]) => {
    const value = String(profile[key] || "").replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
    const control = type === "textarea" ? `<textarea name="${key}" rows="3">${value}</textarea>` : `<input name="${key}" value="${value}">`;
    return `<label><span>${label}</span>${control}</label>`;
  }).join("");
  host.innerHTML = `<div class="profile-status"><div><p class="eyebrow">Research Profile · saved locally</p><h3>${hasProfile ? "เติมหรือแก้ไขข้อมูลที่ใช้ร่วมกัน" : "ตอบคำถามเดียวกับ Module 1 ก่อนเริ่ม"}</h3><p>กรอกเท่าที่จำเป็น ช่องใดไม่เกี่ยวข้องให้เว้นว่าง ข้อมูลจะเก็บเฉพาะ browser นี้</p></div></div><form class="profile-form">${fields}<div class="profile-actions"><button class="button primary" type="submit">บันทึกในเครื่อง</button>${hasRelevantProfile ? '<button class="button secondary" type="button" data-profile-cancel>ยกเลิก</button>' : ""}<small aria-live="polite"></small></div></form>`;
  const form = host.querySelector("form");
  form.addEventListener("submit", (event) => {
    event.preventDefault();
    const next = {};
    for (const [key] of researchProfileFields) next[key] = form.elements[key].value.trim();
    saveResearchProfile(next);
    document.dispatchEvent(new CustomEvent("research-profile-updated", { detail: next }));
    for (const item of document.querySelectorAll("[data-research-profile]")) renderResearchProfile(item);
  });
  const cancel = host.querySelector("[data-profile-cancel]");
  if (cancel) cancel.addEventListener("click", () => renderResearchProfile(host));
}

for (const host of document.querySelectorAll("[data-research-profile]")) renderResearchProfile(host);

const links = document.querySelectorAll('a[href^="#"]');
for (const link of links) {
  link.addEventListener("click", () => {
    const target = document.querySelector(link.getAttribute("href"));
    if (target) target.setAttribute("tabindex", "-1");
  });
}

const markdownArticle = document.querySelector(".markdown-body");
const markdownToc = document.querySelector(".markdown-toc ol");
if (markdownArticle && markdownToc) {
  for (const heading of markdownArticle.querySelectorAll("h2")) {
    if (!heading.id) heading.id = heading.textContent.trim().toLowerCase().replace(/\s+/g, "-");
    const item = document.createElement("li");
    const link = document.createElement("a");
    link.href = `#${heading.id}`;
    link.textContent = heading.textContent;
    item.appendChild(link);
    markdownToc.appendChild(item);
  }
}
const platformButtons = document.querySelectorAll("[data-platform-button]");
const platformPanels = document.querySelectorAll("[data-platform-panel]");
function selectPlatform(name, persist = false) {
  for (const button of platformButtons) button.setAttribute("aria-pressed", String(button.dataset.platformButton === name));
  for (const panel of platformPanels) panel.hidden = panel.dataset.platformPanel !== name;
  if (persist) setPreference("ai-research-platform", name);
}
if (platformButtons.length) {
  const savedValue = getPreference("ai-research-platform");
  const saved = ["windows", "macos", "linux"].includes(savedValue) ? savedValue : null;
  const detected = /Mac/.test(navigator.platform) ? "macos" : /Win/.test(navigator.platform) ? "windows" : "linux";
  selectPlatform(saved || detected);
  for (const button of platformButtons) button.addEventListener("click", () => selectPlatform(button.dataset.platformButton, true));
}

const promptProfileMap = {
  THAI_NAME: "thai_name",
  ENGLISH_NAME: "english_name",
  AFFILIATION: "affiliation",
  ROLE: "role",
  RESEARCH_FIELD: "field",
  ADVISOR: "advisor",
  RESEARCH_TOPIC_OR_RQ: "research_topic",
  TARGET_VENUE: "target_venue",
  INTENDED_AUDIENCE: "intended_audience",
  RESEARCH_QUESTION: "research_topic",
  OUTPUT_AUDIENCE: "intended_audience",
  OUTPUT_TYPE: "desired_output",
  DATA_CLASSIFICATION: "data_sensitivity",
  WORKING_LANGUAGE: "working_language",
  CONSTRAINTS: "constraints",
};

function applyProfileToPrompt(text, profile) {
  text = text.replace(/^\[RESEARCH_PROFILE_CONTEXT\][\s\S]*?^\[\/RESEARCH_PROFILE_CONTEXT\]\n*/m, "");
  for (const [variable, profileKey] of Object.entries(promptProfileMap)) {
    const value = String(profile[profileKey] || "").trim();
    if (value) text = text.replace(new RegExp(`(${variable}:\\s*)(?:\\{\\{[^\\n]*\\}\\}|[^\\n]*)`), `$1${value}`);
  }
  const context = profileContextText(profile);
  return context ? `${context}\n\n${text}` : text;
}

for (const [index, block] of [...document.querySelectorAll(".prompt-template")].entries()) {
  const code = block.querySelector("code");
  if (!code) continue;
  const initialValue = code.textContent;
  const storageKey = `ai-research-prompt:${location.pathname}:${index}`;
  const savedValue = localStorage.getItem(storageKey);
  const editor = document.createElement("textarea");
  editor.className = "prompt-editor";
  editor.setAttribute("aria-label", "แก้ไข Prompt ก่อนส่งให้ AI");
  editor.spellcheck = false;
  editor.value = savedValue ?? applyProfileToPrompt(initialValue, loadResearchProfile());
  editor.rows = Math.min(28, Math.max(10, editor.value.split("\n").length + 1));
  code.replaceWith(editor);

  const copyButton = block.querySelector("[data-copy]");
  const actions = document.createElement("div");
  actions.className = "prompt-actions";
  const saveButton = document.createElement("button");
  saveButton.type = "button";
  saveButton.textContent = "บันทึกในเครื่อง";
  const resetButton = document.createElement("button");
  resetButton.type = "button";
  resetButton.textContent = "คืนค่าเริ่มต้น";
  const status = document.createElement("small");
  status.className = "prompt-save-status";
  status.setAttribute("aria-live", "polite");
  if (savedValue !== null) status.textContent = "โหลดข้อมูลที่บันทึกไว้ใน browser นี้แล้ว";
  saveButton.addEventListener("click", () => {
    localStorage.setItem(storageKey, editor.value);
    status.textContent = "บันทึกแล้วใน browser นี้";
  });
  resetButton.addEventListener("click", () => {
    localStorage.removeItem(storageKey);
    editor.value = initialValue;
    status.textContent = "คืนค่าเริ่มต้นแล้ว";
  });
  if (copyButton) actions.append(copyButton);
  actions.append(saveButton, resetButton, status);
  block.append(actions);
}

document.addEventListener("research-profile-updated", (event) => {
  for (const editor of document.querySelectorAll(".prompt-editor")) {
    editor.value = applyProfileToPrompt(editor.value, event.detail);
  }
});

async function copyCommand(event) {
  const button = event.currentTarget;
  const command = button.closest(".command");
  const editor = command.querySelector(".prompt-editor");
  const code = command.querySelector("code");
  const value = editor ? editor.value : code.textContent;
  await navigator.clipboard.writeText(value);
  button.textContent = "คัดลอกแล้ว";
  setTimeout(() => { button.textContent = "คัดลอก"; }, 1500);
}
for (const button of document.querySelectorAll("[data-copy]")) {
  button.addEventListener("click", copyCommand);
}

for (const checklist of document.querySelectorAll("[data-checklist]")) {
  const boxes = [...checklist.querySelectorAll('input[type="checkbox"]')];
  const progress = checklist.parentElement.querySelector("[data-progress]");
  const checklistId = checklist.dataset.checklist;
  const updateProgress = () => {
    const done = boxes.filter((box) => box.checked).length;
    if (progress) progress.textContent = `${Math.round(done / boxes.length * 100)}%`;
  };
  boxes.forEach((box, index) => {
    const key = `ai-research-check-${checklistId}-${index}`;
    box.checked = localStorage.getItem(key) === "true";
    box.addEventListener("change", () => { localStorage.setItem(key, box.checked); updateProgress(); });
  });
  updateProgress();
}

const agentInputs = [...document.querySelectorAll('input[name="agent"]')];
const agentRequiredSections = [...document.querySelectorAll("[data-agent-required]")];
const agentGateStatus = document.querySelector("[data-agent-gate-status]");
function selectAgent(agent, persist = false) {
  const workspaceApp = agent === "antigravity" ? "Antigravity IDE" : "VS Code";
  for (const element of document.querySelectorAll("[data-antigravity-only]")) element.hidden = agent !== "antigravity";
  for (const element of document.querySelectorAll("[data-antigravity-hide]")) element.hidden = agent === "antigravity";
  for (const label of document.querySelectorAll("[data-workspace-app]")) label.textContent = workspaceApp;
  for (const label of document.querySelectorAll("[data-workspace-open-command]")) label.textContent = agent === "antigravity" ? "agy-ide ." : "code .";
  const agentPanel = { codex: "Codex panel", claude: "Claude Code panel", antigravity: "Antigravity Agent panel" }[agent];
  for (const label of document.querySelectorAll("[data-agent-panel]")) label.textContent = agentPanel;
  for (const command of document.querySelectorAll("[data-agent-command]")) {
    const template = agent === "antigravity" && command.dataset.antigravityTemplate ? command.dataset.antigravityTemplate : command.dataset.template;
    command.textContent = template.replace("{agent}", agent);
  }
  const loginSteps = document.querySelector("[data-login-steps]");
  if (loginSteps) {
    const steps = {
      codex: [
        ["เปิด Codex panel", "คลิกไอคอน Codex ในแถบด้านข้างของ VS Code"],
        ["เลือก Sign in with ChatGPT", "กดปุ่ม Sign in แล้วเลือกใช้บัญชี ChatGPT"],
        ["ยืนยันใน Browser", "ลงชื่อเข้าใช้บัญชีของตนเอง อนุญาตการเชื่อมต่อ แล้วกลับมาที่ VS Code"]
      ],
      claude: [
        ["เปิด Claude Code panel", "คลิกไอคอน Claude ในแถบด้านข้างของ VS Code"],
        ["เริ่ม Sign in", "กด Sign in แล้วเลือก Claude App หากใช้บัญชี Claude Pro หรือ Max; ผู้ใช้ Anthropic Console ให้เลือก Console"],
        ["ยืนยันใน Browser", "ลงชื่อเข้าใช้ Claude.ai หรือ Anthropic Console ตามสิทธิ์ แล้วอนุญาตการเชื่อมต่อ"]
      ],
      antigravity: [
        ["เปิด Antigravity IDE", "ที่ Welcome screen กด Sign in"],
        ["เลือกบัญชี Google", "ลงชื่อเข้าใช้ด้วยบัญชี Gmail ส่วนบุคคลของตนเองใน Browser"],
        ["ตั้งค่าครั้งแรก", "กลับเข้า IDE เลือก Theme และเลือก Review-driven development เมื่อระบบถามนโยบายการทำงานของ Agent"]
      ]
    };
    loginSteps.innerHTML = steps[agent].map(([title, detail], index) => {
      return `<li><span>${String(index + 1).padStart(2, "0")}</span><div><strong>${title}</strong><br>${detail}</div></li>`;
    }).join("");
  }
  const loginSource = document.querySelector("[data-login-source]");
  if (loginSource) {
    const sources = {
      codex: ["คู่มือ Codex ของ OpenAI", "https://developers.openai.com/codex/"],
      claude: ["คู่มือเริ่มต้น Claude Code ของ Anthropic", "https://docs.anthropic.com/en/docs/claude-code/getting-started"],
      antigravity: ["คู่มือเริ่มต้น Antigravity IDE ของ Google", "https://codelabs.developers.google.com/getting-started-agy-ide?hl=th"]
    };
    loginSource.textContent = sources[agent][0];
    loginSource.href = sources[agent][1];
  }
  for (const section of agentRequiredSections) section.hidden = false;
  if (agentGateStatus) agentGateStatus.innerHTML = '<strong>เลือกแล้ว:</strong> ขั้นตอนถัดไปใช้ Workspace และ AI panel ที่ตรงกับบัญชี';
  if (persist) setPreference("ai-research-agent", agent);
}
if (agentInputs.length) {
  for (const section of agentRequiredSections) section.hidden = true;
  const savedValue = getPreference("ai-research-agent");
  const saved = ["codex", "claude", "antigravity"].includes(savedValue) ? savedValue : null;
  if (saved) {
    const selected = agentInputs.find((input) => input.value === saved);
    if (selected) {
      selected.checked = true;
      selectAgent(saved);
    }
  }
  for (const input of agentInputs) input.addEventListener("change", () => selectAgent(input.value, true));
}
