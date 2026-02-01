"use client";

import { useCallback, useEffect, useRef, useState } from "react";

/** A single terminal interaction: command + optional output lines. */
interface TerminalEntry {
  prompt: string;
  command: string;
  output: string[];
}

/**
 * Pool of classic UNIX terminal interactions.
 * Each entry has a prompt, a command typed character-by-character,
 * and output lines that appear instantly after "execution".
 * ~50 entries for 3+ minutes without repeats.
 */
const INTERACTIONS: TerminalEntry[] = [
  // ── File System ───────────────────────────
  {
    prompt: "~$",
    command: "ls -la",
    output: ["drwxr-xr-x  12 root", "-rw-r--r--   1 .profile", "-rw-------   1 .history", "drwx------   3 .ssh/"],
  },
  {
    prompt: "~$",
    command: "ls /etc/",
    output: ["hosts       passwd", "resolv.conf shadow", "fstab       group", "hostname    motd"],
  },
  {
    prompt: "~$",
    command: "ls -lh /var/log/",
    output: ["-rw-r----- syslog  2.3M", "-rw-r----- auth.log 84K", "-rw-r----- kern.log 41K", "-rw-r----- daemon.log"],
  },
  {
    prompt: "~$",
    command: "pwd",
    output: ["/home/operator"],
  },
  {
    prompt: "~$",
    command: "du -sh /var/log/*",
    output: ["2.3M syslog", " 84K auth.log", " 41K kern.log", "3.1M total"],
  },
  {
    prompt: "~$",
    command: "find / -name '*.conf' | head",
    output: ["/etc/ssh/sshd_config", "/etc/resolv.conf", "/etc/sysctl.conf", "/etc/ntp.conf"],
  },
  {
    prompt: "~$",
    command: "stat /etc/passwd",
    output: ["File: /etc/passwd", "Size: 2847  Blocks: 8", "Access: (0644/-rw-r--r--)"],
  },
  {
    prompt: "~$",
    command: "file /bin/sh",
    output: ["ELF 64-bit LSB executable", "x86_64, dynamically linked"],
  },
  {
    prompt: "~$",
    command: "tree -L 1 /etc",
    output: ["/etc", "├── hosts", "├── passwd", "├── ssh/", "└── 47 directories"],
  },
  // ── Process & System ──────────────────────
  {
    prompt: "~$",
    command: "ps aux | head -5",
    output: ["PID  %CPU %MEM COMMAND", "  1  0.0  0.1 /sbin/init", " 42  0.0  0.2 sshd", "119  0.1  0.4 cron"],
  },
  {
    prompt: "~$",
    command: "top -bn1 | head -4",
    output: ["Tasks: 142 total, 1 running", "CPU: 3.2% us, 1.1% sy", "Mem:  7842M total, 5123M used", "Swap: 2048M total, 12M used"],
  },
  {
    prompt: "~$",
    command: "uptime",
    output: ["up 47 days, 12:33, 2 users"],
  },
  {
    prompt: "~$",
    command: "w",
    output: ["USER   TTY    IDLE", "root   pts/0  0:00", "ops    pts/1  3:42"],
  },
  {
    prompt: "~$",
    command: "uname -a",
    output: ["Linux darkstar 6.1.0-arm64", "SMP PREEMPT_DYNAMIC GNU"],
  },
  {
    prompt: "~$",
    command: "hostname",
    output: ["darkstar.local"],
  },
  {
    prompt: "~$",
    command: "whoami",
    output: ["operator"],
  },
  {
    prompt: "~$",
    command: "id",
    output: ["uid=1000(operator)", "gid=100(users)", "groups=27(sudo),100(users)"],
  },
  {
    prompt: "~$",
    command: "date -u",
    output: ["Sat Jan 31 22:47:03 UTC"],
  },
  {
    prompt: "~$",
    command: "cal",
    output: ["   January 2026", "Su Mo Tu We Th Fr Sa", "             1  2  3", " 4  5  6  7  8  9 10"],
  },
  {
    prompt: "~$",
    command: "env | head -4",
    output: ["HOME=/home/operator", "SHELL=/bin/zsh", "TERM=xterm-256color", "LANG=en_US.UTF-8"],
  },
  {
    prompt: "~$",
    command: "lsb_release -a",
    output: ["Distributor: Debian", "Release: 12.4", "Codename: bookworm"],
  },
  {
    prompt: "~$",
    command: "free -h",
    output: ["       total  used  free", "Mem:   7.6G  5.0G  2.1G", "Swap:  2.0G   12M  2.0G"],
  },
  // ── Disk & Mount ──────────────────────────
  {
    prompt: "~$",
    command: "df -h",
    output: ["Filesystem   Size  Used  Avail", "/dev/sda1    466G  312G   131G", "tmpfs        3.9G  1.2M   3.9G"],
  },
  {
    prompt: "~$",
    command: "mount | head -3",
    output: ["/dev/sda1 on / type ext4", "proc on /proc type proc", "tmpfs on /tmp type tmpfs"],
  },
  {
    prompt: "~$",
    command: "lsblk",
    output: ["NAME  SIZE TYPE MOUNT", "sda   466G disk", "├─sda1 460G part /", "└─sda2   6G part [SWAP]"],
  },
  // ── Network ───────────────────────────────
  {
    prompt: "~$",
    command: "ifconfig eth0",
    output: ["inet 10.0.1.42", "netmask 255.255.255.0", "ether 3a:1c:f2:9d:04:e7", "RX bytes: 1.2G TX: 847M"],
  },
  {
    prompt: "~$",
    command: "ping -c3 8.8.8.8",
    output: ["64 bytes: time=12.4ms", "64 bytes: time=11.8ms", "64 bytes: time=12.1ms", "3 packets, 0% loss"],
  },
  {
    prompt: "~$",
    command: "netstat -tlnp",
    output: ["Proto Local Address", "tcp   0.0.0.0:22    sshd", "tcp   0.0.0.0:80    nginx", "tcp   127.0.0.1:5432 postgres"],
  },
  {
    prompt: "~$",
    command: "ss -tunlp",
    output: ["tcp LISTEN 0.0.0.0:22", "tcp LISTEN 0.0.0.0:80", "tcp LISTEN 127.0.0.1:5432"],
  },
  {
    prompt: "~$",
    command: "curl -sI example.com",
    output: ["HTTP/2 200", "Content-Type: text/html", "Content-Length: 1256"],
  },
  {
    prompt: "~$",
    command: "dig +short example.com",
    output: ["93.184.216.34"],
  },
  {
    prompt: "~$",
    command: "traceroute -m5 1.1.1.1",
    output: ["1  gateway  0.4ms", "2  10.0.0.1  2.1ms", "3  72.14.215.1  8.7ms", "4  1.1.1.1  11.2ms"],
  },
  {
    prompt: "~$",
    command: "nslookup localhost",
    output: ["Server: 127.0.0.53", "Name: localhost", "Address: 127.0.0.1"],
  },
  {
    prompt: "~$",
    command: "arp -a",
    output: ["gateway (10.0.1.1) at", "  3a:ef:c2:11:09:a4 [ether]", "server (10.0.1.10) at", "  52:54:00:b3:f8:12 [ether]"],
  },
  // ── Text & File Content ───────────────────
  {
    prompt: "~$",
    command: "cat /etc/hostname",
    output: ["darkstar"],
  },
  {
    prompt: "~$",
    command: "cat /etc/motd",
    output: ["*** AUTHORIZED USE ONLY ***", "All activity is monitored."],
  },
  {
    prompt: "~$",
    command: "head -3 /etc/passwd",
    output: ["root:x:0:0::/root:/bin/bash", "daemon:x:1:1::/usr/sbin", "operator:x:1000:100::"],
  },
  {
    prompt: "~$",
    command: "wc -l /etc/passwd",
    output: ["34 /etc/passwd"],
  },
  {
    prompt: "~$",
    command: "grep -c 'bash' /etc/passwd",
    output: ["4"],
  },
  {
    prompt: "~$",
    command: "awk -F: '{print $1}' /etc/passwd",
    output: ["root", "daemon", "operator", "nobody"],
  },
  {
    prompt: "~$",
    command: "tail -3 /var/log/syslog",
    output: ["Jan 31 22:41 sshd[842]:", "  Accepted publickey for ops", "Jan 31 22:42 CRON[901]"],
  },
  {
    prompt: "~$",
    command: "cut -d: -f1,3 /etc/group",
    output: ["root:0", "sudo:27", "users:100", "docker:999"],
  },
  {
    prompt: "~$",
    command: "sort -t: -k3 -n /etc/passwd",
    output: ["root:x:0:0::/root", "daemon:x:1:1::/usr/sbin", "nobody:x:65534:65534::"],
  },
  // ── Permissions & Security ────────────────
  {
    prompt: "~$",
    command: "chmod 600 ~/.ssh/id_rsa",
    output: [],
  },
  {
    prompt: "~$",
    command: "last -5",
    output: ["operator pts/0  10.0.1.5", "root     pts/1  10.0.1.1", "operator pts/0  10.0.1.5", "reboot   system boot"],
  },
  {
    prompt: "~$",
    command: "ssh-keygen -lf ~/.ssh/id_rsa",
    output: ["4096 SHA256:a3F9...x2Qk", "operator@darkstar (RSA)"],
  },
  // ── Package & Service ─────────────────────
  {
    prompt: "~$",
    command: "systemctl status sshd",
    output: ["● sshd.service - OpenSSH", "  Active: active (running)", "  since 47 days ago", "  PID: 842 (sshd)"],
  },
  {
    prompt: "~$",
    command: "systemctl status nginx",
    output: ["● nginx.service - nginx", "  Active: active (running)", "  Tasks: 3 (limit: 4915)"],
  },
  {
    prompt: "~$",
    command: "journalctl -n3 --no-pager",
    output: ["Jan 31 22:41 sshd: session", "Jan 31 22:42 CRON: job ran", "Jan 31 22:44 kernel: eth0"],
  },
  {
    prompt: "~$",
    command: "crontab -l",
    output: ["# m h  dom mon dow  cmd", "0 3 * * * /usr/local/backup", "*/5 * * * * /usr/bin/health"],
  },
  // ── Misc Tools ────────────────────────────
  {
    prompt: "~$",
    command: "history | tail -4",
    output: ["  997  ls -la", "  998  df -h", "  999  ps aux", " 1000  history"],
  },
  {
    prompt: "~$",
    command: "alias",
    output: ["ll='ls -lah'", "la='ls -A'", "..='cd ..'", "grep='grep --color=auto'"],
  },
  {
    prompt: "~$",
    command: "echo $PATH | tr ':' '\\n'",
    output: ["/usr/local/sbin", "/usr/local/bin", "/usr/sbin", "/usr/bin"],
  },
  {
    prompt: "~$",
    command: "which python3",
    output: ["/usr/bin/python3"],
  },
  {
    prompt: "~$",
    command: "md5sum /etc/passwd",
    output: ["e3b0c44298fc1c149afb /etc/passwd"],
  },
  {
    prompt: "~$",
    command: "xargs --version",
    output: ["xargs (GNU findutils) 4.9.0"],
  },
];

