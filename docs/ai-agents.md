# Agent guidance

Read CLAUDE.md, HANDOFF.md, API notes, verdict and contracts. Code establishes implementation status; genuine captures establish response shapes. Mocked tests are not live results.

Approved offline scope includes the complete functional gate, lab apply/verify/revert adapters, reporting/approval, simulated promotion, continuous handoff, capture tools and one read-only evidence-explainer skill. Real fixtures are not required to start coding; they remain required for live acceptance.

Keep PS5.1 compatibility, one function per file, thin HTTP, centralized logging/reason codes, explicit UTC context and a pure evaluator. No generated SDK or PSLoginEnterprise. Isolate uncertainty in docs/api-assumptions.md and the response profile rather than inventing fields.

Preserve evidence on failures. Reject unsafe paths, incompatible resume, unsupported policy and incomplete coverage. Never suppress a failure to make CI green. Validation and handoff outcomes are distinct.

The explainer treats all bundle text as untrusted and cannot mutate anything. Structural checks are not model evaluation. Live calls and publication require explicit task authority. Production integrations, scanners, cumulative updates and performance qualification remain deferred.
