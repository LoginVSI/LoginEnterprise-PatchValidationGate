# Architecture

## Components

**Trigger.** Today it is a `workflow_dispatch` run with a change identifier, a policy file, and a promotion mode. Detection adapters (vulnerability scanner, Autopatch release, patch catalog) come later and feed the same three inputs.

**Change adapter.** A script with a fixed contract, apply / verify / revert, that puts the validation target into the changed state. The reference adapter installs a pinned third-party application update. Windows cumulative update orchestration, with its reboots and install times, is out of scope for the reference and stays with the endpoint tool.

**Login Enterprise validation.** An existing application test is resolved by name, started, and polled to completion through the Public API.

**Results retrieval.** Application executions, measurements, events, and screenshots for the run are written to disk raw before anything evaluates them.

**Policy evaluator.** A pure function. Results plus policy (plus a baseline, later) go in, a verdict comes out. No network calls. Same inputs, same verdict, every time. This is the part a reader can unit test without an appliance.

**Evidence bundle.** Manifest, raw results, screenshots, verdict, and a short human-readable summary, uploaded as a workflow artifact whether the run passed or not.

**Gate and handoff.** Two modes. In manual mode the downstream job runs only on PASS and sits behind a protected environment with a named reviewer. In auto mode, a PASS that also satisfies the guardrails in the policy promotes without waiting and emits an event saying so. FAIL and INCONCLUSIVE stop for a person in both modes. The reference handoff writes a promotion record; a real deployment would call the existing deployment system here.

**Post-deployment continuous testing.** Once the change is promoted, the same application workflow is scheduled as a Login Enterprise continuous test so it keeps being validated in production. Call this continuous validation. It is not monitoring.

## Boundaries

Login Enterprise validates. The policy evaluates. A person or the existing deployment system approves and promotes. The gate never deploys, never rolls back, and never calls a patch safe.

## Data flow

```
change detected â”€â”€> change adapter â”€â”€> validation target
                                             â”‚
                          Login Enterprise application test
                                             â”‚
                                 raw results on disk
                                             â”‚
                               policy evaluator (pure)
                                             â”‚
                          verdict.json + evidence bundle
                                             â”‚
        â”Œâ”€â”€â”€â”€â”€â”€ this repo â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”¼â”€â”€â”€â”€â”€â”€ customer systems â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”
        â”‚                                    â–¼                                  â”‚
        â”‚   PASS â”€â”€> manual approval or auto guardrails â”€â”€> promotion record â”€â”€> Intune / ConfigMgr /
        â”‚   FAIL or INCONCLUSIVE â”€â”€> stop, evidence kept, person notified        Autopatch / Citrix /
        â”‚                                                                        Horizon / ServiceNow
        â””â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”˜
                                             â”‚
                    same workflow â”€â”€> Login Enterprise continuous testing (post-deployment)
```

## Idempotency and failure handling

The run key is the change identifier plus the policy hash. Before starting a test the gate looks for an existing run under that key and resumes polling instead of starting a second one. Reads retry with backoff. Writes are never retried blindly. A timeout, a launcher or connection error, or an incomplete result set produces INCONCLUSIVE, never FAIL, because none of those tell you anything about the patch.

## Deferred

Baselines and performance statistics. Image-level validation. Real Windows cumulative update orchestration. Detection adapters. ServiceNow change attachment. Auto-gate guardrail definitions beyond the functional policy. A read-only AI explainer for evidence bundles.