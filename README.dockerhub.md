# DeepSeek Harness

DeepSeek Harness (`dsh`) is an open-source agent harness developed by [DeepSeek AI](https://deepseek.com), using an architecture where **everything is a plugin**.

## Quick Start

The Web UI binds to `127.0.0.1` inside the container for security. Run it with:

```bash
docker run --rm -it \
  -p 127.0.0.1:3080:3080 \
  -e DEEPSEEK_API_KEY=your_api_key \
  -e DEEPSEEK_BASE_URL=https://api.deepseek.com \
  kwaw/deepseek-harness:latest \
  sh -c '
    node -e "
      const net = require(\"node:net\");
      net.createServer(client => {
        const upstream = net.connect(3081, \"127.0.0.1\");
        client.pipe(upstream);
        upstream.pipe(client);
        const close = () => { client.destroy(); upstream.destroy(); };
        client.on(\"error\", close);
        upstream.on(\"error\", close);
      }).listen(3080, \"0.0.0.0\");
    " &
    exec node --import tsx/esm apps/cli/src/bin.ts web --no-open --port 3081
  '
```

Then open: **http://127.0.0.1:3080**

## Access Token

When the container starts, DeepSeek Harness prints a URL containing a temporary access token:

```text
dsh web: http://127.0.0.1:3081/?token=YOUR_TOKEN
```

The container exposes the relay on port `3080`. Open the same URL with only the port changed to `3080`:

```text
http://127.0.0.1:3080/?token=YOUR_TOKEN
```

Keep the `?token=...` query string unchanged. After the token is accepted, the browser receives an authentication cookie and redirects to the normal Web UI.

The token is generated when the process starts. Restarting the container generates a new token. Treat the token URL as a secret and do not share it.

## What This Does

- Runs an in-container TCP proxy from `0.0.0.0:3080` to `127.0.0.1:3081`
- Starts the DSH Web UI on loopback port `3081`
- Publishes only to the host's `127.0.0.1:3080`
- Preserves the token query string while forwarding requests
- Bypasses the Corepack interactive prompt

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `DEEPSEEK_API_KEY` | Yes | Your DeepSeek API key |
| `DEEPSEEK_BASE_URL` | No | API endpoint (default: `https://api.deepseek.com`) |

## Security Notice

This Web UI provides code-execution capabilities. It does not provide user accounts or multi-user authentication; access is protected by a temporary startup token.

The published port binds to `127.0.0.1` (loopback only), so it is reachable only from your local machine. Do not change this to `0.0.0.0:3080:3080` unless you understand the security implications.

## Using docker-compose

Create a `docker-compose.yml`:

```yaml
services:
  dsh:
    image: kwaw/deepseek-harness:latest
    container_name: deepseek-harness
    ports:
      - "127.0.0.1:3080:3080"
    environment:
      DEEPSEEK_API_KEY: ${DEEPSEEK_API_KEY}
      DEEPSEEK_BASE_URL: ${DEEPSEEK_BASE_URL:-https://api.deepseek.com}
    command: >
      sh -c '
        node -e "
          const net = require(\"node:net\");
          net.createServer(client => {
            const upstream = net.connect(3081, \"127.0.0.1\");
            client.pipe(upstream);
            upstream.pipe(client);
            const close = () => { client.destroy(); upstream.destroy(); };
            client.on(\"error\", close);
            upstream.on(\"error\", close);
          }).listen(3080, \"0.0.0.0\");
        " &
        exec node --import tsx/esm apps/cli/src/bin.ts web --no-open --port 3081
      '
    restart: unless-stopped
```

Create a `.env` file:

```dotenv
DEEPSEEK_API_KEY=your_key_here
DEEPSEEK_BASE_URL=https://api.deepseek.com
```

Run:

```bash
docker compose up -d
```

The container logs contain the token URL. Replace its port `3081` with `3080` before opening it in your browser.

## Links

- **GitHub**: https://github.com/deepseek-ai/deepseek-harness
- **Documentation**: https://github.com/deepseek-ai/deepseek-harness/tree/master/docs
- **License**: MIT

## Version

This image tracks version `0.1.0-rc.8` of DeepSeek Harness.

---

**Note**: This is a community-maintained container. For the official npm distribution, see the [project README](https://github.com/deepseek-ai/deepseek-harness).
