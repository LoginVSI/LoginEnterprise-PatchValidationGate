# Functional policy

Copy default.policy.json to an ignored *.local.json file. Replace both CONFIGURE application IDs from reviewed captures. Both Notepad and the chosen demo application are required. Placeholders intentionally fail validation.

Test-LEGatePolicyDefinition validates on PS5.1. Supported settings: version 1, named test, positive integer wait/poll limits up to 3600, explicit unique application IDs, allowStepRetries 0, failOnAnyApplicationFailure true, performance.enabled false, manual/auto mode, and exactly verdict:PASS plus results-complete auto guards.

Unknown keys, missing sections, empty coverage, retries, enabled performance policy, and unknown guards are rejected. The six inconclusiveWhen codes are mandatory in supplied order. They cannot disable integrity checks.

Hashes identify exact policy bytes, including whitespace. Keep identical bytes for resume/promotion. See [verdict](../docs/verdict.md).
