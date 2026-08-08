// ─────────────────────────────────────────────────────────────
//  Клієнт гри: вхід за кодом + ім'я, спроби, оцінка 1-12, надсилання
//  Потрібен глобальний window.SCHOOL_STATS_URL (див. config.js).
// ─────────────────────────────────────────────────────────────
(function () {
  "use strict";
  var STUDENT_KEY = "school_student_v1";

  // ── Шкала переведення % → оцінка 1-12 (пороги легко змінити тут) ──
  var SCALE = [[90,12],[82,11],[74,10],[66,9],[58,8],[50,7],[42,6],[34,5],[25,4],[17,3],[8,2]];
  function pctToGrade(pct){ for (var i=0;i<SCALE.length;i++){ if (pct>=SCALE[i][0]) return SCALE[i][1]; } return 1; }

  function getStudent(){ try { return JSON.parse(localStorage.getItem(STUDENT_KEY) || "null"); } catch(e){ return null; } }
  function saveStudent(s){ try { localStorage.setItem(STUDENT_KEY, JSON.stringify(s)); } catch(e){} }
  function attemptsOf(game){ var v=parseInt(localStorage.getItem("school_att_"+game)||"0",10); return isNaN(v)?0:v; }
  function bumpAttempt(game){ var n=attemptsOf(game)+1; try{ localStorage.setItem("school_att_"+game, String(n)); }catch(e){} return n; }

  function send(payload){
    var url = window.SCHOOL_STATS_URL;
    if (!url) return; // не налаштовано — тихо пропускаємо (гра працює без сервера)
    try {
      fetch(url, { method:"POST", mode:"no-cors",
        headers:{ "Content-Type":"text/plain;charset=utf-8" },
        body: JSON.stringify(payload) });
    } catch(e){}
  }

  function whenReady(fn){ if (document.readyState !== "loading") fn(); else document.addEventListener("DOMContentLoaded", fn); }

  // ── Модалка входу: код + ім'я ──
  function askIdentity(){
    if (getStudent()) return;
    var ov = document.createElement("div");
    ov.setAttribute("style","position:fixed;inset:0;z-index:99999;background:rgba(15,25,40,.7);display:grid;place-items:center;padding:16px;font-family:'Segoe UI',system-ui,sans-serif");
    ov.innerHTML =
      '<div style="background:#fff;border-radius:20px;max-width:380px;width:100%;padding:24px;box-shadow:0 24px 60px rgba(0,0,0,.4)">' +
      '<div style="font-size:40px;text-align:center">🤖</div>' +
      '<h2 style="margin:8px 0 2px;text-align:center;color:#1b3a5c;font-size:21px">Вхід до ігор</h2>' +
      '<p style="margin:0 0 16px;text-align:center;color:#5b7a99;font-size:14px">Введи свій код і ім\'я — щоб вчитель побачив твій результат.</p>' +
      '<label style="display:block;font-size:13px;color:#5b7a99;font-weight:700;margin-bottom:4px">Код (дав вчитель)</label>' +
      '<input id="sc_code" autocomplete="off" placeholder="напр. K7QX" style="width:100%;box-sizing:border-box;padding:12px;border:2px solid #cfdcea;border-radius:12px;font-size:18px;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px">' +
      '<label style="display:block;font-size:13px;color:#5b7a99;font-weight:700;margin-bottom:4px">Ім\'я та прізвище</label>' +
      '<input id="sc_name" autocomplete="off" placeholder="напр. Олег Петренко" style="width:100%;box-sizing:border-box;padding:12px;border:2px solid #cfdcea;border-radius:12px;font-size:16px;margin-bottom:16px">' +
      '<button id="sc_go" style="width:100%;padding:13px;border:0;border-radius:999px;background:#f2994a;color:#3a2202;font-weight:800;font-size:16px;cursor:pointer">Увійти →</button>' +
      '<div id="sc_err" style="color:#ea6b6b;font-size:13px;text-align:center;margin-top:10px;min-height:16px"></div></div>';
    document.body.appendChild(ov);
    var go = ov.querySelector("#sc_go");
    function submit(){
      var code = ov.querySelector("#sc_code").value.trim().toUpperCase();
      var name = ov.querySelector("#sc_name").value.trim();
      var err = ov.querySelector("#sc_err");
      if (code.length < 3){ err.textContent = "Введи, будь ласка, свій код."; return; }
      if (name.length < 3){ err.textContent = "Напиши ім'я та прізвище."; return; }
      saveStudent({ code: code, name: name });
      ov.remove();
    }
    go.onclick = submit;
    ov.querySelector("#sc_name").addEventListener("keydown", function(e){ if (e.key === "Enter") submit(); });
  }

  whenReady(askIdentity);

  window.SchoolGame = {
    pctToGrade: pctToGrade,
    student: getStudent,
    resetStudent: function(){ try{ localStorage.removeItem(STUDENT_KEY); }catch(e){} },
    attempts: attemptsOf,
    // Викликати наприкінці гри. Повертає {pct, grade, attempt} для показу учневі.
    submit: function(game, score, max){
      var pct = Math.round(100 * score / Math.max(1, max));
      var grade = pctToGrade(pct);
      var attempt = bumpAttempt(game);
      var s = getStudent() || {};
      send({ code: s.code || "", name: s.name || "", game: game,
             score: score, max: max, pct: pct, grade: grade, attempt: attempt });
      return { pct: pct, grade: grade, attempt: attempt };
    }
  };
})();
