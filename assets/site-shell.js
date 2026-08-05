const MODULE_LINKS = [
  [1, "prepare.html", "Prepare Workspace"],
  [2, "module-2.html", "First AI Research Task"],
  [3, "module-3.html", "Problem–Gap–RQ"],
  [4, "module-4.html", "Literature Evidence"],
  [5, "module-5.html", "Research Logic"],
  [6, "module-6.html", "Experiment Design"],
  [7, "module-7.html", "Analysis & Visuals"],
  [8, "module-8.html", "Document Production"],
  [9, "module-9.html", "Personal Workflow"],
];

const LOCAL_LINKS = {
  home: [["course", "หลักสูตร"], ["requirements", "ข้อกำหนด"]],
  1: [["setup", "ก่อนเริ่ม"], ["practice", "ฝึกทำ"], ["homework", "งานท้ายบท"]],
  2: [["outcomes", "สิ่งที่จะเรียนรู้"], ["activity", "ลงมือทำ"], ["finish", "ทบทวน"]],
  3: [["start", "ก่อนเริ่ม"], ["activity", "ลงมือทำ"], ["finish", "ทบทวน"]],
  4: [["prepare", "ก่อนเริ่ม"], ["shared", "ลงมือทำ"], ["finish", "ทบทวน"]],
  5: [["start", "ก่อนเริ่ม"], ["activity", "ลงมือทำ"], ["review", "ทบทวน"]],
  6: [["start", "ก่อนเริ่ม"], ["activity", "ลงมือทำ"], ["review", "ทบทวน"]],
  7: [["start", "ก่อนเริ่ม"], ["activity", "ลงมือทำ"], ["review", "ทบทวน"]],
  8: [["start", "ก่อนเริ่ม"], ["activity", "ลงมือทำ"], ["review", "ทบทวน"]],
  9: [["start", "ก่อนเริ่ม"], ["activity", "ลงมือทำ"], ["review", "ทบทวน"]],
  example: [["definition", "โจทย์วิจัย"], ["method", "วิธีวิจัย"], ["review", "ทบทวน"]],
};

class SiteHeader extends HTMLElement {
  connectedCallback() {
    const current = this.getAttribute("current") || "";
    const isHome = current === "home";
    const moduleLinks = MODULE_LINKS.map(([number, href, label]) => {
      const active = String(number) === current ? ' aria-current="page"' : "";
      return `<a class="available" href="${href}"${active}>${number} · ${label}</a>`;
    }).join("");
    const localLinks = (LOCAL_LINKS[current] || [])
      .map(([id, label]) => `<a href="#${id}">${label}</a>`)
      .join("");
    this.innerHTML = `<header class="site-header">
      <a class="brand" href="${isHome ? "#top" : "index.html"}" aria-label="AI for Research หน้าแรก"><span class="brand-mark">AI</span><span>for Research</span></a>
      <nav aria-label="เมนูหลัก">
        ${isHome ? "" : '<a href="index.html">หน้าหลัก</a>'}
        <details class="module-menu"><summary>โมดูล 1–9</summary><div>${moduleLinks}</div></details>
        ${localLinks}
        <a class="nav-cta" href="prepare.html">เริ่ม Module 1</a>
      </nav>
    </header>`;
  }
}

class SiteFooter extends HTMLElement {
  connectedCallback() {
    this.innerHTML = `<footer>
      <p><a href="index.html">AI for Research</a></p>
      <div class="footer-credit"><p>Developed by One234@KU</p><p>© 2026 พันธุ์ปิติ เปี่ยมสง่า. All rights reserved.</p></div>
    </footer>`;
  }
}

customElements.define("site-header", SiteHeader);
customElements.define("site-footer", SiteFooter);
