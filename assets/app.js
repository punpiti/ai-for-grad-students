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
for (const block of document.querySelectorAll(".markdown-body pre")) {
  const code = block.querySelector("code");
  if (!code) continue;
  const button = document.createElement("button");
  button.type = "button";
  button.className = "markdown-copy";
  button.textContent = "คัดลอก";
  button.addEventListener("click", async () => {
    await navigator.clipboard.writeText(code.textContent);
    button.textContent = "คัดลอกแล้ว";
    setTimeout(() => { button.textContent = "คัดลอก"; }, 1500);
  });
  block.appendChild(button);
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

async function copyCommand(event) {
  const button = event.currentTarget;
  const value = button.parentElement.querySelector("code").textContent;
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
