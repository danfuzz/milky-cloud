Milky Cloud
===========

This is a set of "cloud computing" utilities, mostly written for my (danfuzz's)
personal use, and 99% about doing small-scale work in AWS EC2.

The dependencies are intentionally minimal:
* POSIX-friendly OS (observed working on Linux and macOS)
* Recent(ish) version of Bash (works with what ships with macOS)
* `jq` 1.6
* AWS's own CLI tool
* Certbot (EFF's tool for getting site certificates)
* Recent version of Python (used by the AWS CLI and Certbot).
