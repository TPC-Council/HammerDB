# HammerDB 6.1.1 multi-architecture Docker test plan

This release adds a separate VillageSQL image; eight images in total (base, mysql, maria, postgres, oracle, mssqls, villagesql, combined).

## Before builds

- Wait until the TPC releases HammerDB v6.1.1 publicly with both Ubuntu 24.04 amd64 and ARM64 archives.
- Verify both release archive SHA-256 values against the actual downloaded files.
- Confirm architecture-specific MySQL and Oracle client checksums are current.
- The new workflow remains manual and is not triggered by a tag or release event.

## Validation

1. Run build-only on linux/amd64 and linux/arm64; smoke-test all eight images.
2. Verify the separate VillageSQL image resolves the MySQL client library and the HammerDB librarycheck reports VillageSQL.
3. Verify the combined image reports MySQL, MariaDB, PostgreSQL, Oracle, MSSQLServer and VillageSQL.
4. Once the TPC release is public, run push-test, verifying immutable test manifests and all eight manifest digests.
5. Promote only the exact tested digests from the upstream TPC-Council repository after explicit approval. The HammerDBLtd fork cannot promote production.

Do not run push-test or production promotion prior to public release.