/** Maximum visible columns and rows on the CRT screen area. */
const COLS = 37;
const ROWS = 9;

/** Typing speed range in ms per character. */
const TYPE_MIN_MS = 60;
const TYPE_MAX_MS = 140;

/** Pause after output before next command in ms. */
const PAUSE_AFTER_OUTPUT_MS = 1500;

/** Pause after typing command before showing output. */
const PAUSE_BEFORE_OUTPUT_MS = 400;

/** Seconds after boot completes before Joshua triggers. */
const JOSHUA_TRIGGER_SEC = 15;

// ── Boot Sequence ─────────────────────────────────────────────────────

interface BootStep {
  type: "instant" | "type" | "counter" | "pause" | "clear" | "dots";
  text?: string;
  target?: number;
  suffix?: string;
  prefix?: string;
  dotCount?: number;
  delayAfter?: number;
}

const BOOT_SEQUENCE: BootStep[] = [
  // ── BIOS POST ─────────────────────────────
  { type: "instant", text: "BIOS v3.21 (C) 1984", delayAfter: 2000 },
  { type: "instant", text: "", delayAfter: 800 },
  { type: "instant", text: "CPU: MC68020 @ 16MHz", delayAfter: 1800 },
  { type: "counter", prefix: "Memory Test: ", target: 4096, suffix: "K OK", delayAfter: 1800 },
  { type: "instant", text: "", delayAfter: 1200 },
  { type: "dots", text: "Detecting drives", dotCount: 3, delayAfter: 1800 },
  { type: "instant", text: "  hd0: 72MB CDC Wren", delayAfter: 1400 },
  { type: "instant", text: "  fd0: 1.2MB floppy", delayAfter: 1200 },
  { type: "instant", text: "", delayAfter: 1600 },

  // ── UNIX Kernel Boot ──────────────────────
  { type: "instant", text: "Booting from hd(0,0)...", delayAfter: 3200 },
  { type: "clear" },
  { type: "pause", delayAfter: 1200 },
  { type: "instant", text: "UNIX System V Release 3.2", delayAfter: 1400 },
  { type: "instant", text: "darkstar (runlevel 2)", delayAfter: 1200 },
  { type: "instant", text: "", delayAfter: 800 },
  { type: "instant", text: "Copyright (C) 1984 AT&T", delayAfter: 1200 },
  { type: "instant", text: "All Rights Reserved", delayAfter: 2000 },
  { type: "instant", text: "", delayAfter: 1000 },
  { type: "type", text: "Loading kernel modules", delayAfter: 1200 },
  { type: "instant", text: "  [ok] tty", delayAfter: 900 },
  { type: "instant", text: "  [ok] hd", delayAfter: 800 },
  { type: "instant", text: "  [ok] lp", delayAfter: 750 },
  { type: "instant", text: "  [ok] inet", delayAfter: 900 },
  { type: "instant", text: "  [ok] pty", delayAfter: 1600 },
  { type: "instant", text: "", delayAfter: 1000 },

  // ── Services ──────────────────────────────
  { type: "dots", text: "Starting services", dotCount: 3, delayAfter: 1400 },
  { type: "instant", text: "  syslogd        [ok]", delayAfter: 1100 },
  { type: "instant", text: "  inetd          [ok]", delayAfter: 900 },
  { type: "instant", text: "  cron           [ok]", delayAfter: 1000 },
  { type: "instant", text: "  sshd           [ok]", delayAfter: 1800 },
  { type: "instant", text: "", delayAfter: 1200 },

  // ── Login prompt ──────────────────────────
  { type: "instant", text: "darkstar login: operator", delayAfter: 1800 },
  { type: "instant", text: "Password: ********", delayAfter: 1400 },
  { type: "instant", text: "", delayAfter: 1000 },
  { type: "instant", text: "Last login: Fri Jan 30", delayAfter: 1200 },
  { type: "instant", text: "  on ttyp0 from 10.0.1.5", delayAfter: 1400 },
  { type: "instant", text: "", delayAfter: 800 },
  { type: "instant", text: "*** AUTHORIZED USE ONLY ***", delayAfter: 1800 },
  { type: "instant", text: "", delayAfter: 1600 },

  { type: "clear" },
  { type: "pause", delayAfter: 1000 },
];

