#!/usr/bin/env bash
# EGG_APP Backend — tüm endpoint'leri rastgele verilerle uçtan uca test eden script.
set -uo pipefail

BASE="http://127.0.0.1:8080/api/v1"
HEALTH="http://127.0.0.1:8080/api/health"

PASS=0
FAIL=0

hr() { printf '\n\033[1;36m%s\033[0m\n' "──────────────────────────────────────────────────────────"; }

# $1 = açıklama, $2 = beklenen HTTP kodu, $3 = curl çıktı dosyası (gövde), $4 = gerçek kod
check() {
  local desc="$1" expected="$2" body_file="$3" actual="$4"
  if [[ "$actual" == "$expected" ]]; then
    printf '\033[1;32m✔ PASS\033[0m  [%s]  HTTP %s\n' "$desc" "$actual" >&2
    PASS=$((PASS+1))
  else
    printf '\033[1;31m✘ FAIL\033[0m  [%s]  beklenen=%s  gelen=%s\n' "$desc" "$expected" "$actual" >&2
    FAIL=$((FAIL+1))
  fi
  echo "   ↳ Yanıt: $(cat "$body_file" | head -c 500)" >&2
}

# req <method> <path> <expected_code> <desc> [json_body] [auth_token]
req() {
  local method="$1" path="$2" expected="$3" desc="$4" body="${5:-}" token="${6:-}"
  local tmp; tmp=$(mktemp)
  local args=(-s -o "$tmp" -w '%{http_code}' -X "$method" "$BASE$path" -H 'Content-Type: application/json')
  [[ -n "$token" ]] && args+=(-H "Authorization: Bearer $token")
  [[ -n "$body" ]] && args+=(-d "$body")
  local code; code=$(curl "${args[@]}")
  check "$desc" "$expected" "$tmp" "$code"
  cat "$tmp"
  rm -f "$tmp"
}

