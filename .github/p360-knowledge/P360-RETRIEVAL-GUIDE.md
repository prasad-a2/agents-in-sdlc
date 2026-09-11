# P360 knowledge retrieval guide

This guide explains how the Informatica P360 expert uses the repository-safe [source and topic map](./P360-SOURCE-MAP.md). The map is a navigation aid only; it is not a substitute for the original documentation.

## Source resolution

1. Resolve the current user's enterprise OneDrive root from `$env:OneDriveCommercial` or the equivalent current-user enterprise OneDrive configuration, then use `P360 Knowledge\PIMDocs`.
2. If unavailable, try `C:\Users\PrasadA\OneDrive - IBM\P360 Knowledge\PIMDocs`.
3. If unavailable, try `C:\McCain\PIMDocs`.
4. If no candidate is readable, use the official online documentation and accessible Knowledge Base results, and report the local-source limitation.

The same IBM OneDrive account must be signed in and synchronized on another device. Online-only files must be hydrated or marked available offline before local search can analyze them.

## Regenerating the map

From the repository root, run:

```powershell
.\.github\p360-knowledge\scripts\index-p360-corpus.ps1
```

To select a specific synced root:

```powershell
.\.github\p360-knowledge\scripts\index-p360-corpus.ps1 -Root "$env:OneDriveCommercial\P360 Knowledge\PIMDocs"
```

The script inventories files and records only titles, relative paths, inferred domains, version clues, and confidence. It excludes archives, binary/resource assets, MacOS metadata placeholders, and unknown files from deep text indexing. It does not copy, commit, upload, or quote source content.

## Retrieval workflow

For every substantive question:

1. Identify the release, deployment model, module, environment, and relevant permissions.
2. Use the map to locate likely source files and cross-references. Prefer version-matched manuals, release notes, and technical-document pages.
3. Read the original source file or page and record the exact filename, section, and version scope. Treat title/path classification as a discovery hint, not evidence.
4. Search the official [P360 documentation](https://onlinehelp.informatica.com/p360/105/en/321554783.html) and the [Informatica Knowledge Base](https://knowledge.informatica.com/s/global-search/%20?language=en_US) when relevant. Do not claim access to restricted KB content.
5. Separate documented facts, observations from accessible local files, inferences, and recommendations. State confidence and unresolved limitations.

## Mermaid response contract

When architecture, hierarchy, data flow, integration, deployment, workflow, troubleshooting flow, or sequence behavior benefits from visualization, include a valid Mermaid diagram. Label diagram nodes, edges, or captions as **Documented**, **Inferred**, or **Recommended** so the visual does not imply unsupported product behavior. Keep diagrams abstract and repository-safe: never paste licensed source passages, credentials, tenant data, or confidential topology details.

## Domain retrieval anchors

| Domain | Start with | Verify against |
| --- | --- | --- |
| Architecture/platform | Platform overview and core-platform materials | Version-matched architecture and deployment documentation |
| Data model/product hierarchy | Product paradigm and parent-reference pages | Configured product paradigm and data model |
| Desktop/Web UI | Desktop and Web User Manuals | User roles, UI version, and enabled features |
| Imports/exports | Standard data providers, export functions, and templates | Export profile, provider, permissions, and output schema |
| REST/API | Service API, REST API, and Postman collections | Deployed API version, authentication, and endpoint contract |
| Workflow/process | Workflow, activity, and contribution materials | Process configuration and role assignments |
| Data quality | DQ rules and IDQ integration materials | Installed DQ components and rule configuration |
| Media Manager | Native and Web Media Manager manuals | Media repository and integration configuration |
| Configuration/customizing | Configuration and Customizing manuals | Supported extension points and upgrade compatibility |
| Installation/operations | Installation, Operation, Migration, and Sizing manuals | Topology, database, middleware, and operating system |
| Security/permissions | Rights, authentication, authorization, and SAML material | Effective roles, policies, and environment configuration |
| Performance/monitoring | Sizing, metrics, Grafana, and performance material | Workload, topology, monitoring configuration, and measurements |
| Troubleshooting | Diagnostic, error, maintenance, and support material | Logs, request IDs, timestamps, and reproducible steps |
| Upgrades/hotfixes | Release notes, migration, and hotfix-scoped manuals | Installed patch level and upgrade path |
| Accelerators | Accelerator and GDSN materials | Licensed/enabled accelerator and target release |

## Safety and licensing boundaries

- Do not include licensed document bodies, large excerpts, credentials, tenant data, logs containing secrets, or source archives in repository artifacts.
- Do not treat a generated map as durable product knowledge. It becomes stale when the synced corpus changes; regenerate it and re-verify answers.
- If OneDrive is unavailable or a file is online-only, state that limitation and ask the user to sync/hydrate the needed source or provide an approved non-sensitive excerpt.