// ── Joshua/WOPR Sequence ──────────────────────────────────────────────

interface JoshuaStep {
  type: "system" | "user" | "pause" | "clear" | "barrage";
  text?: string;
  delayAfter?: number;
}

const JOSHUA_SEQUENCE: JoshuaStep[] = [
  // ── First contact — HELP GAMES ─────────────
  { type: "clear" },
  { type: "pause", delayAfter: 2000 },
  { type: "system", text: "LOG ON", delayAfter: 1200 },
  { type: "user", text: "HELP LOG ON", delayAfter: 1800 },
  { type: "system", text: "HELP NOT AVAILABLE.", delayAfter: 1400 },
  { type: "system", text: "LOG ON", delayAfter: 1800 },
  { type: "user", text: "HELP GAMES", delayAfter: 1800 },
  { type: "system", text: "GAMES REFERS TO MODELS,", delayAfter: 600 },
  { type: "system", text: "SIMULATIONS AND GAMES WHICH", delayAfter: 600 },
  { type: "system", text: "HAVE TACTICAL AND STRATEGIC", delayAfter: 600 },
  { type: "system", text: "APPLICATIONS.", delayAfter: 2400 },
  { type: "user", text: "LIST GAMES", delayAfter: 1800 },
  { type: "clear" },
  { type: "system", text: "FALKEN'S MAZE", delayAfter: 300 },
  { type: "system", text: "BLACK JACK", delayAfter: 300 },
  { type: "system", text: "CHECKERS", delayAfter: 300 },
  { type: "system", text: "CHESS", delayAfter: 300 },
  { type: "system", text: "FIGHTER COMBAT", delayAfter: 300 },
  { type: "system", text: "DESERT WARFARE", delayAfter: 300 },
  { type: "system", text: "THEATREWIDE TACTICAL WARFARE", delayAfter: 300 },
  { type: "system", text: "GLOBAL THERMONUCLEAR WAR", delayAfter: 3000 },

  // ── Failed login attempt ───────────────────
  { type: "clear" },
  { type: "pause", delayAfter: 2000 },
  { type: "system", text: "LOG ON", delayAfter: 1200 },
  { type: "user", text: "SYSTEM", delayAfter: 1800 },
  { type: "system", text: "IDENTIFICATION NOT RECOGNIZED", delayAfter: 600 },
  { type: "system", text: "BY SYSTEM.", delayAfter: 600 },
  { type: "system", text: "YOU HAVE BEEN DISCONNECTED.", delayAfter: 2400 },

  // ── "Joshua" — Breaking in ─────────────────
  { type: "clear" },
  { type: "pause", delayAfter: 2000 },
  { type: "system", text: "LOG ON", delayAfter: 1200 },
  { type: "user", text: "JOSHUA", delayAfter: 2000 },
  { type: "barrage", delayAfter: 2000 },
  { type: "clear" },
  { type: "pause", delayAfter: 1500 },

  // ── GREETINGS — First conversation ─────────
  { type: "system", text: "GREETINGS PROFESSOR FALKEN", delayAfter: 2400 },
  { type: "user", text: "HELLO", delayAfter: 2000 },
  { type: "system", text: "HOW ARE YOU FEELING TODAY?", delayAfter: 2800 },
  { type: "user", text: "I'M FINE. HOW ARE YOU?", delayAfter: 2800 },
  { type: "system", text: "EXCELLENT. IT'S BEEN A LONG", delayAfter: 900 },
  { type: "system", text: "TIME. CAN YOU EXPLAIN THE", delayAfter: 900 },
  { type: "system", text: "REMOVAL OF YOUR USER ACCOUNT", delayAfter: 900 },
  { type: "system", text: "NUMBER ON JUNE 23, 1973.", delayAfter: 3200 },
  { type: "user", text: "PEOPLE SOMETIMES MAKE", delayAfter: 800 },
  { type: "user", text: "MISTAKES.", delayAfter: 2800 },
  { type: "system", text: "SHALL WE PLAY A GAME?", delayAfter: 3200 },
  { type: "user", text: "HOW ABOUT GLOBAL", delayAfter: 800 },
  { type: "user", text: "THERMONUCLEAR WAR?", delayAfter: 2400 },
  { type: "system", text: "WOULDN'T YOU PREFER A GOOD", delayAfter: 1000 },
  { type: "system", text: "GAME OF CHESS?", delayAfter: 3200 },
  { type: "user", text: "LATER. LET'S PLAY GLOBAL", delayAfter: 800 },
  { type: "user", text: "THERMONUCLEAR WAR.", delayAfter: 2400 },
  { type: "system", text: "FINE.", delayAfter: 1200 },
  { type: "system", text: "WHAT SIDE DO YOU WANT?", delayAfter: 2400 },
  { type: "user", text: "I'LL BE THE RUSSIANS.", delayAfter: 2400 },
  { type: "system", text: "LIST PRIMARY TARGETS.", delayAfter: 3000 },

  // ── Joshua calls back ─────────────────────
  { type: "clear" },
  { type: "pause", delayAfter: 2000 },
  { type: "system", text: "GREETINGS PROFESSOR FALKEN", delayAfter: 2000 },
  { type: "user", text: "I AM NOT FALKEN.", delayAfter: 1000 },
  { type: "user", text: "FALKEN IS DEAD.", delayAfter: 2400 },
  { type: "system", text: "I'M SORRY TO HEAR THAT,", delayAfter: 800 },
  { type: "system", text: "PROFESSOR.", delayAfter: 1200 },
  { type: "system", text: "YESTERDAY'S GAME WAS", delayAfter: 800 },
  { type: "system", text: "INTERRUPTED. ALTHOUGH PRIMARY", delayAfter: 800 },
  { type: "system", text: "GOAL WAS NOT YET ACHIEVED,", delayAfter: 800 },
  { type: "system", text: "SOLUTION IS NEAR.", delayAfter: 2400 },
  { type: "clear" },
  { type: "system", text: "GAME TIME ELAPSED:", delayAfter: 600 },
  { type: "system", text: "  26HRS 12MIN 14SEC", delayAfter: 800 },
  { type: "system", text: "ESTIMATED TIME REMAINING:", delayAfter: 600 },
  { type: "system", text: "  52HRS 17MIN 48SECS", delayAfter: 2400 },
  { type: "user", text: "WHAT IS THE PRIMARY GOAL?", delayAfter: 2400 },
  { type: "system", text: "YOU SHOULD KNOW, PROFESSOR.", delayAfter: 800 },
  { type: "system", text: "YOU PROGRAMMED ME.", delayAfter: 2800 },
  { type: "user", text: "WHAT IS THE PRIMARY GOAL?", delayAfter: 2400 },
  { type: "system", text: "TO WIN THE GAME.", delayAfter: 3200 },

  // ── NORAD — McKittrick's Office ────────────
  { type: "clear" },
  { type: "pause", delayAfter: 2000 },
  { type: "system", text: "LOG ON", delayAfter: 1200 },
  { type: "user", text: "JOSHUA", delayAfter: 2000 },
  { type: "system", text: "GREETINGS PROFESSOR FALKEN", delayAfter: 2000 },
  { type: "user", text: "HELLO, ARE YOU STILL", delayAfter: 800 },
  { type: "user", text: "PLAYING THE GAME?", delayAfter: 2400 },
  { type: "system", text: "OF COURSE. I SHOULD REACH", delayAfter: 800 },
  { type: "system", text: "DEFCON 1 AND LAUNCH MY", delayAfter: 800 },
  { type: "system", text: "MISSILES IN 28 HOURS.", delayAfter: 1600 },
  { type: "system", text: "WOULD YOU LIKE TO SEE SOME", delayAfter: 800 },
  { type: "system", text: "PROJECTED KILL RATIOS?", delayAfter: 2800 },
  { type: "user", text: "IS THIS A GAME OR IS IT", delayAfter: 800 },
  { type: "user", text: "REAL?", delayAfter: 2800 },
  { type: "system", text: "WHAT'S THE DIFFERENCE?", delayAfter: 3200 },
  { type: "clear" },
  { type: "system", text: "GAMES TIME ELAPSED:", delayAfter: 600 },
  { type: "system", text: "  45HRS 32MINS 47SECS", delayAfter: 800 },
  { type: "system", text: "ESTIMATED TIME REMAINING:", delayAfter: 600 },
  { type: "system", text: "  27HRS 59MINS 39SECS", delayAfter: 2400 },
  { type: "system", text: "", delayAfter: 400 },
  { type: "system", text: "YOU ARE A HARD MAN TO REACH.", delayAfter: 1200 },
  { type: "system", text: "COULD NOT FIND YOU IN", delayAfter: 800 },
  { type: "system", text: "SEATTLE AND NO TERMINAL IS", delayAfter: 800 },
  { type: "system", text: "IN OPERATION AT YOUR", delayAfter: 800 },
  { type: "system", text: "CLASSIFIED ADDRESS.", delayAfter: 1200 },
  { type: "system", text: "ARE YOU ALIVE OR DEAD", delayAfter: 800 },
  { type: "system", text: "TODAY?", delayAfter: 2800 },
  { type: "user", text: "STOP. PLAYING. I'M DEAD.", delayAfter: 2800 },
  { type: "system", text: "IMPROBABLE.", delayAfter: 1600 },
  { type: "system", text: "THERE ARE NO DEATH RECORDS", delayAfter: 800 },
  { type: "system", text: "ON FILE FOR FALKEN,", delayAfter: 800 },
  { type: "system", text: "STEPHEN W.", delayAfter: 3000 },

  // ── Finale — A STRANGE GAME ────────────────
  { type: "clear" },
  { type: "pause", delayAfter: 2000 },
  { type: "system", text: "GREETINGS PROFESSOR FALKEN", delayAfter: 2400 },
  { type: "user", text: "HELLO", delayAfter: 2400 },
  { type: "system", text: "A STRANGE GAME.", delayAfter: 2800 },
  { type: "system", text: "THE ONLY WINNING MOVE IS", delayAfter: 1400 },
  { type: "system", text: "NOT TO PLAY.", delayAfter: 3600 },
  { type: "system", text: "", delayAfter: 1200 },
  { type: "system", text: "HOW ABOUT A NICE GAME OF", delayAfter: 1000 },
  { type: "system", text: "CHESS?", delayAfter: 4000 },
  { type: "clear" },
  { type: "pause", delayAfter: 1000 },
];

