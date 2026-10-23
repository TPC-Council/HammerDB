# HammerDB 6.1 Docker images

These Dockerfiles package the published HammerDB 6.1 Ubuntu 24.04 release tarballs; HammerDB is **not compiled from source**. A single Dockerfile per logical image builds `linux/amd64` and `linux/arm64`, and a multi-platform manifest lets Docker select the host architecture automatically.

Images are built in dependency order: **base → MySQL → MariaDB → PostgreSQL → Oracle → SQL Server → VillageSQL → combined**. Child builds accept image build arguments so validation never mixes 6.1 work with an existing production image. The combined image contains all six database targets (Db2 remains excluded). The obsolete remote-GUI Docker variant was removed; normal HammerDB GUI and web service functionality are unchanged.

## Client design

* MySQL uses the architecture-specific `libmysqlclient.so.24` supplied by HammerDB and validates its SHA-256, ELF machine and SONAME.
* VillageSQL reuses the architecture-specific MySQL client library, with an independent image and librarycheck smoke test.
* MariaDB uses Ubuntu 24.04's architecture-selected `libmariadb3` package.
* PostgreSQL uses PGDG PostgreSQL/libpq 17. This enables testing `sslnegotiation=direct` for issue #901, but the issue is not considered resolved until the separate direct-TLS integration test passes.
* Oracle uses the matching official Instant Client archive at `/opt/oracle/instantclient`.
* SQL Server uses Microsoft's Ubuntu 24.04 ODBC Driver 18 on both architectures and a custom `/usr/local/unixODBC` build with `--enable-fastvalidate`.

## Building and publishing

Run the manual **HammerDB 6.1 multi-architecture images** workflow. Its only trigger is `workflow_dispatch` and its modes are:

* `build-only`: builds and smoke-tests each architecture without logging in or
  publishing externally. Intermediate images are pushed only to a temporary
  registry on the Actions runner so later Buildx builds resolve the exact
  newly built dependencies.
* `push-test`: uses only `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`, refuses
  pre-existing tags, publishes immutable `v6.1-test-<component>-<commit>`
  manifests, and smoke-tests both platform digests before recording them.
* `promote-production`: preflights all eight supplied tested manifest digests
  before changing any tag, then copies those exact manifests without
  rebuilding. It requires explicit confirmation and is blocked outside
  `TPC-Council/HammerDB`.

Production version tags are `v6.1-*` and aliases are the component names (`latest` for combined). Inspect a manifest with `IMAGE=docker.io/tpcorg/hammerdb:v6.1-test-<sha> Docker/tests/test-manifest.sh`. See [the test plan](TESTING-6.1-MULTIARCH.md).

## 6.1 release staging

The v6.1 Git tag is not enough to build the base image: the public release must contain the Ubuntu 24.04 amd64 and arm64 tarballs and verified SHA-256 checksums. Do not run `push-test` or `promote-production` until the TPC release is public. In this fork, production promotion is blocked by the workflow's upstream-only guard.
