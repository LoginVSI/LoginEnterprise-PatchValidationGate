# Test fixtures

Sanitized JSON captured from a real Login Enterprise appliance. Unit tests load these so they can exercise the module against response shapes that actually came off the wire, without needing an appliance.

## Naming

One file per endpoint and scenario, lower case, hyphen separated:

```
{endpoint}.{scenario}.json
```

The endpoint part is the path with slashes turned into dots and ids replaced by their placeholder name. The scenario says what makes this capture interesting.

Examples:

```
system.version.json
tests.applicationTest.two-candidates-one-exact.json
tests.testId.test-runs.existing-run-for-change.json
test-runs.testRunId.completed-successful.json
test-runs.testRunId.completed-internalError.json
test-runs.testRunId.created.json
```

## Sanitization rule

Before a capture is committed:

- No hostnames, IP addresses, or URLs that point at a real appliance. Replace them with `appliance.example.test`.
- No account names, user names, email addresses, or domain names. Replace with `user01`, `example.test`, and so on.
- No tokens or credentials of any kind, anywhere in the body or in headers that were captured alongside it.
- Ids are fine. GUIDs and run ids carry no information on their own and keeping them makes the fixture match the real shape.
- Test names and application names are fine if they are generic. Rename anything that identifies a customer or a project.
- Keep the shape. Do not remove fields, reorder them, or reformat beyond pretty printing. The point of a fixture is that it looks exactly like what the appliance sends.

If you are unsure whether something identifies a customer, replace it.

## Capturing

Point the module at the appliance with `LE_BASE_URL` and `LE_API_TOKEN`, run the call, and save the raw object with `ConvertTo-Json -Depth 20`. Then sanitize by hand and read the whole file once more before committing. See docs/contributing.md for the review checklist.
