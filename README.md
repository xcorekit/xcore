# xcore

xcorekit private barrel — installs the full xcorekit tool suite in one command.

## Install everything

```bash
git clone git@github.com:xcorekit/xcore.git
cd xcore && ./install.sh
source ~/.bashrc
```

## Update everything

```bash
cd xcore && ./install.sh --update
# or once installed:
# isconl-update handles this too
```

## What gets installed

| Tool | Command(s) |
|------|-----------|
| git-core | `commitx` `git-prx` |
| bash-core | `promptx` |
| animate-core | `animatex` |
| calendar-core | `equicycle` `calendarx` |
| finance-core | `financex` |
| backup-core | `backupx` |
| sys-core | `updatex` `refreshx` `serverx` |

Each tool is also individually installable:
```bash
git clone git@github.com:xcorekit/git-core.git && cd git-core && ./install.sh
```
