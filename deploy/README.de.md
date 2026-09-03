# OpenReply für CopyPasteCEO (Hetzner-VPS)

Eigener Fork von `diwenne/openreply`. Läuft komplett auf dem VPS `91.98.237.49`
unter `/opt/openreply` mit Docker Compose; nginx + Let's Encrypt davor.

| Was | Wert |
| --- | --- |
| Öffentliche URL | `https://go.copypasteceo.com` (Dashboard, OAuth-Callback, Webhook, Tracked Links) |
| Web-Port intern | `127.0.0.1:3040` |
| Meta-App | CopyPasteCEO Social (895421260313410), Instagram-App-ID 1055200540394941 |
| OAuth-Redirect in Meta | `https://go.copypasteceo.com/api/instagram/callback` |
| Webhook in Meta | `https://go.copypasteceo.com/api/webhook`, Felder `comments` + `messages` |
| Login | Magic-Link per Resend, nur Adressen aus `ALLOWED_EMAILS` |
| Secrets | `/opt/openreply/.env` (nie im Repo, nie im Chat) |

## Betrieb

```bash
ssh root@91.98.237.49
cd /opt/openreply

# Status / Logs
docker compose --env-file .env -f deploy/docker-compose.vps.yml ps
docker compose --env-file .env -f deploy/docker-compose.vps.yml logs -f --tail=100 worker
curl -s http://127.0.0.1:3040/api/health

# Update auf neuen Stand des Forks (erst lokal committen + pushen!)
git pull
docker compose --env-file .env -f deploy/docker-compose.vps.yml up -d --build

# Datenbank direkt ansehen (Diagnose: WebhookEvent, DmLog, OperationalEvent)
docker compose --env-file .env -f deploy/docker-compose.vps.yml exec postgres psql -U openreply -d openreply
```

## Upstream nachziehen

```bash
git fetch upstream
git merge upstream/main
git push origin main
```

## Was bei einem Domainwechsel angefasst werden muss

1. `NEXTAUTH_URL` in `/opt/openreply/.env`
2. `server_name` in `/etc/nginx/sites-available/openreply` + neues Zertifikat (`certbot --nginx -d <host>`)
3. In der Meta-App: OAuth-Redirect-URI und Webhook-Callback-URL
4. `docker compose ... up -d` (Web + Worker neu starten, Tracked Links nutzen die neue Domain)
