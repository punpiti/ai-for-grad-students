const form = document.querySelector("[data-registration-form]");
const result = document.querySelector("[data-registration-result]");
const summary = document.querySelector("[data-registration-summary]");
function registrationText(data) {
  const value = (key) => data.get(key)?.toString().trim() || "ยังไม่ระบุ";
  return ["ร่างข้อมูลสมัคร AI for Research แบบกลุ่ม","","แพ็กเกจ: "+value("course"),"กลุ่มผู้สมัคร: "+value("group_type"),"จำนวนผู้เรียนโดยประมาณ: "+value("headcount")+" คน","ผู้ประสานงาน: "+value("contact_name"),"สังกัดหรือชื่อกลุ่ม: "+value("organization"),"อาหาร: "+value("meal_plan"),"ข้อจำกัดอาหาร: "+value("dietary"),"หมายเหตุ: "+value("notes"),"","สถานะ: ร่างสำหรับวางแผน ยังไม่ใช่การยืนยันที่นั่งและยังไม่มีการชำระเงิน"].join("\n");
}
form?.addEventListener("submit",(event)=>{event.preventDefault();if(!form.reportValidity())return;summary.textContent=registrationText(new FormData(form));result.hidden=false;result.scrollIntoView({behavior:"smooth",block:"start"});});
document.querySelector("[data-download-registration]")?.addEventListener("click",()=>{const blob=new Blob([summary.textContent],{type:"text/plain;charset=utf-8"});const link=document.createElement("a");link.href=URL.createObjectURL(blob);link.download="ai-for-research-registration-draft.txt";link.click();URL.revokeObjectURL(link.href);});
document.querySelector("[data-copy-registration]")?.addEventListener("click",async(event)=>{await navigator.clipboard.writeText(summary.textContent);const button=event.currentTarget,original=button.textContent;button.textContent="คัดลอกแล้ว";setTimeout(()=>{button.textContent=original;},1400);});
