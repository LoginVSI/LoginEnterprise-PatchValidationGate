# Portability

Keep adapter, verdict, evidence and promotion contracts unchanged when translating orchestration.

| Platform | Mapping |
|---|---|
| Azure DevOps | Parameters, protected environment approval, exclusive target resource, secrets, pipeline artifact download with independent hash. Capture actual reviewer/time. |
| GitLab | Protected manual jobs or explicit auto rules, resource_group per target, protected runners/variables, immutable artifacts and verified hashes. |
| Jenkins | Trusted pipeline, lockable target resource, credential binding, audited input approval, archived artifacts and verified hashes. |
| ServiceNow | Change issue becomes change record, comments become work notes, sanitized evidence becomes attachments. An authorized integration can consume the promotion contract. No connector is implemented. |

Preserve durable recovery state, non-PASS gates, separate handoff records, private originals and stop-before-mutation rules. Production promotion remains simulated until a real deployment integration exists.
