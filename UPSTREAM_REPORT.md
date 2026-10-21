# Upstream report (copy-ready; NOT filed)

Destination: https://github.com/microsoft/kiota/issues (the Dart writer lives in that repo).
Searches of microsoft/kiota issues/PRs for the Dart `additionalData` / discriminated error
symptoms returned no open issue. The defects are already fixed in Kiota 1.36.0 (see the 1.36.0 release
notes: https://github.com/microsoft/kiota/releases/tag/v1.36.0). v1.36.1 is the latest release as of
2026-10-21 (https://github.com/microsoft/kiota/releases/latest). **Recommendation: do not file** for
1.36.x; upgrade to >= 1.36.0. The text below applies only to 1.35.0 and is kept for reference.

---

**Title:** Dart: discriminated error base generates uncompilable client (1.35.0)

**Version:** Kiota 1.35.0+114aa7ee609262d892fd9ceb02b2d9f7ecb84190, Dart 3.13.5,
`microsoft_kiota_abstractions` 0.3.0.

**Reproduction:** REPO_COMMIT_URL (run `scripts/reproduce.sh 1.35.0`; schema in `openapi.yaml`).
`kiota generate --language Dart --openapi openapi.yaml --class-name ReproClient --namespace-name repro --output lib/src --exclude-backward-compatible`, then `dart analyze lib`.

**Actual:** `ProblemDetailsDto extends ApiException` with `required this.additionalData`, but
derived classes call `super()` and the discriminator factory calls `ProblemDetailsDto()` /
`ConflictProblemDto()` without it:
```
1 MISSING_REQUIRED_ARGUMENT|gone_problem_dto.dart
3 MISSING_REQUIRED_ARGUMENT|problem_details_dto.dart
1 RETURN_OF_INVALID_TYPE|problem_details_dto.dart   (ApiException returned where ProblemDetailsDto is declared)
```

**Expected:** a client that compiles; `additionalData` optional and discriminated children
inheriting from the base. Kiota 1.36.0/1.36.1 produce this (0 analyzer errors).
