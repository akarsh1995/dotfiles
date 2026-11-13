## About

Personal configuration files, versioned as a git repository that lives at
`~/.config`. The repo is backed up hourly and can bootstrap a fresh macOS or
Linux machine.

## New machine

One-liner (recommended):

```bash
curl -sS "https://raw.githubusercontent.com/akarsh1995/dotfiles/main/bootstrap-config.sh" | bash
```

It installs git/Homebrew/fish if needed, moves any existing `~/.config` to
`~/.config-backup-<timestamp>` (never deletes it), clones the repo into
`~/.config`, and runs `bootstrap.fish`.

Manual:

```bash
git clone git@github.com:akarsh1995/dotfiles.git ~/.config
fish ~/.config/bootstrap.fish
```

`bootstrap.fish` is idempotent and safe to re-run:

```bash
fish ~/.config/bootstrap.fish            # install/refresh everything
fish ~/.config/bootstrap.fish --check    # report gaps, change nothing
fish ~/.config/bootstrap.fish --dry-run  # print actions only
fish ~/.config/bootstrap.fish --install-font
```

Flags: `--skip-brew`, `--skip-font`, `--skip-shell`, `--skip-agents`.
The Nerd Font is opt-in because the upstream archive is ~123 MB; `--check`
tells you if a font is missing.

## Prerequisites after cloning

- **GPG key** `DBF7D3AFC7E8B220` for signed commits and `fish/secure/*.gpg`:

  ```bash
  gpg --import <backup>.asc
  gpg --edit-key DBF7D3AFC7E8B220   # trust -> 5 -> save
  ```

  Then run `bootstrap.fish` again so it enables signing. On macOS, unlock the
  key once and choose **Save in Keychain** in `pinentry-mac`; hourly backups
  run without a TTY and cannot type a passphrase.
- **SSH keys** for GitHub and Codeberg (`ssh -T git@github.com`).
- **GitHub CLI**: `gh auth login` (credentials helper for HTTPS remotes).

## Fish config

Everything under `fish/` is tracked except:

- `fish_variables` (runtime/universal state)
- plaintext files under `fish/secure/` (only `*.gpg` is committed)
- fisher-managed plugins (restored from `fish_plugins`)
- generated files (`rustup.fish`, `terax.fish`, frozen key bindings,
  `completions/bun.fish`, `completions/docker.fish`)

New hand-written functions/completions/scripts are therefore committed
automatically — no `.gitignore` edit needed.

## Auto backup

An hourly agent commits and pushes the repo:

- macOS: `launchd` label `com.akarsh.autobackup` (catches up after sleep)
- Linux: `dotfiles-autobackup.timer` (`Persistent=true`)

Each run refreshes `brew/brew-packages` (installed-on-request formulae and
casks) and `fish/fish_plugins` before committing, so a new machine installs
what this one actually uses. Commits are GPG-signed. GitHub is canonical;
Codeberg is a best-effort mirror. If signing fails, changes stay staged, the
failure is logged, and a desktop notification is shown; the next run retries.

```bash
config-backup             # run now
config-backup --dry-run   # preview
config-backup status      # branch + recent log
config-backup log         # full-ish log
```

Log: `~/.config/scripts/autobackup.log`.

## Guardrails

The pre-commit hook (`scripts/git-hooks/pre-commit`, enabled by bootstrap):

- refuses plaintext files under `fish/secure/`
- runs `fish -n` on staged fish files
- runs `gitleaks` when it is installed

## Scheduled cleanup (macOS)

`launchd` agents `com.akarsh.cleanup.caches` (every other Monday) and
`com.akarsh.cleanup.build` (first Monday) run `scripts/cleanup-scheduled.fish`.
Log: `~/.config/scripts/launchd.cleanup.log`.

## Linux notes

- Scheduled backup uses a systemd user timer; enable lingering if you want it
  to run while logged out: `loginctl enable-linger "$USER"`.
- Unattended signed commits need a keyring-backed pinentry (e.g.
  `pinentry-gnome3`). `bootstrap.fish` warns if none is configured.
- The cleanup agents are macOS-only.

## Troubleshooting

```bash
launchctl print gui/$(id -u)/com.akarsh.autobackup   # macOS
systemctl --user status dotfiles-autobackup.timer     # Linux
tail -50 ~/.config/scripts/autobackup.log
fish -n ~/.config/fish/functions/some-file.fish
```
