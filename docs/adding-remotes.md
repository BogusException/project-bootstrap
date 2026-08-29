# Adding Git Remotes

## 1. Overview

`mkproj` sets up a local git repo only. Remotes let you back up, share, or push to a server. You can add them any time after bootstrap -- they are not required to start coding.

This doc covers three options:

- **Option A** -- a local bare repo on the same machine or a NAS (fast, no internet required)
- **Option B** -- GitHub (public or private, accessible from anywhere)
- **Option C** -- SourceForge or any other git host

You can also combine options (push to two destinations at once -- see section 5).

---

## 2. Option A -- Local bare repo (backup on the same machine or NAS)

### 2.1 What it is

A "bare" repo is a git repository with no working tree -- just the history. It acts as a local server you push to and pull from. Useful for backups on the same machine or a network drive, with no internet dependency.

### 2.2 Create the bare repo

```bash
mkdir -p ~/Repositories
git init --bare ~/Repositories/myproject.git
```

Replace `myproject` with your actual project name.

### 2.3 Add it as a remote

Run this from inside your project directory:

```bash
git remote add origin ~/Repositories/myproject.git
git push -u origin main
```

`-u` sets the upstream so future `git push` and `git pull` commands need no arguments.

### 2.4 Verify

```bash
git remote -v
```

You should see two lines showing `origin` with the path to your bare repo (one for fetch, one for push).

---

## 3. Option B -- GitHub

### 3.1 Create a GitHub account (if needed)

Sign up at https://github.com/join. If you already have an account, skip this step.

### 3.2 Generate an SSH key

SSH keys let you push without entering a password every time. If you already have a key at `~/.ssh/id_ed25519`, skip to the next step.

```bash
ssh-keygen -t ed25519 -C "your-email@example.com"
```

Press Enter to accept the default file location. Set a passphrase if you want extra security (recommended), or press Enter twice for none.

Then print your public key:

```bash
cat ~/.ssh/id_ed25519.pub
```

Copy the entire output. Go to GitHub > Settings > SSH and GPG keys > New SSH key, paste it in, and save.

### 3.3 Test the connection

```bash
ssh -T git@github.com
```

You should see: `Hi USERNAME! You've successfully authenticated...`

If you see `Permission denied (publickey)`, the key was not added correctly -- repeat section 3.2.

### 3.4 Create a repository on GitHub

1. Go to https://github.com and click the `+` icon in the top right, then "New repository"
2. Name it to match your project (e.g. `myproject`)
3. Leave it empty -- do **not** tick "Add a README file" or any other option. Adding files there would conflict with your local history.
4. Click "Create repository"

GitHub will show you a page with remote setup commands. Ignore those -- use the commands in section 3.5 instead.

### 3.5 Add the remote

Run this from inside your project directory, replacing `USERNAME` and `PROJECTNAME`:

```bash
git remote add origin git@github.com:USERNAME/PROJECTNAME.git
git push -u origin main
```

### 3.6 Verify

```bash
git remote -v
```

You should see two lines pointing to `git@github.com:USERNAME/PROJECTNAME.git`.

---

## 4. Option C -- SourceForge or other git host

### 4.1 General pattern

Every git host gives you a remote URL when you create a repository. It will be either an SSH URL (`git@...`) or an HTTPS URL (`https://...`). SSH is preferred -- it avoids password prompts.

```bash
git remote add origin <remote-url>
git push -u origin main
```

Replace `<remote-url>` with the SSH or HTTPS URL from your host's repository creation page.

For SSH-based hosts, you will need to add your public key (`~/.ssh/id_ed25519.pub`) to that host's settings, the same way you did for GitHub in section 3.2.

---

## 5. Pushing to two remotes simultaneously (local + GitHub)

### 5.1 How it works

Git supports multiple push URLs on a single remote. One `git push` sends to both destinations. This is handy if you want a local bare-repo backup and a GitHub copy with a single command.

### 5.2 Setup

If you already have `origin` pointing to one destination, add the second as an extra push URL. You need to add **both** URLs -- git replaces the default push URL when you run `set-url --add --push`.

```bash
# Add both push URLs (replace paths/usernames as appropriate):
git remote set-url --add --push origin ~/Repositories/myproject.git
git remote set-url --add --push origin git@github.com:USERNAME/myproject.git

# Confirm the configuration:
git remote -v
```

You should see one fetch line and two push lines for `origin`.

### 5.3 Verify

```bash
git push
```

The output will show two sets of push results -- one for each destination.

---

## 6. Checking your current remote configuration

At any time, you can see what remotes are configured:

```bash
git remote -v
```

To see full details for a specific remote:

```bash
git remote show origin
```

---

## 7. Troubleshooting

### 7.1 Permission denied (publickey)

Your SSH key has not been added to the host. Work through sections 3.2 and 3.3 again and confirm the key appears in the host's SSH key settings page. Make sure you copied the `.pub` file (public key), not the private key.

### 7.2 Repository not found

Check the remote URL is correct:

```bash
git remote -v
```

For GitHub: confirm the repository exists (visit the URL in a browser), is not private without your access, and that the username and repo name in the URL match exactly (case-sensitive).

To fix a wrong URL:

```bash
git remote set-url origin <correct-url>
```

### 7.3 Updates were rejected (fetch first)

The remote has commits you do not have locally -- this happens if GitHub initialized the repo with a file, or if you pushed from another machine. Pull and rebase first:

```bash
git pull --rebase origin main
```

Then push again.
