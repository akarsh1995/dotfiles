# Password Store (pw)

A simple, secure password manager designed to work seamlessly with GPG encryption.

## Features

- Store passwords securely using GPG encryption
- Generate secure random passwords
- Copy passwords to clipboard without displaying them
- List all stored passwords
- Import/export functionality for backups
- Tab completion for all commands

## Usage

The password store is accessed through the `pw` command:

```
pw COMMAND [ARGS...]
```

### Available Commands

- `pw add NAME [--username=VALUE] [--url=VALUE] [DESCRIPTION]` - Add or update a password (will prompt for password)
- `pw gen NAME [LENGTH] [--username=VALUE] [--url=VALUE] [DESCRIPTION]` - Generate and store a password
- `pw get NAME` - Copy password to clipboard
- `pw show NAME` - Show password in terminal
- `pw user NAME` - Copy username/email to clipboard
- `pw url NAME` - Copy URL to clipboard
- `pw ls` or `pw list` - List all passwords
- `pw rm NAME` - Delete a password
- `pw export PATH` - Export passwords to a file
- `pw import PATH` - Import passwords from a file
- `pw import-pass [DIR]` - Import passwords from standard pass
- `pw init` - Initialize the password store
- `pw help` - Show help message

### Examples

Add a password (will prompt for password):
```fish
pw add github "GitHub account password"
```

Add a password with username (will prompt for password):
```fish
pw add github --username=user@example.com "GitHub account password"
```

Add a password with username and URL (will prompt for password):
```fish
pw add github --username=user@example.com --url=https://github.com "GitHub account password"
```

Generate a random password:
```fish
pw gen netflix 16 "Netflix account password"
```

Generate a random password with username:
```fish
pw gen netflix 16 --username=user@example.com "Netflix account password" 
```

Generate a random password with username and URL:
```fish
pw gen netflix 16 --username=user@example.com --url=https://netflix.com "Netflix account password" 
```

Retrieve a password (copies to clipboard):
```fish
pw get github
```

Display a password in the terminal:
```fish
pw show github
```

Copy the username/email to clipboard:
```fish
pw user github
```

Copy the URL to clipboard:
```fish
pw url github
```

List all stored passwords in a formatted table:
```fish
pw ls
```

Show additional details including update timestamps:
```fish
pw ls --details
```

The password listing displays a nicely formatted table with:
- Password name and hierarchy
- Username/email when available
- URL when available 
- Description
- Last update timestamp (with --details flag)

Delete a password:
```fish
pw rm github
```

Export passwords for backup:
```fish
pw export ~/backup/passwords.gpg
```

Import passwords:
```fish
pw import ~/backup/passwords.gpg
```

## Security

- All passwords are encrypted using GPG with your personal key
- Passwords are never stored in plain text on disk
- When copying to clipboard, passwords are not displayed on screen
- All sensitive operations require GPG decryption

## Storage

Passwords are stored in:
`$XDG_CONFIG_HOME/fish/secure/passwords/registry.json.gpg`

## Importing from Pass

When importing from the standard pass utility using `pw import-pass`, the following fields are detected and imported:

- The first line is used as the password
- Lines matching `username:`, `user:`, `login:`, or `email:` are imported as username
- Lines matching `url:`, `website:`, `site:`, or `link:` are imported as URL
- Lines matching `description:`, `desc:`, `notes:`, or `note:` are imported as description

Example of a pass entry that works well with import:

```
MySecretPassword
username: user@example.com
url: https://example.com
description: This is my account
```

## Implementation

This password store is built on the same security model as the existing file encryption and secrets system, providing a secure and consistent approach to sensitive data management.