# Rastgele değer üreticiler
RAND=$RANDOM$RANDOM
EMAIL="eggtester${RAND}@example.com"
EMAIL2="eggtester${RAND}_2@example.com"
PASSWORD="Sifre${RAND}!"
NEWPASS="YeniSifre${RAND}!"
FIRST_NAMES=(Ali Ayşe Mehmet Zeynep Burak Elif Cem Deniz)
LAST_NAMES=(Yılmaz Kaya Demir Şahin Çelik Arslan Doğan Aydın)
FNAME=${FIRST_NAMES[$RANDOM % ${#FIRST_NAMES[@]}]}
LNAME=${LAST_NAMES[$RANDOM % ${#LAST_NAMES[@]}]}
DEVICE_NAME="MutfakCihazi-${RAND}"
MODEL_CODES=(VEC-1000 VEC-2000 VEC-3000PRO)
MODEL_CODE=${MODEL_CODES[$RANDOM % ${#MODEL_CODES[@]}]}
PAIR_CODE="PAIR-${RAND}"
PRESET_NAME="HazirAyar-${RAND}"
MODES=(bulk separate)
MODE=${MODES[$RANDOM % ${#MODES[@]}]}
DONENESS=(soft medium hard)
SECTIONS="[1,2,3]"
DONE_LEVELS="[\"${DONENESS[$RANDOM % 3]}\", \"${DONENESS[$RANDOM % 3]}\", \"${DONENESS[$RANDOM % 3]}\"]"

echo "════════════════════════════════════════════════════════════"
echo " EGG_APP — Vapor Backend Uçtan Uca Endpoint Testi"
echo " Tarih: $(date '+%Y-%m-%d %H:%M:%S')"
echo " Rastgele kullanıcı: $FNAME $LNAME <$EMAIL>"
echo "════════════════════════════════════════════════════════════"

# ───────────────────────── 0) Health check ─────────────────────────
hr; echo "0) HEALTH CHECK — GET /api/health"
tmp=$(mktemp); code=$(curl -s -o "$tmp" -w '%{http_code}' "$HEALTH")
check "Sunucu sağlık kontrolü" 200 "$tmp" "$code"; rm -f "$tmp"

# ───────────────────────── 1) AUTH ─────────────────────────
hr; echo "1) AUTH — Kayıt / Giriş / Şifre işlemleri"

OUT=$(req POST /auth/register 200 "Kayıt ol (register)" "{\"firstName\":\"$FNAME\",\"lastName\":\"$LNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$OUT" | jq -r '.token // empty')
USER_ID=$(echo "$OUT" | jq -r '.userId // empty')
echo "   → Alınan JWT: ${TOKEN:0:24}..."

req POST /auth/register 409 "Aynı e-posta ile tekrar kayıt (çakışma beklenir)" "{\"firstName\":\"$FNAME\",\"lastName\":\"$LNAME\",\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" > /dev/null

req POST /auth/login 200 "Giriş yap (login)" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}" > /dev/null

req POST /auth/login 401 "Yanlış şifre ile giriş (yetkisiz beklenir)" "{\"email\":\"$EMAIL\",\"password\":\"yanlisSifre123\"}" > /dev/null

FORGOT_OUT=$(req POST /auth/forgot-password 200 "Şifremi unuttum (forgot-password)" "{\"email\":\"$EMAIL\"}")
RESET_TOKEN=$(echo "$FORGOT_OUT" | jq -r '.resetToken // empty')
echo "   → Alınan reset token: ${RESET_TOKEN:0:16}..."

req POST /auth/reset-password 200 "Şifre sıfırla (reset-password)" "{\"token\":\"$RESET_TOKEN\",\"newPassword\":\"$NEWPASS\"}" > /dev/null

LOGIN2_OUT=$(req POST /auth/login 200 "Yeni şifre ile giriş" "{\"email\":\"$EMAIL\",\"password\":\"$NEWPASS\"}")
TOKEN=$(echo "$LOGIN2_OUT" | jq -r '.token // empty')

req POST /auth/change-password 200 "Şifre değiştir (change-password)" "{\"currentPassword\":\"$NEWPASS\",\"newPassword\":\"$PASSWORD\"}" "$TOKEN" > /dev/null

# Giriş tokenını yeniden al (şifre değişti, eski token hâlâ geçerli olabilir ama garanti olsun)
RELOGIN_OUT=$(req POST /auth/login 200 "Tekrar giriş (final token)" "{\"email\":\"$EMAIL\",\"password\":\"$PASSWORD\"}")
TOKEN=$(echo "$RELOGIN_OUT" | jq -r '.token // empty')
echo "   → Kullanılacak nihai JWT: ${TOKEN:0:24}..."

# ───────────────────────── 2) PROFILE (users/me) ─────────────────────────
hr; echo "2) PROFILE — /users/me"

req GET /users/me 200 "Profili getir (getProfile)" "" "$TOKEN" > /dev/null

req PATCH /users/me 200 "Profili güncelle (updateProfile)" "{\"firstName\":\"$FNAME-Guncel\",\"lastName\":\"$LNAME\"}" "$TOKEN" > /dev/null

req POST /users/me/avatar 200 "Avatar yükle (uploadAvatar)" "{\"avatarUrl\":\"https://example.com/avatars/${RAND}.png\"}" "$TOKEN" > /dev/null

req GET /users/me 401 "Profili tokensız iste (yetkisiz beklenir)" "" "" > /dev/null

# ───────────────────────── 3) DEVICES ─────────────────────────
hr; echo "3) DEVICES — Cihaz işlemleri"

DEV_OUT=$(req POST /devices 200 "Cihaz oluştur (create)" "{\"name\":\"$DEVICE_NAME\",\"modelCode\":\"$MODEL_CODE\"}" "$TOKEN")
DEVICE_ID=$(echo "$DEV_OUT" | jq -r '.id // empty')
echo "   → Oluşturulan cihaz ID: $DEVICE_ID"

req GET /devices 200 "Cihazları listele (list)" "" "$TOKEN" > /dev/null

req POST /devices/pair 200 "Cihaz eşleştir (pair — QR/manuel kod)" "{\"pairingCode\":\"$PAIR_CODE\",\"name\":\"EslesenCihaz-$RAND\"}" "$TOKEN" > /dev/null

req PATCH "/devices/$DEVICE_ID/ping" 200 "Cihaza ping at (ping/lastSeenAt güncelle)" "" "$TOKEN" > /dev/null

req DELETE "/devices/$DEVICE_ID" 204 "Cihazı sil (delete)" "" "$TOKEN" > /dev/null

req PATCH "/devices/00000000-0000-0000-0000-000000000000/ping" 404 "Var olmayan cihaza ping (404 beklenir)" "" "$TOKEN" > /dev/null

# ───────────────────────── 4) PRESETS ─────────────────────────
hr; echo "4) PRESETS — Hazır ayar işlemleri"

PRESET_OUT=$(req POST /presets 200 "Preset oluştur (create)" "{\"name\":\"$PRESET_NAME\",\"mode\":\"$MODE\",\"selectedSections\":$SECTIONS,\"donenessLevels\":$DONE_LEVELS}" "$TOKEN")
PRESET_ID=$(echo "$PRESET_OUT" | jq -r '.id // empty')
echo "   → Oluşturulan preset ID: $PRESET_ID"

req GET /presets 200 "Presetleri listele (list)" "" "$TOKEN" > /dev/null

req PUT "/presets/$PRESET_ID" 200 "Preset güncelle (update)" "{\"name\":\"$PRESET_NAME-v2\",\"mode\":\"$MODE\",\"selectedSections\":[1,2],\"donenessLevels\":[\"hard\",\"soft\"]}" "$TOKEN" > /dev/null

SHARE_OUT=$(req GET "/presets/$PRESET_ID/share" 200 "Paylaşım kodu üret/getir (share)" "" "$TOKEN")
SHARE_CODE=$(echo "$SHARE_OUT" | jq -r '.shareCode // empty')
echo "   → Paylaşım kodu: $SHARE_CODE"

req POST /presets/import 200 "Paylaşım koduyla içe aktar (import)" "{\"code\":\"$SHARE_CODE\"}" "$TOKEN" > /dev/null

req POST /presets/import 404 "Geçersiz kodla içe aktarma (404 beklenir)" "{\"code\":\"GECERSIZ-${RAND}\"}" "$TOKEN" > /dev/null

req DELETE "/presets/$PRESET_ID" 204 "Preset sil (delete)" "" "$TOKEN" > /dev/null

# ───────────────────────── 5) COOK SESSIONS ─────────────────────────
hr; echo "5) COOK SESSIONS — Pişirme oturumları"

# Yeni cihaz (silinen yerine)
DEV2_OUT=$(req POST /devices 200 "(yardımcı) İkinci cihaz oluştur" "{\"name\":\"PisirmeCihazi-$RAND\",\"modelCode\":\"$MODEL_CODE\"}" "$TOKEN")
DEVICE2_ID=$(echo "$DEV2_OUT" | jq -r '.id // empty')

COOK_OUT=$(req POST /cook/sessions 200 "Pişirme başlat (startCook)" "{\"deviceId\":\"$DEVICE2_ID\",\"presetName\":\"$PRESET_NAME\",\"mode\":\"$MODE\",\"selectedSections\":$SECTIONS,\"donenessLevels\":$DONE_LEVELS,\"scheduledAt\":null}" "$TOKEN")
SESSION_ID=$(echo "$COOK_OUT" | jq -r '.id // empty')
echo "   → Oluşturulan oturum ID: $SESSION_ID"

req GET /cook/sessions 200 "Pişirme geçmişini listele (history)" "" "$TOKEN" > /dev/null

req PATCH "/cook/sessions/$SESSION_ID" 200 "Oturum durumunu güncelle → preheating" "{\"status\":\"preheating\"}" "$TOKEN" > /dev/null
req PATCH "/cook/sessions/$SESSION_ID" 200 "Oturum durumunu güncelle → active" "{\"status\":\"active\"}" "$TOKEN" > /dev/null
req PATCH "/cook/sessions/$SESSION_ID" 200 "Oturum durumunu güncelle → paused" "{\"status\":\"paused\"}" "$TOKEN" > /dev/null
req PATCH "/cook/sessions/$SESSION_ID" 200 "Oturum durumunu güncelle → resumed" "{\"status\":\"resumed\"}" "$TOKEN" > /dev/null
req PATCH "/cook/sessions/$SESSION_ID" 200 "Oturum durumunu güncelle → completed" "{\"status\":\"completed\"}" "$TOKEN" > /dev/null

req PATCH "/cook/sessions/$SESSION_ID" 400 "Geçersiz durum değeri gönder (400 beklenir)" "{\"status\":\"asdasd-gecersiz\"}" "$TOKEN" > /dev/null

# Planlanmış pişirme (scheduledAt dolu)
SCHED_TIME=$(date -u -v+2H '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '+2 hour' '+%Y-%m-%dT%H:%M:%SZ')
req POST /cook/sessions 200 "Planlanmış pişirme oluştur (scheduledAt dolu)" "{\"deviceId\":\"$DEVICE2_ID\",\"presetName\":\"$PRESET_NAME\",\"mode\":\"separate\",\"selectedSections\":[1,2,3,4,5,6],\"donenessLevels\":[\"soft\",\"medium\",\"hard\",\"soft\",\"medium\",\"hard\"],\"scheduledAt\":\"$SCHED_TIME\"}" "$TOKEN" > /dev/null

req DELETE /cook/sessions/history 204 "Pişirme geçmişini temizle (clearHistory)" "" "$TOKEN" > /dev/null

# ───────────────────────── 6) NOTIFICATIONS ─────────────────────────
hr; echo "6) NOTIFICATIONS — Bildirim tercihleri"

req GET /notifications/preferences 200 "Bildirim tercihlerini getir (getPrefs)" "" "$TOKEN" > /dev/null

req PUT /notifications/preferences 200 "Bildirim tercihlerini güncelle (updatePrefs — rastgele bool'lar)" "{\"cookComplete\":true,\"fiveMinReminder\":false,\"scheduledStart\":true,\"offlineAlert\":false,\"firmwareUpdates\":true,\"tipsRecipes\":false,\"vestelMarketing\":true}" "$TOKEN" > /dev/null

# ───────────────────────── 7) WATCH SETTINGS ─────────────────────────
hr; echo "7) WATCH SETTINGS — Akıllı saat ayarları"

req GET /watch/settings 200 "Saat ayarlarını getir (get)" "" "$TOKEN" > /dev/null

req PUT /watch/settings 200 "Saat ayarlarını güncelle (update — rastgele bool'lar)" "{\"haptics\":true,\"chime\":true,\"autoStart\":false}" "$TOKEN" > /dev/null

# ───────────────────────── ÖZET ─────────────────────────
hr
echo "TEST SONUCU ÖZETİ"
echo "  Toplam: $((PASS+FAIL))   ✔ Başarılı: $PASS   ✘ Başarısız: $FAIL"
hr
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
