Docker Yumsync CHANGELOG
========================

The version numbers of this docker image do not directly reflect the version number of Yumsync that is being used. Each image version below will indicate what version of Yumsync it is using.

v0.2.0 (2016-01-21)
-------------------

### Feature

* Restore and archive now show better time and percentage estimates

### Bugfix

* Bumped Yumsync to version v0.1.2, this fixes combined metadata generation

| Yumsync |
| :-----: |
| [v0.1.2](https://github.com/jrwesolo/yumsync/tree/v0.1.2) |

v0.1.3 (2016-01-21)
-------------------

### Bugfix

* Do not overwrite archive file if it already exists

| Yumsync |
| :-----: |
| [v0.1.1](https://github.com/jrwesolo/yumsync/tree/v0.1.1) |

v0.1.2 (2016-01-21)
-------------------

Updates in the CentOS 7 image introduced a yum plugin called OVL. This plugin was then being used when python was syncing repos. Tons of "permission denied" errors were showing up in the logs. OVL now gets disabled before Yumsync gets run.

### Bugfix

* Disable yum plugin `ovl` before `yumsync` runs

| Yumsync |
| :-----: |
| [v0.1.1](https://github.com/jrwesolo/yumsync/tree/v0.1.1) |

v0.1.1 (2016-01-21)
-------------------

### Bugfix

* Fixed incorrect use of `pass` in bash script (this isn't python!)

| Yumsync |
| :-----: |
| [v0.1.1](https://github.com/jrwesolo/yumsync/tree/v0.1.1) |

v0.1.0 (2016-01-20)
-------------------

This is the initial release of the Docker image of Yumsync.

| Yumsync |
| :-----: |
| [v0.1.1](https://github.com/jrwesolo/yumsync/tree/v0.1.1) |
