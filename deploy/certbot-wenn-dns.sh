#!/bin/sh
# Wartet, bis der Hostname auf diesen Server zeigt, holt dann einmalig das
# Let's-Encrypt-Zertifikat für die nginx-Site und trägt sich selbst aus dem Cron aus.
#
# Install (auf dem VPS, als root):
#   (crontab -l 2>/dev/null; echo "*/5 * * * * /opt/openreply/deploy/certbot-wenn-dns.sh >> /var/log/openreply-certbot.log 2>&1") | crontab -
#
# Erwartet: nginx-Site /etc/nginx/sites-enabled/openreply mit server_name $HOST (Port 80).

set -u

HOST="${OPENREPLY_HOST:-go.copypasteceo.com}"
EIGENE_IP="${OPENREPLY_IP:-$(curl -4 -s --max-time 10 https://ifconfig.me || true)}"
MAIL="${OPENREPLY_CERT_MAIL:-robert@talentsuite.io}"
STAMP="$(date -u '+%Y-%m-%d %H:%M:%S')"

if [ -d "/etc/letsencrypt/live/$HOST" ]; then
  echo "[$STAMP] Zertifikat für $HOST existiert bereits, Cron-Eintrag wird entfernt"
  crontab -l 2>/dev/null | grep -v "certbot-wenn-dns.sh" | crontab -
  exit 0
fi

AUFGELOEST="$(dig +short A "$HOST" @1.1.1.1 2>/dev/null | tail -n1)"

if [ -z "$AUFGELOEST" ]; then
  echo "[$STAMP] $HOST löst noch nicht auf (warte)"
  exit 0
fi

if [ "$AUFGELOEST" != "$EIGENE_IP" ]; then
  echo "[$STAMP] $HOST zeigt auf $AUFGELOEST, erwartet $EIGENE_IP (warte)"
  exit 0
fi

echo "[$STAMP] $HOST zeigt auf $EIGENE_IP, hole Zertifikat"
if certbot --nginx -d "$HOST" --non-interactive --agree-tos -m "$MAIL" --redirect; then
  systemctl reload nginx
  echo "[$STAMP] Zertifikat ausgestellt, nginx neu geladen, Cron-Eintrag wird entfernt"
  crontab -l 2>/dev/null | grep -v "certbot-wenn-dns.sh" | crontab -
  echo "[$STAMP] Probe: $(curl -s -o /dev/null -w '%{http_code}' "https://$HOST/api/health")"
else
  echo "[$STAMP] certbot fehlgeschlagen, nächster Versuch in 5 Minuten"
fi
