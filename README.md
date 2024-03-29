Milky Cloud
===========

This is a set of "cloud computing" utilities, mostly written for my (danfuzz's)
personal use, and 99% about doing small-scale work in AWS EC2.

The core dependencies are intentionally minimal:
* POSIX-friendly OS (observed working on Linux and macOS)
* Recent(ish) version of Bash (works with what ships with macOS)
* `jq` 1.6
* Recent version of Python (used indirectly).

On top of that, the dependencies are:
* AWS's own CLI tool -- for all AWS-related functionality.
* Certbot -- EFF's tool for getting site certificates.
* op -- the (poorly-named) 1Password CLI tool, only needed if secrets (e.g.
  access keys) are stored in 1Password.

## Instructions

Copy the `scripts` directory wherever you want. It is itself a copy of
[`bashy-lib`](https://github.com/danfuzz/bashy-lib), with an additional
sub-library for this project and a top-level dispatch script. If you have your
own verion of `bashy-lib`, you can instead just copy the directory
`scripts/lib/milky-cloud` and (optionally) the top-level script.
