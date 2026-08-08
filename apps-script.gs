/**
 * ПРИЙМАЧ РЕЗУЛЬТАТІВ ІГОР → Google Таблиця
 * ------------------------------------------------------------------
 * Як під'єднати (коротко, докладніше в README.md):
 *  1) Створи Google Таблицю.
 *  2) Розширення → Apps Script. Встав цей код замість того, що там є.
 *  3) Запусти один раз функцію setup() (дозволь доступ) — вона створить
 *     вкладки «Учні», «Результати», «Підсумок» і меню.
 *  4) На вкладці «Учні» впиши Клас і ПІБ учнів; у меню «Ігри» → «Згенерувати коди».
 *  5) Розгорни: Deploy → New deployment → Web app →
 *        Execute as: Me,  Who has access: Anyone → скопіюй URL (/exec).
 *  6) Встав цей URL у config.js на сайті (window.SCHOOL_STATS_URL).
 */

var TAB_STUDENTS = "Учні";
var TAB_RESULTS  = "Результати";
var TAB_SUMMARY  = "Підсумок";

function onOpen() {
  SpreadsheetApp.getUi()
    .createMenu("Ігри")
    .addItem("Згенерувати коди для учнів", "generateCodes")
    .addItem("Оновити підсумок", "buildSummary")
    .addItem("Створити вкладки (setup)", "setup")
    .addToUi();
}

function setup() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var st = ss.getSheetByName(TAB_STUDENTS) || ss.insertSheet(TAB_STUDENTS);
  if (st.getLastRow() === 0) st.appendRow(["Клас", "ПІБ", "Код"]);
  var rs = ss.getSheetByName(TAB_RESULTS) || ss.insertSheet(TAB_RESULTS);
  if (rs.getLastRow() === 0)
    rs.appendRow(["Дата/час", "Код", "Введене ім'я", "Клас", "ПІБ (ростер)", "Гра", "%", "Бал(1-12)", "Спроба", "Очки", "Макс", "Примітка"]);
  if (!ss.getSheetByName(TAB_SUMMARY)) ss.insertSheet(TAB_SUMMARY);
  buildSummary();
  SpreadsheetApp.getUi().alert("Готово! Заповни вкладку «Учні» і згенеруй коди (меню «Ігри»).");
}

/** Генерує короткі унікальні коди для рядків «Учні» без коду. */
function generateCodes() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var st = ss.getSheetByName(TAB_STUDENTS);
  if (!st) { SpreadsheetApp.getUi().alert("Спершу запусти setup()."); return; }
  var last = st.getLastRow();
  if (last < 2) return;
  var rng = st.getRange(2, 1, last - 1, 3);
  var vals = rng.getValues();
  var used = {};
  vals.forEach(function(r){ if (r[2]) used[String(r[2]).toUpperCase()] = true; });
  var alphabet = "ABCDEFGHJKMNPQRSTUVWXYZ23456789"; // без 0,O,1,I,L
  function gen(){
    var c; do { c = ""; for (var i=0;i<4;i++) c += alphabet.charAt(Math.floor(Math.random()*alphabet.length)); } while (used[c]);
    used[c] = true; return c;
  }
  var changed = false;
  for (var i=0;i<vals.length;i++){
    if (vals[i][1] && !vals[i][2]) { vals[i][2] = gen(); changed = true; } // є ПІБ, немає коду
  }
  if (changed) rng.setValues(vals);
  SpreadsheetApp.getUi().alert("Коди згенеровано. Роздай кожному учневі його код (стовпець «Код»).");
}

/** Пошук учня за кодом → {klas, pib}. */
function lookupStudent(code) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var st = ss.getSheetByName(TAB_STUDENTS);
  if (!st || st.getLastRow() < 2) return null;
  var vals = st.getRange(2, 1, st.getLastRow() - 1, 3).getValues();
  code = String(code || "").toUpperCase();
  for (var i=0;i<vals.length;i++){
    if (String(vals[i][2]).toUpperCase() === code) return { klas: vals[i][0], pib: vals[i][1] };
  }
  return null;
}

/** Прийом результату з гри (POST). */
function doPost(e) {
  try {
    var d = JSON.parse(e.postData.contents);
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var rs = ss.getSheetByName(TAB_RESULTS) || ss.insertSheet(TAB_RESULTS);
    var stu = lookupStudent(d.code);
    var note = stu ? "" : "невідомий код";
    rs.appendRow([
      new Date(), d.code || "", d.name || "",
      stu ? stu.klas : "", stu ? stu.pib : "",
      d.game || "", d.pct != null ? d.pct : "", d.grade != null ? d.grade : "",
      d.attempt != null ? d.attempt : "", d.score != null ? d.score : "", d.max != null ? d.max : "", note
    ]);
    return ContentService.createTextOutput(JSON.stringify({ ok: true }))
      .setMimeType(ContentService.MimeType.JSON);
  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ ok: false, error: String(err) }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

/** Будує «Підсумок»: найкращий бал кожного учня по кожній грі. */
function buildSummary() {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var rs = ss.getSheetByName(TAB_RESULTS);
  var sm = ss.getSheetByName(TAB_SUMMARY) || ss.insertSheet(TAB_SUMMARY);
  sm.clear();
  sm.appendRow(["Клас", "ПІБ", "Гра", "Кращий бал (1-12)", "Кращий %", "К-ть спроб"]);
  if (!rs || rs.getLastRow() < 2) return;
  var vals = rs.getRange(2, 1, rs.getLastRow() - 1, 12).getValues();
  var map = {}; // key = клас|пиб|гра
  vals.forEach(function(r){
    var klas=r[3], pib=r[4], game=r[5], pct=Number(r[6])||0, grade=Number(r[7])||0;
    if (!pib) return; // пропускаємо невідомі коди
    var k = klas + "|" + pib + "|" + game;
    if (!map[k]) map[k] = { klas:klas, pib:pib, game:game, grade:grade, pct:pct, n:1 };
    else { map[k].n++; if (grade > map[k].grade) { map[k].grade=grade; map[k].pct=pct; } }
  });
  var rows = Object.keys(map).map(function(k){ var m=map[k]; return [m.klas, m.pib, m.game, m.grade, m.pct, m.n]; });
  rows.sort(function(a,b){ return (a[0]+a[2]+a[1]).localeCompare(b[0]+b[2]+b[1]); });
  if (rows.length) sm.getRange(2, 1, rows.length, 6).setValues(rows);
}
