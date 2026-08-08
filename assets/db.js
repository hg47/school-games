/* ═══════════════════════════════════════════════════════════════════════════
   ЗВ'ЯЗОК З БАЗОЮ ДЛЯ СТОРІНОК УЧНЯ · без жодної бібліотеки
   Підключають: index.html і всі games/*.html — ПІСЛЯ supabase-config.js.

   ⚠️ НАВІЩО ЦЕ ЗАМІСТЬ БІБЛІОТЕКИ.
      Раніше тут стояло  import { createClient } from 'https://esm.sh/…'.
      Це тягнуло ГРАФ із 16 модулів на ~280 кБ із чужого сервера — при
      кожному відкритті сторінки. І все це, щоб зробити ОДИН POST-запит:
      сторінки учня використовують тільки rpc(), і нічого більше
      (ні auth, ні realtime, ні storage, ні from()).

      Гірше було інше — відмова esm.sh посеред уроку:
      • index.html: привʼязка кнопки лежала В ТОМУ Ж модулі, тому «Увійти»
        просто нічого не робила. Без помилки, без повідомлення.
      • гра: window.submitResult не існував, фінал падав у гілку
        «Демо-режим» — оцінка не зберігалася.

   ⭐ RPC у Supabase — це звичайний POST на /rest/v1/rpc/<функція>.
      Перевірено на живій базі: HTTP 200, application/json, у тілі —
      те саме, що повертає sql-функція. Тому бібліотека тут не потрібна.

   ⚠️ Форму відповіді збережено такою САМОЮ, як у бібліотеки — { data, error },
      де error має .message. Інакше довелося б правити всі місця виклику.
   ═══════════════════════════════════════════════════════════════════════════ */
(() => {
  "use strict";

  const URL_ = window.SUPABASE_URL, KEY = window.SUPABASE_KEY;

  async function rpc(fn, args) {
    if (!URL_ || !KEY) return { data: null, error: { message: 'supabase-config.js не підключено' } };
    try {
      const r = await fetch(URL_ + '/rest/v1/rpc/' + fn, {
        method: 'POST',
        headers: {
          'apikey': KEY,
          'Authorization': 'Bearer ' + KEY,
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify(args || {})
      });
      const text = await r.text();
      let data = null;
      try { data = text ? JSON.parse(text) : null; } catch (e) { data = null; }
      if (!r.ok) {
        // PostgREST на помилці віддає {message, hint, details, code}
        const m = (data && (data.message || data.error)) || ('HTTP ' + r.status);
        return { data: null, error: { message: m, status: r.status } };
      }
      return { data: data, error: null };
    } catch (e) {
      // мережі немає / запит заблоковано
      return { data: null, error: { message: String(e && e.message || e) } };
    }
  }

  // та сама форма звернення, що була в бібліотеки: sb.rpc(...)
  window.sb = { rpc: rpc };

  /* Запис результату гри. Був однаковим у всіх девʼяти іграх — тепер лежить
     в одному місці. Повертає те, що віддала sql-функція submit_result:
     { ok, grade, pct, attempt_no, remaining } або { ok:false, error }. */
  window.submitResult = async function (score) {
    try {
      const play = JSON.parse(sessionStorage.getItem('play') || 'null');
      if (!play || !play.code) return { ok: false, error: 'no session' };
      const { data, error } = await rpc('submit_result', { p_code: play.code, p_score: score });
      if (error) return { ok: false, error: error.message };
      return data;
    } catch (e) {
      return { ok: false, error: String(e) };
    }
  };
})();
