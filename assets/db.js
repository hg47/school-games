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
  /* ═══ СПРОБА ПОЧИНАЄТЬСЯ НА СТАРТІ (supabase/18_attempt_start.sql) ═══
     ⚠️ Раніше оновлення сторінки посеред гри давало безкоштовний новий
        старт: спроба рахувалась лише в кінці. Тепер:
        • «Почати» → start_attempt: сервер одразу записує спробу;
        • прогрес (раунд, помилки, журнал) зберігається в localStorage,
          тож після оновлення гра ПРОДОВЖУЄТЬСЯ з початку того самого раунду,
          а помилки нікуди не зникають;
        • токен пристрою відрізняє «оновив сторінку» (та сама спроба) від
          «відкрив на іншому пристрої» (попередня спроба перервана).
     ⭐ Якщо в базі ще немає start_attempt (HTTP 404) — гра працює по-старому. */
  const KEY_ = code => 'att:' + String(code || '').toUpperCase();
  const load = code => { try { return JSON.parse(localStorage.getItem(KEY_(code)) || 'null'); } catch (e) { return null; } };
  const store = (code, st) => { try { localStorage.setItem(KEY_(code), JSON.stringify(st)); } catch (e) {} };
  const newToken = () => (window.crypto && crypto.randomUUID) ? crypto.randomUUID()
    : 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, ch => {
        const r = Math.random() * 16 | 0; return (ch === 'x' ? r : (r & 3 | 8)).toString(16); });

  window.Attempt = {
    /* є незавершений прогрес на цьому пристрої? */
    saved(code) { const s = load(code); return !!(s && s.token && s.started); },
    /* зберегти прогрес; помилки й журнал ніколи не зменшуються
       (дві відкриті вкладки не можуть «стерти» помилки одна одної) */
    save(code, st) {
      const s = load(code); if (!s || !s.token) return;
      if (typeof st.round === 'number') s.round = st.round;
      if (typeof st.stars === 'number') s.stars = st.stars;
      if (typeof st.mistakes === 'number') s.mistakes = Math.max(s.mistakes || 0, st.mistakes);
      if (st.mlog && st.mlog.length >= (s.mlog || []).length) s.mlog = st.mlog.slice(0, 300);
      store(code, s);
    },
    mistakes(code) { const s = load(code); return (s && s.mistakes) || 0; },
    clear(code) { try { localStorage.removeItem(KEY_(code)); } catch (e) {} },
    /* «Почати»: { ok, state? } — state, якщо продовжуємо ту саму спробу;
       { ok:false, msg, stop } — якщо грати не можна */
    async begin(play) {
      const code = play && play.code;
      if (!code) return { ok: false, msg: 'Немає коду. Повернись на головну сторінку.', stop: true };
      let s = load(code);
      const token = (s && s.token) || newToken();
      const r = await rpc('start_attempt', { p_code: code, p_token: token });
      if (r.error) {
        if (r.error.status === 404) return { ok: true, legacy: true };   // база ще стара
        return { ok: false, msg: 'Немає звʼязку із сервером. Перевір інтернет і натисни «Почати» ще раз.' };
      }
      const d = r.data || {};
      if (!d.ok) {
        const used = /вичерпано/i.test(d.error || '');
        if (used) this.clear(code);
        return { ok: false, stop: used,
          msg: used ? 'Усі спроби вже використано. Якщо стався технічний збій — скажи вчителю.'
                    : (d.error || 'Не вдалося почати гру.') };
      }
      if (d.resumed && s && s.started) return { ok: true, state: s };
      // нова спроба — прогрес з нуля
      s = { token: token, started: true, round: 0, stars: 0, mistakes: 0, mlog: [] };
      store(code, s);
      return { ok: true };
    }
  };

  window.submitResult = async function (score, details) {
    try {
      const play = JSON.parse(sessionStorage.getItem('play') || 'null');
      if (!play || !play.code) return { ok: false, error: 'no session' };
      const st = load(play.code);
      // ⭐ Спроба, розпочата на старті (18_attempt_start.sql), — завершуємо саме її.
      if (st && st.token) {
        const r = await rpc('submit_result', { p_code: play.code, p_score: score,
          p_details: details || null, p_token: st.token });
        if (!r.error) { if (r.data && r.data.ok) window.Attempt.clear(play.code); return r.data; }
        if (r.error.status !== 404) return { ok: false, error: r.error.message };
      }
      // ⭐ Журнал помилок (де саме помилився) — supabase/17_result_details.sql.
      //    Якщо тієї функції в базі ще немає (HTTP 404), записуємо бал
      //    старим способом: журнал — довідка, а бал губити не можна.
      if (details) {
        const r = await rpc('submit_result', { p_code: play.code, p_score: score, p_details: details });
        if (!r.error) return r.data;
        if (r.error.status !== 404) return { ok: false, error: r.error.message };
      }
      const { data, error } = await rpc('submit_result', { p_code: play.code, p_score: score });
      if (error) return { ok: false, error: error.message };
      return data;
    } catch (e) {
      return { ok: false, error: String(e) };
    }
  };
})();