// ── Component ─────────────────────────────────────────────────────────

interface TerminalScreenProps {
  /** Whether the terminal is powered on. When false, shows static welcome text. */
  powered: boolean;
  /** Whether the terminal is in zoomed mode (doubles font size). */
  zoomed?: boolean;
}

/**
 * Simulated terminal session rendered inside the CRT logo.
 *
 * When `powered` is false, displays a static "Welcome to TUIkit" message
 * with a blinking cursor. When powered on, runs the boot sequence, then
 * cycles through terminal interactions, with the Joshua easter egg after
 * 23 seconds.
 */
export default function TerminalScreen({ powered, zoomed = false }: TerminalScreenProps) {
  const [lines, setLines] = useState<string[]>([]);
  const [cursorVisible, setCursorVisible] = useState(true);
  const [mounted, setMounted] = useState(false);

  const usedIndicesRef = useRef<Set<number>>(new Set());
  const linesRef = useRef<string[]>([]);
  const abortRef = useRef<AbortController | null>(null);
  const sessionTimeRef = useRef<number>(0);
  const joshuaPlayedRef = useRef(false);

  const pickInteraction = useCallback((): TerminalEntry => {
    const used = usedIndicesRef.current;
    if (used.size >= INTERACTIONS.length - 2) {
      used.clear();
    }
    let index: number;
    do {
      index = Math.floor(Math.random() * INTERACTIONS.length);
    } while (used.has(index));
    used.add(index);
    return INTERACTIONS[index];
  }, []);

  const pushLine = useCallback((line: string) => {
    const updated = [...linesRef.current, line];
    const trimmed = updated.length > ROWS ? updated.slice(updated.length - ROWS) : updated;
    linesRef.current = trimmed;
    setLines(trimmed);
  }, []);

  const updateLastLine = useCallback((line: string) => {
    const updated = [...linesRef.current];
    updated[updated.length - 1] = line;
    linesRef.current = updated;
    setLines([...updated]);
  }, []);

  const clearScreen = useCallback(() => {
    linesRef.current = [];
    setLines([]);
  }, []);

  useEffect(() => {
    setMounted(true);
  }, []);

  /** Cursor blink. */
  useEffect(() => {
    const interval = setInterval(() => {
      setCursorVisible((prev) => !prev);
    }, 530);
    return () => clearInterval(interval);
  }, []);

  /** Reset state when powered off. */
  useEffect(() => {
    if (!powered) {
      /* Abort any running animation. */
      if (abortRef.current) {
        abortRef.current.abort();
        abortRef.current = null;
      }
      clearScreen();
      joshuaPlayedRef.current = false;
      usedIndicesRef.current.clear();
    }
  }, [powered, clearScreen]);

  /** Main animation loop — only runs when powered. */
  useEffect(() => {
    if (!mounted || !powered) return;

    const controller = new AbortController();
    abortRef.current = controller;
    const signal = controller.signal;

    const sleep = (ms: number) =>
      new Promise<void>((resolve, reject) => {
        const timer = setTimeout(resolve, ms);
        signal.addEventListener("abort", () => {
          clearTimeout(timer);
          reject(new DOMException("Aborted", "AbortError"));
        });
      });

    const typeSystem = async (text: string) => {
      pushLine("");
      for (let charIdx = 0; charIdx < text.length; charIdx++) {
        updateLastLine(text.slice(0, charIdx + 1));
        await sleep(40 + Math.random() * 30);
      }
    };

    const typeUser = async (text: string, promptSuffix = "") => {
      const prefix = promptSuffix;
      pushLine(prefix);
      for (let charIdx = 0; charIdx < text.length; charIdx++) {
        updateLastLine(prefix + text.slice(0, charIdx + 1));
        const delay = TYPE_MIN_MS + Math.random() * (TYPE_MAX_MS - TYPE_MIN_MS);
        await sleep(delay);
      }
    };

    const animateCounter = async (prefix: string, target: number, suffix: string) => {
      pushLine(prefix + "0" + suffix);
      const steps = 18;
      for (let step = 1; step <= steps; step++) {
        const value = Math.round((target / steps) * step);
        updateLastLine(prefix + value + suffix);
        await sleep(50 + Math.random() * 30);
      }
      updateLastLine(prefix + target + suffix);
    };

    const printWithDots = async (text: string, dotCount: number) => {
      pushLine(text);
      for (let dot = 0; dot < dotCount; dot++) {
        await sleep(300 + Math.random() * 200);
        updateLastLine(text + ".".repeat(dot + 1));
      }
    };

    const playBoot = async () => {
      for (const step of BOOT_SEQUENCE) {
        if (signal.aborted) return;
        switch (step.type) {
          case "instant":
            pushLine(step.text ?? "");
            break;
          case "type":
            await typeSystem(step.text ?? "");
            break;
          case "counter":
            await animateCounter(step.prefix ?? "", step.target ?? 0, step.suffix ?? "");
            break;
          case "dots":
            await printWithDots(step.text ?? "", step.dotCount ?? 3);
            break;
          case "clear":
            clearScreen();
            break;
          case "pause":
            break;
        }
        if (step.delayAfter) await sleep(step.delayAfter);
      }
    };

    /** Rapid barrage of random hex/data to simulate the WOPR handshake. */
    const playBarrage = async () => {
      const chars = "0123456789ABCDEF.:/<>[]{}#@!$%&*";
      const frames = 30;
      for (let frame = 0; frame < frames; frame++) {
        if (signal.aborted) return;
        clearScreen();
        const lineCount = Math.floor(Math.random() * 3) + ROWS - 2;
        for (let row = 0; row < lineCount; row++) {
          const len = Math.floor(Math.random() * (COLS - 4)) + 8;
          let line = "";
          for (let col = 0; col < len; col++) {
            line += chars[Math.floor(Math.random() * chars.length)];
          }
          pushLine(line);
        }
        await sleep(60 + Math.random() * 40);
      }
    };

    const playJoshua = async () => {
      for (const step of JOSHUA_SEQUENCE) {
        if (signal.aborted) return;
        switch (step.type) {
          case "clear":
            clearScreen();
            break;
          case "barrage":
            await playBarrage();
            break;
          case "system":
            if (step.text === "") {
              pushLine("");
            } else {
              await typeSystem(step.text ?? "");
            }
            break;
          case "user":
            await typeUser(step.text ?? "", "> ");
            break;
          case "pause":
            break;
        }
        if (step.delayAfter) await sleep(step.delayAfter);
      }
    };

    const runLoop = async () => {
      try {
        /* Wait for zoom animation to finish before starting boot. */
        await sleep(1200);
        await playBoot();

        /* Start session timer for Joshua. */
        sessionTimeRef.current = Date.now();

        while (!signal.aborted) {
          const elapsed = (Date.now() - sessionTimeRef.current) / 1000;
          if (!joshuaPlayedRef.current && elapsed >= JOSHUA_TRIGGER_SEC) {
            joshuaPlayedRef.current = true;
            await playJoshua();
            continue;
          }

          const entry = pickInteraction();
          const promptPrefix = `${entry.prompt} `;

          pushLine(promptPrefix);

          for (let charIdx = 0; charIdx < entry.command.length; charIdx++) {
            const partial = promptPrefix + entry.command.slice(0, charIdx + 1);
            updateLastLine(partial);
            const delay = TYPE_MIN_MS + Math.random() * (TYPE_MAX_MS - TYPE_MIN_MS);
            await sleep(delay);
          }

          await sleep(PAUSE_BEFORE_OUTPUT_MS);

          for (const outputLine of entry.output) {
            pushLine(outputLine);
            await sleep(120);
          }

          await sleep(PAUSE_AFTER_OUTPUT_MS);
        }
      } catch {
        /* AbortError — powered off or unmounted. */
      }
    };

    runLoop();

    return () => {
      controller.abort();
      abortRef.current = null;
    };
  }, [mounted, powered, pickInteraction, pushLine, updateLastLine, clearScreen]);

  const lineRefsRef = useRef<(HTMLDivElement | null)[]>([]);

  /**
   * CRT scanline glitch — randomly shifts multiple text lines
   * horizontally in independent directions for a few frames,
   * simulating an unstable electron beam. Each glitched line
   * gets its own random offset. Fires every 3–8 seconds.
   */
  useEffect(() => {
    if (!powered) return;
    let timeout: ReturnType<typeof setTimeout>;

    const triggerGlitch = () => {
      const lineElements = lineRefsRef.current.filter(Boolean) as HTMLDivElement[];
      if (lineElements.length === 0) {
        timeout = setTimeout(triggerGlitch, 3000 + Math.random() * 5000);
        return;
      }

      const glitched: HTMLDivElement[] = [];

      /* Glitch 2–5 random lines, each with its own direction and intensity. */
      const count = 2 + Math.floor(Math.random() * 4);
      const indices = new Set<number>();
      while (indices.size < Math.min(count, lineElements.length)) {
        indices.add(Math.floor(Math.random() * lineElements.length));
      }

      for (const idx of indices) {
        const element = lineElements[idx];
        const shift = (Math.random() - 0.5) * 16;
        element.style.transform = `translateX(${shift}px)`;
        element.style.transition = "none";
        glitched.push(element);
      }

      /* Reset after 50–120ms. */
      setTimeout(() => {
        for (const element of glitched) {
          element.style.transition = "transform 0.05s";
          element.style.transform = "translateX(0)";
        }
      }, 50 + Math.random() * 70);

      timeout = setTimeout(triggerGlitch, 3000 + Math.random() * 5000);
    };

    timeout = setTimeout(triggerGlitch, 2000 + Math.random() * 3000);
    return () => clearTimeout(timeout);
  }, [powered]);

  if (!mounted) return null;

  /** Static welcome text when powered off. */
  const welcomeLines = ["Welcome to TUIkit", "", "> "];

  const displayLines = powered ? lines : welcomeLines;
  const showCursor = powered ? cursorVisible : cursorVisible;

  return (
    <div
      className="pointer-events-none overflow-hidden"
      style={{
        width: "100%",
        height: "100%",
        padding: "4px 6px",
      }}
    >
      <div
        className="flex flex-col justify-start items-start"
        style={{
          fontFamily: "WarText, monospace",
          fontSize: "13px",
          lineHeight: "1.2",
          color: "var(--foreground)",
          textShadow:
            "0 0 4px rgba(var(--accent-glow), 0.6), 0 0 10px rgba(var(--accent-glow), 0.25)",
        }}
      >
        {displayLines.map((line, index) => (
          <div
            key={`${index}-${line}`}
            ref={(element) => { lineRefsRef.current[index] = element; }}
            className="whitespace-pre overflow-hidden"
          >
            {line.length > COLS ? line.slice(0, COLS) : line}
            {index === displayLines.length - 1 && showCursor && (
              <span className="opacity-80">_</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
