document.documentElement.classList.add("js");

const links = document.querySelectorAll('a[href^="#"]');
for (const link of links) {
  link.addEventListener("click", () => {
    const target = document.querySelector(link.getAttribute("href"));
    if (target) target.setAttribute("tabindex", "-1");
  });
}

const platformButtons = document.querySelectorAll("[data-platform-button]");
const platformPanels = document.querySelectorAll("[data-platform-panel]");
function selectPlatform(name) {
  for (const button of platformButtons) button.setAttribute("aria-pressed", String(button.dataset.platformButton === name));
  for (const panel of platformPanels) panel.hidden = panel.dataset.platformPanel !== name;
  localStorage.setItem("ai-grad-platform", name);
}
if (platformButtons.length) {
  const saved = localStorage.getItem("ai-grad-platform");
  const detected = /Mac/.test(navigator.platform) ? "macos" : /Win/.test(navigator.platform) ? "windows" : "linux";
  selectPlatform(saved || detected);
  for (const button of platformButtons) button.addEventListener("click", () => selectPlatform(button.dataset.platformButton));
}

for (const button of document.querySelectorAll("[data-copy]")) {
  button.addEventListener("click", async () => {
    const value = button.parentElement.querySelector("code").textContent;
    await navigator.clipboard.writeText(value);
    button.textContent = "คัดลอกแล้ว";
    setTimeout(() => { button.textContent = "คัดลอก"; }, 1500);
  });
}

const boxes = [...document.querySelectorAll('.checklist input[type="checkbox"]')];
const progress = document.querySelector("[data-progress]");
function updateProgress() {
  const done = boxes.filter((box) => box.checked).length;
  if (progress) progress.textContent = `${Math.round(done / boxes.length * 100)}%`;
}
boxes.forEach((box, index) => {
  box.checked = localStorage.getItem(`ai-grad-check-${index}`) === "true";
  box.addEventListener("change", () => { localStorage.setItem(`ai-grad-check-${index}`, box.checked); updateProgress(); });
});
updateProgress();

const agentInputs = [...document.querySelectorAll('input[name="agent"]')];
function selectAgent(agent) {
  for (const command of document.querySelectorAll("[data-agent-command]")) command.textContent = command.dataset.template.replace("{agent}", agent);
  const help = document.querySelector("[data-login-help]");
  if (help) {
    const labels = {
      codex: 'เปิด Codex แล้วรัน <code>codex login</code>',
      claude: 'เปิด Claude Code ด้วย <code>claude</code> แล้วเลือกบัญชี Claude ที่มีสิทธิ์',
      antigravity: 'เปิด Antigravity CLI ด้วย <code>agy</code> แล้วลงชื่อเข้าใช้ Google'
    };
    help.innerHTML = labels[agent];
  }
  localStorage.setItem("ai-grad-agent", agent);
}
if (agentInputs.length) {
  const savedAgent = localStorage.getItem("ai-grad-agent") || "codex";
  const selected = agentInputs.find((input) => input.value === savedAgent) || agentInputs[0];
  selected.checked = true;
  selectAgent(selected.value);
  for (const input of agentInputs) input.addEventListener("change", () => selectAgent(input.value));
}
