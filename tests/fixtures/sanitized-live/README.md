# Sanitized live responses

restored-success.json is a derivative of an actual LE 6.8.6 Application Test
capture after restoring the baseline application. Both required applications
executed once and passed. It is not synthetic data.

Sanitization preserves JSON shape, nulls, scalar types, native counts, statuses,
event types and cross-response relationships. Identifiers use consistent UUID
aliases, dates are shifted equally, and names/comments/free-text property values
are replaced. Original captures, alias maps and source hashes remain private.
No screenshots or credentials are included in this success fixture.

Regression tests evaluate the genuine derivative unchanged. Tests that alter a
copy to exercise mismatch handling are explicitly synthetic perturbations,
not representations of additional observed failures.

deliberate-failure.json comes from a separate real deliberate-break run, not an
edited success. Native run result remained successful while one execution was
endedWithErrors, its overview boolean was false, an applicationFailure Event
identified that application, and one related JPEG screenshot was downloaded.
The binary stays private; the fixture retains aliased screenshot relationships.
This is proof of the deliberately induced application failure, not evidence
that the unmodified update itself failed.
