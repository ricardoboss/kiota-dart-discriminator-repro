# kiota-dart-discriminator-repro

Minimal synthetic reproduction of Kiota Dart generator defects with a discriminated
error base schema (`ProblemDetailsDto`).

## Result

| Kiota | `dart analyze` errors on generated client |
| --- | --- |
| 1.35.0 | 5: 4x `missing_required_argument` (`additionalData`), 1x `return_of_invalid_type` (`ApiException` vs `ProblemDetailsDto`) |
| 1.36.0 | 0 |
| 1.36.1 (latest release as of 2026-10-21) | 0 |

The defects are fixed upstream in 1.36.0 (release notes: "Dart: an error model's constructor
declared the named `additionalData` parameter as `required` ..."; the `return_of_invalid_type` error
also disappears in 1.36.0, though its release note is stated for C# and Java). See
[UPSTREAM_REPORT.md](UPSTREAM_REPORT.md).

## Reproduce

Needs the .NET SDK (8+) and the Dart SDK (3.13.5 used) on `PATH`.

```sh
scripts/reproduce.sh 1.35.0   # exit 0: exactly the errors in expected/1.35.0.txt
scripts/reproduce.sh 1.36.1   # exit 0: zero analyzer errors (expected/1.36.1.txt is empty)
```

The script installs the pinned Kiota into `.tools/`, generates a client from `openapi.yaml`,
resolves the pinned `microsoft_kiota_*` runtime packages (`pubspec.yaml`) and runs `dart analyze`.
Exit codes: `0` analyzer errors equal `expected/<version>.txt`; `1` they differ (a defect was
fixed or a new one appeared); `2` setup failure (install, generate, `pub get`, analyzer crash).
CI runs the same script for each version; green means the expected result held for all three.

## Schema shape that triggers it

`openapi.yaml`: base `ProblemDetailsDto` with a `type` discriminator, used as the `default` error
response; two derived schemas used as explicit 404/409 error responses, one derived schema
(`GoneProblemDto`) used only in the discriminator mapping.
Out of scope: the runtime `copyWith` subtype-erasing behavior of `microsoft_kiota_http`.
