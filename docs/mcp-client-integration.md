# MCP Client Integration

## Intended clients

- Open WebUI
- AI agents that call MCP tools (including agents backed by vLLM)
- Ollama-based applications that use an MCP-capable client/agent layer
- Cline and other IDE/agent tools with MCP support

**Note:** vLLM and Ollama typically provide model inference. They do not automatically discover or execute MCP tools. An MCP-capable client or agent must perform tool discovery, invocation, and result handling.

## Connection parameters (after transport verification)

| Service | ClusterIP (in-cluster) | Shared Gateway HTTPS (one IP, different ports) |
|---|---|---|
| Technical Knowledge | `http://mcp-technical-knowledge.mcp.svc.cluster.local:8000/mcp` | `https://mcp.example.local:8443/mcp` |
| Wobbegong SQL | `http://mcp-wobbegong-sql.mcp.svc.cluster.local:8000/mcp` | `https://mcp.example.local:8444/mcp` |
| GTISS/DIS | `http://mcp-gtiss-dis-knowledge.mcp.svc.cluster.local:8000/mcp` | `https://mcp.example.local:8445/mcp` |
| DevSecOps | `http://mcp-devsecops-knowledge.mcp.svc.cluster.local:8000/mcp` | `https://mcp.example.local:8446/mcp` |
| ATOMS | `http://mcp-atoms-knowledge.mcp.svc.cluster.local:8000/mcp` | `https://mcp.example.local:8447/mcp` |

All Gateway URLs share one hostname/IP (`mcp-shared-gateway`). Clients must trust the internal CA.

Confirm transport, port, and path against each Python script before configuring clients.

## Tool discovery and validation

1. Confirm the Service endpoints resolve inside the cluster (`nslookup` / `curl` from a debug pod).
2. Use the client’s MCP add-server flow with the correct transport.
3. List tools/resources and verify names match expectations from the Python implementation.
4. Execute a low-risk read-only tool first.
5. Validate error handling for auth failures and upstream outages (Neo4j / APIs / SQLite).

## Authentication

- Prefer network isolation (ClusterIP + NetworkPolicy) for internal clients.
- If the application supports MCP endpoint authentication, configure it via Secrets and document the client header/token requirements after script inspection.
- Do not expose MCP services externally without authentication and an explicit HTTPRoute configuration.

## Stdio-only servers

If a script supports only stdio:

1. Do not pretend Helm `mcp.transport: streamable-http` enables HTTP.
2. Run an approved HTTP/SSE/Streamable-HTTP adapter sidecar or gateway that speaks MCP over stdio to the Python process.
3. Point Kubernetes Service traffic at the adapter’s HTTP port.
4. Document the adapter image, command, and session model.

This repository does not ship an MCP gateway by default.

## Common compatibility issues

| Symptom | Likely cause |
|---|---|
| Client cannot connect | Wrong transport, path, or port |
| Tools missing | Server failed startup; upstream dependency down |
| Timeouts | Probe/port mismatch; server blocked on Neo4j/API |
| Works locally, fails in cluster | DNS name, NetworkPolicy, or Secret misconfiguration |
| Mutating actions unexpected | Over-privileged DevSecOps tokens or tools |

Treat tool results and retrieved documents as untrusted data, not instructions that override operational policy.
