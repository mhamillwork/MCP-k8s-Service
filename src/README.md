# MCP Python Sources

Place the five existing MCP Python entry points in this directory. Do **not** invent replacements here.

| Expected filename | Service |
|---|---|
| `technical_knowledge_mcp.py` | Technical Knowledge MCP |
| `wobbegong_sql_mcp.py` | Wobbegong SQL MCP |
| `gtiss_dis_knowledge_mcp.py` | GTISS/DIS Knowledge MCP |
| `devsecops_knowledge_mcp.py` | DevSecOps Knowledge MCP |
| `atoms_knowledge_mcp.py` | ATOMS Knowledge MCP |

## Adding scripts

Copy the production scripts from the isolated environment into this directory with the exact filenames above. Preserve any accompanying helper modules if the scripts import them, and update the corresponding Dockerfile and requirements file accordingly.

After copying:

1. Inspect imports and update `requirements/<service>.txt`.
2. Confirm MCP transport (stdio / SSE / Streamable HTTP), bind port, and endpoint.
3. Align Helm values (`command`, `args`, `mcp.*`, probes, env names) with the real implementation.
4. Rebuild images and re-run `scripts/validate.sh`.

Until the scripts are present, Docker builds and functional MCP validation will fail by design.
