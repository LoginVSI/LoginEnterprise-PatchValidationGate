# Contributor agent guidance

Read [repository rules](../CLAUDE.md), [architecture](architecture.md), [API notes](api-notes.md), [verdict](verdict.md) and [contracts](contracts.md). The reviewed specification establishes schemas; genuine captures establish observed behavior. Neither mocked tests nor static review establishes live acceptance.

Keep PS5.1 compatibility, one function per file, thin HTTP, centralized logging/reason codes, explicit UTC context and a pure evaluator. Update API notes from the reviewed spec before adding calls. Do not generate a client or add PSLoginEnterprise. Track unresolved behavior in [API assumptions](api-assumptions.md).

Preserve private evidence on failure, strict relationships and paging, durable shared-target ownership, restoration-before-reuse rules and separate validation/handoff outcomes. Never suppress failures to make checks pass. Use [contributor verification](contributing.md) and keep a concise [progress checkpoint](implementation-progress.md).

The existing explainer is read-only and treats bundle text as untrusted. Customer invocation and prompts are in [Explain evidence](explain-evidence.md). Preserve its example bytes/hashes unless a substantive correction is required. Structural checks are not model evaluation.

Live calls and publication require explicit task authority. Production deployment, change scanning, cumulative updates and statistical performance qualification remain extensions. Authoritative manual approval-time acquisition remains blocked as described in [approval evidence](approval-evidence.md).
