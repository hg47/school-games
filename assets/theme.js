/* ═══════════════════════════════════════════════════════════════════════════
   ПЕРЕМИКАЧ ТЕМИ · світла (за замовчуванням) ⇄ темна
   Підключати в <head> БЕЗ defer:

     <script src="assets/theme.js"></script>          (у корені)
     <script src="../assets/theme.js"></script>       (в games/)

   ⚠️ Саме в <head> і саме без defer — тоді тема проставлена ще до першого
      малювання й немає блимання світлим на темній темі.

   ⛔⛔ РІШЕННЯ ВЧИТЕЛЯ 15.09.2026: режиму «авто» БІЛЬШЕ НЕМАЄ.
      Сайт завжди відкривається у СВІТЛІЙ темі, хоч би що стояло в системі —
      уроки показують з екрана, і дітям звичніший світлий вигляд.
      Темну вмикає сам учитель кнопкою в правому верхньому куті.

   ⚠️ У css немає жодного @media (prefers-color-scheme) І ЦЕ ЛИШАЄТЬСЯ ТАК:
      скрипт проставляє html[data-theme="light"|"dark"] конкретним значенням,
      тому світла палітра описана один раз і копії не розходяться.

   Вибір користувача (light|dark) живе в localStorage під ключем "theme"
   і спільний для всіх сторінок сайту: обрав на головній — діє і в грі,
   і в тренажері. ⚠️ Старе значення "auto" читається як «світла».
   ═══════════════════════════════════════════════════════════════════════════ */
(() => {
  "use strict";
  const KEY = "theme";
  const ORDER = ["light", "dark"];
  const LABEL = { light: "світла", dark: "темна" };

  // localStorage може бути заборонений (приватний режим, політика) — не падаємо.
  // ⚠️ Усе, що не "light"/"dark" (зокрема старе "auto"), читається як «світла».
  const get = () => {
    try { const v = localStorage.getItem(KEY); return ORDER.includes(v) ? v : "light"; }
    catch (e) { return "light"; }
  };
  const save = v => { try { localStorage.setItem(KEY, v); } catch (e) {} };

  const apply = () => {
    const choice = get();
    document.documentElement.setAttribute("data-theme", choice);
    return choice;
  };

  apply();   // до першого малювання
  // ⛔ Слухача системної теми немає навмисно: сайт за системою не перемикається.

  // ── іконки: сонце (світла), місяць (темна) ──
  const SVG = s => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
    'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + s + '</svg>';
  const ICON = {
    light: SVG('<circle cx="12" cy="12" r="4.2"/><path d="M12 2.6v2.2M12 19.2v2.2M2.6 12h2.2M19.2 12h2.2' +
               'M5.4 5.4l1.6 1.6M17 17l1.6 1.6M18.6 5.4L17 7M7 17l-1.6 1.6"/>'),
    dark: SVG('<path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a7.5 7.5 0 1 0 10.5 10.5z"/>')
  };

  let btn = null;
  const repaint = () => {
    if (!btn) return;
    const c = get();
    btn.innerHTML = ICON[c];
    const t = "Тема: " + LABEL[c] + " · натисни, щоб змінити";
    btn.title = t;
    btn.setAttribute("aria-label", t);
  };

  const build = () => {
    if (document.querySelector(".themebtn")) return;
    btn = document.createElement("button");
    btn.type = "button";
    btn.className = "themebtn";
    btn.onclick = () => {
      save(ORDER[(ORDER.indexOf(get()) + 1) % ORDER.length]);
      apply(); repaint();
    };
    repaint();
    // у демо й іграх є шапка .top — кнопці там саме місце, поруч із зірочками.
    // на головній і в адмінці шапки немає, тому в куток екрана.
    const top = document.querySelector(".top");
    if (top) top.appendChild(btn);
    else { btn.classList.add("themebtn-fixed"); document.body.appendChild(btn); }
  };

  // ─── ФОН-ОБОЇ З НАЗВ МОВ І ФРЕЙМВОРКІВ ───────────────────────────────────
  // Вмикається лише на сторінках із <body data-techbg>, щоб не заважати в іграх
  // і в переглядачі слайдів. Стилі — у site.css (.techbg). Слова технічні, тож
  // українськомовне правило на них не поширюється (як HTML/CSS у матеріалах).
  const TECH = [
    ["C#", "a hot"], ["JavaScript", "b"], [".NET", "a hot"], ["HTML", "c"],
    ["Kotlin", "b"], ["Python", "a hot"], ["CSS", "c"], ["TypeScript", "b"],
    ["C++", "a hot"], ["Java", "b"], ["SQL", "c"], ["Rust", "a"], ["Swift", "c"],
    ["ASP.NET", "b"], ["Go", "c"], ["React", "b"], ["Blazor", "a"], ["PHP", "c"],
    ["Vue", "b"], ["Ruby", "c"], [".NET MAUI", "a"], ["Angular", "c"],
    ["Node.js", "b"], ["Docker", "c"], ["Django", "a"], ["Git", "c"],
    ["Flask", "b"], ["Linux", "c"], ["PostgreSQL", "b"], ["JSON", "c"],
    ["Unity", "a"], ["Bash", "c"], ["Kubernetes", "b"], ["REST", "c"],
    ["WPF", "b"], ["Redis", "c"], ["TensorFlow", "a"], ["MongoDB", "c"],
    ["Azure", "b"], ["NumPy", "c"], ["pandas", "b"], ["GraphQL", "c"],
    ["Assembly", "a"], ["Pascal", "c"], ["Scratch", "b"], ["Xamarin", "c"],
    ["C#", "a"], ["Python", "b"], [".NET", "c"], ["C++", "b"], ["JavaScript", "a"],
  ];

  const buildTechbg = () => {
    if (!document.body || document.body.dataset.techbg === undefined) return;
    if (document.querySelector(".techbg")) return;
    const wall = document.createElement("div");
    wall.className = "techbg";
    wall.setAttribute("aria-hidden", "true");
    const frag = document.createDocumentFragment();
    for (const [word, cls] of TECH) {
      const s = document.createElement("span");
      s.className = cls;
      s.textContent = word;
      frag.appendChild(s);
    }
    wall.appendChild(frag);
    document.body.insertBefore(wall, document.body.firstChild);
  };

  const init = () => { build(); buildTechbg(); };
  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
})();
