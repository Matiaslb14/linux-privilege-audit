# Linux Privilege Audit — SUID/SGID & Capabilities Scanner

This project provides a **Linux privilege escalation audit tool** written in Bash.  
It scans for **SUID/SGID binaries**, **file capabilities**, and detects **risky `$PATH` settings**, generating a structured report.

## 🚀 Features
- Scan and list **SUID** binaries (`-4000`) with owner, group, permissions, and SHA256 hash.
- Scan and list **SGID** binaries (`-2000`) with full metadata.
- Enumerate **file capabilities** (`getcap -r /`).
- Detect risky `$PATH` settings:
  - `.` (dot) included in PATH.
  - **World-writable** directories in PATH.
- Output:
  - `REPORT.md` → summary + host info.
  - `suid_files.csv`, `sgid_files.csv`, `capabilities.csv`, `path_risks.csv`.

## 🛠️ Usage

git clone https://github.com/Matiaslb14/linux-privilege-audit.git
cd linux-privilege-audit
chmod +x priv_audit.sh

# Run with default output name (timestamped)
sudo ./priv_audit.sh

# Or specify a custom output folder
sudo ./priv_audit.sh report_mati

📂 Example Output

example-output/
 ├── REPORT.md
 ├── suid_files.csv
 ├── sgid_files.csv
 ├── capabilities.csv
 └── path_risks.csv

🔍 Sample SUID scan (CSV preview)

path                    owner  group   perm        sha256
/usr/bin/chfn           root   root    -rwsr-xr-x  2371665d023ae96aadcd86c8b2000200e23adf441ae02
/usr/bin/chsh           root   root    -rwsr-xr-x  cbe6de7973fadde66cd19f5da00640eafdfb8a70e83bee
/usr/bin/fusermount3    root   root    -rwsr-xr-x  c4a018496c54c929eae9d032bf2cccf72c7a0cb72e13
...

🔒 Security Recommendations

Review unexpected SUID/SGID binaries and remove the bit if unnecessary:

chmod u-s <file> (remove SUID)

chmod g-s <file> (remove SGID)

Drop unused capabilities:

setcap -r <file>

Harden PATH:

Avoid including . (dot).

Remove or secure world-writable directories in PATH.

Monitor changes:

Schedule this script in cron or systemd to detect deviations.

📜 Disclaimer

This tool is intended for educational and defensive security purposes.
Do not run it on systems without proper authorization.

✍️ Author: Matías Lagos (Mati)
