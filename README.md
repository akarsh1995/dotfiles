## About

This repository contains my configuration files for setting up a local environment using dotfiles.

## Usage

To bootstrap the dotfiles, run the following command:

```bash
curl -sS "https://raw.githubusercontent.com/akarsh1995/dotfiles/main/bootstrap-config.sh" | bash
```

This will:

1. Backup your existing `.config` directory (if it exists).
2. Clone the dotfiles repository into your `.config` directory.
3. Run the bootstrap script to set up the configuration.

