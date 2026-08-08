/* ═══════════════════════════════════════════════════════════════════════════
   ПЕРЕМИКАЧ ТЕМИ · авто → світла → темна → авто
   Підключати в <head> БЕЗ defer:

     <script src="assets/theme.js"></script>          (у корені)
     <script src="../assets/theme.js"></script>       (в games/)

   ⚠️ Саме в <head> і саме без defer — тоді тема проставлена ще до першого
      малювання й немає блимання світлим на темній темі.

   ⚠️ КЛЮЧОВЕ РІШЕННЯ: «авто» розбирає цей скрипт, а не css. У css немає
      жодного @media (prefers-color-scheme) — там лише :root (темна) і
      :root[data-theme="light"]. Скрипт читає системну настройку й проставляє
      КОНКРЕТНЕ значення. Завдяки цьому світла палітра описана один раз,
      а не двічі (в media-запиті та в блоці атрибута), і копії не розходяться.

   Вибір користувача (auto|light|dark) живе в localStorage під ключем "theme"
   і спільний для всіх сторінок сайту: обрав на головній — діє і в грі.
   ═══════════════════════════════════════════════════════════════════════════ */
(() => {
  "use strict";
  const KEY = "theme";
  const ORDER = ["auto", "light", "dark"];
  const LABEL = { auto: "авто (як у системі)", light: "світла", dark: "темна" };
  const mq = window.matchMedia("(prefers-color-scheme: dark)");

  // localStorage може бути заборонений (приватний режим, політика) — не падаємо
  const get = () => {
    try { const v = localStorage.getItem(KEY); return ORDER.includes(v) ? v : "auto"; }
    catch (e) { return "auto"; }
  };
  const save = v => { try { localStorage.setItem(KEY, v); } catch (e) {} };

  const apply = () => {
    const choice = get();
    const real = choice === "auto" ? (mq.matches ? "dark" : "light") : choice;
    document.documentElement.setAttribute("data-theme", real);
    return choice;
  };

  apply();   // до першого малювання

  // якщо стоїть «авто», а користувач перемкнув тему в системі — реагуємо
  const onSys = () => { if (get() === "auto") { apply(); repaint(); } };
  if (mq.addEventListener) mq.addEventListener("change", onSys);
  else if (mq.addListener) mq.addListener(onSys);           // старі Safari

  // ── іконки: півколо (авто), сонце (світла), місяць (темна) ──
  const SVG = s => '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" ' +
    'stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">' + s + '</svg>';
  const ICON = {
    auto: SVG('<circle cx="12" cy="12" r="8"/><path d="M12 4a8 8 0 0 0 0 16z" fill="currentColor" stroke="none"/>'),
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

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", build);
  else build();
})();
