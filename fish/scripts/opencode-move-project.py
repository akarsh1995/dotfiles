#!/usr/bin/env python3
"""Update opencode's session database after renaming/moving a project directory.

Usage:
  python move-project.py /old/path /new/path
  python move-project.py --dry-run /old/path /new/path
"""

import argparse
import os
import sqlite3
import sys
from pathlib import Path

DB_PATH = os.path.expanduser("~/.local/share/opencode/opencode.db")


def tables_with_column(cursor, column):
    cursor.execute(
        "SELECT name FROM pragma_table_info(name) WHERE name = ? ORDER BY name",
        (column,),
    )
    return [row[0] for row in cursor.fetchall()]


def main():
    parser = argparse.ArgumentParser(
        description="Remap opencode session paths after a project directory rename"
    )
    parser.add_argument("old_dir", type=str, help="Old directory path")
    parser.add_argument("new_dir", type=str, help="New directory path")
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would change without modifying the database",
    )
    args = parser.parse_args()

    old_dir = os.path.abspath(args.old_dir)
    new_dir = os.path.abspath(args.new_dir)
    old_rel = old_dir.lstrip("/")
    new_rel = new_dir.lstrip("/")

    if old_dir == new_dir:
        print("old_dir and new_dir are the same — nothing to do.")
        sys.exit(0)

    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()

    # Check if DB is accessible
    try:
        cursor.execute("SELECT COUNT(*) FROM session")
    except sqlite3.Error as e:
        print(f"Error accessing database at {DB_PATH}: {e}", file=sys.stderr)
        sys.exit(1)

    updates = []

    # 1. session.directory (absolute path)
    cursor.execute(
        "SELECT id, directory, title FROM session WHERE directory = ? OR directory LIKE ?",
        (old_dir, f"{old_dir}/%"),
    )
    for row in cursor.fetchall():
        new_val = row["directory"].replace(old_dir, new_dir, 1)
        updates.append(("session", "directory", row["id"], row["directory"], new_val))

    # 2. session.path (relative path, no leading /)
    cursor.execute(
        "SELECT id, path, title FROM session WHERE path = ? OR path LIKE ?",
        (old_rel, f"{old_rel}/%"),
    )
    for row in cursor.fetchall():
        new_val = row["path"].replace(old_rel, new_rel, 1)
        updates.append(("session", "path", row["id"], row["path"], new_val))

    # 3. project.worktree
    cursor.execute(
        "SELECT id, worktree FROM project WHERE worktree = ? OR worktree LIKE ?",
        (old_dir, f"{old_dir}/%"),
    )
    for row in cursor.fetchall():
        new_val = row["worktree"].replace(old_dir, new_dir, 1)
        updates.append(("project", "worktree", row["id"], row["worktree"], new_val))

    # 4. project_directory.directory
    cursor.execute(
        "SELECT project_id, directory FROM project_directory WHERE directory = ? OR directory LIKE ?",
        (old_dir, f"{old_dir}/%"),
    )
    for row in cursor.fetchall():
        new_val = row["directory"].replace(old_dir, new_dir, 1)
        updates.append(
            ("project_directory", "directory", row["project_id"], row["directory"], new_val)
        )

    # 5. workspace.directory
    cursor.execute(
        "SELECT id, directory FROM workspace WHERE directory = ? OR directory LIKE ?",
        (old_dir, f"{old_dir}/%"),
    )
    for row in cursor.fetchall():
        new_val = row["directory"].replace(old_dir, new_dir, 1)
        updates.append(("workspace", "directory", row["id"], row["directory"], new_val))

    if not updates:
        print("No records found referencing the old path.")
        conn.close()
        return

    print(f"Found {len(updates)} record(s) referencing old path:\n")

    for table, col, pk, old_val, new_val in updates:
        label = f"{table}.{col}"
        print(f"  {label:45s}  {old_val}")
        print(f"  {'':45s}  -> {new_val}")
        print()

    if args.dry_run:
        print("[DRY-RUN] No changes made.")
        conn.close()
        return
    else:
        confirm = input("Apply these changes? [y/N] ").strip().lower()
        if confirm != "y":
            print("Aborted.")
            conn.close()
            return

    conn.execute("BEGIN TRANSACTION")
    try:
        for table, col, pk, old_val, new_val in updates:
            if table == "session":
                cursor.execute(
                    f"UPDATE session SET {col} = ? WHERE id = ?", (new_val, pk)
                )
            elif table == "project":
                cursor.execute(
                    f"UPDATE project SET {col} = ? WHERE id = ?", (new_val, pk)
                )
            elif table == "project_directory":
                cursor.execute(
                    f"UPDATE project_directory SET {col} = ? WHERE project_id = ? AND {col} = ?",
                    (new_val, pk, old_val),
                )
            elif table == "workspace":
                cursor.execute(
                    f"UPDATE workspace SET {col} = ? WHERE id = ?", (new_val, pk)
                )
        conn.commit()
        print(f"Successfully updated {len(updates)} record(s).")
        print("Restart opencode for changes to take effect.")
    except sqlite3.Error as e:
        conn.rollback()
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
