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
    prompt: "$",
    command: "ls -la",
    output: ["drwxr-xr-x  12 root", "-rw-r--r--   1 .profile", "-rw-------   1 .runcom", "drwx------   3 .rhost"],
  },
  {
    prompt: "$",
    command: "ls /etc",
    output: ["hosts       passwd", "inittab     shadow", "fstab       group", "rc2.d       motd"],
  },
  {
    prompt: "$",
    command: "ls -l /var/adm",
    output: ["-rw-r----- syslog    47K", "-rw-r----- sulog      8K", "-rw-r----- messages  12K", "-rw-r----- wtmp      31K"],
  },
  {
    prompt: "$",
    command: "pwd",
    output: ["/usr/operator"],
  },
  {
    prompt: "$",
    command: "du -s /var/adm/*",
    output: ["94  syslog", "16  sulog", "24  messages", "62  wtmp"],
  },
  {
    prompt: "$",
    command: "find /etc -name '*.conf'",
    output: ["/etc/resolv.conf", "/etc/ntp.conf", "/etc/syslog.conf", "/etc/uucp/Systems"],
  },
  {
    prompt: "$",
    command: "file /bin/sh",
    output: ["MC68020 executable", "not stripped"],
  },
  {
    prompt: "$",
    command: "ls /dev/console",
    output: ["crw--w--w- 0,0 console"],
  },
  // ── Process & System ──────────────────────
  {
    prompt: "$",
    command: "ps -ef | head -5",
    output: ["  PID TTY  TIME CMD", "    0 ?    0:12 sched", "    1 ?    0:03 /etc/init", "   42 ?    0:01 /etc/cron", "   58 co   0:00 /bin/sh"],
  },
  {
    prompt: "$",
    command: "uptime",
    output: ["up 47 days, 12:33, 2 users"],
  },
  {
    prompt: "$",
    command: "who",
    output: ["root     console  Jan 30", "operator ttyp0    Jan 31"],
  },
  {
    prompt: "$",
    command: "uname -a",
    output: ["UNIX darkstar 3.2 2 m68k"],
  },
  {
    prompt: "$",
    command: "hostname",
    output: ["darkstar"],
  },
  {
    prompt: "$",
    command: "id",
    output: ["uid=100(operator)", "gid=100(users)"],
  },
  {
    prompt: "$",
    command: "date",
    output: ["Fri Jan 31 22:47:03 EST"],
  },
  {
    prompt: "$",
    command: "cal",
    output: ["   January 1986", "Su Mo Tu We Th Fr Sa", "          1  2  3  4", " 5  6  7  8  9 10 11"],
  },
  {
    prompt: "$",
    command: "env | head -4",
    output: ["HOME=/usr/operator", "SHELL=/bin/sh", "TERM=vt100", "TZ=EST5EDT"],
  },
  {
    prompt: "$",
    command: "sar -u 3 1",
    output: ["darkstar  UNIX 3.2  m68k", "%usr %sys %wio %idle", " 4.2  2.1  0.8  92.9"],
  },
  // ── Disk & Mount ──────────────────────────
  {
    prompt: "$",
    command: "df",
    output: ["/dev/dsk/0s0  72MB  51MB  21MB", "/dev/dsk/0s1  72MB  38MB  34MB"],
  },
  {
    prompt: "$",
    command: "mount",
    output: ["/dev/dsk/0s0 on / type s5", "/dev/dsk/0s1 on /usr type s5", "/dev/fd0 on /mnt type s5"],
  },
  // ── Network ───────────────────────────────
  {
    prompt: "$",
    command: "ifconfig en0",
    output: ["inet 10.0.1.42", "netmask 255.255.255.0", "broadcast 10.0.1.255", "UP RUNNING"],
  },
  {
    prompt: "$",
    command: "ping darkstar",
    output: ["darkstar is alive"],
  },
  {
    prompt: "$",
    command: "netstat -rn",
    output: ["Destination  Gateway", "default      10.0.1.1", "10.0.1.0     10.0.1.42", "127.0.0.1    127.0.0.1"],
  },
  {
    prompt: "$",
    command: "netstat -a | head -4",
    output: ["Proto Local Address", "tcp   *.telnet  LISTEN", "tcp   *.ftp     LISTEN", "tcp   *.smtp   LISTEN"],
  },
  {
    prompt: "$",
    command: "arp -a",
    output: ["gateway (10.0.1.1) at", "  08:00:20:1a:2b:3c", "wopr (10.0.1.10) at", "  08:00:20:4d:5e:6f"],
  },
  {
    prompt: "$",
    command: "nslookup darkstar",
    output: ["Server: 10.0.1.1", "Name: darkstar", "Address: 10.0.1.42"],
  },
  {
    prompt: "$",
    command: "finger @darkstar",
    output: ["Login   Name      TTY Idle", "root    Super-User co  0:12", "operator          p0     "],
  },
  {
    prompt: "$",
    command: "rlogin wopr",
    output: ["Connection refused"],
  },
  // ── Text & File Content ───────────────────
  {
    prompt: "$",
    command: "cat /etc/motd",
    output: ["*** AUTHORIZED USE ONLY ***", "All activity is monitored."],
  },
  {
    prompt: "$",
    command: "head -3 /etc/passwd",
    output: ["root:x:0:0:Super-User:/:/bin/sh", "daemon:x:1:1::/:", "operator:x:100:100::/usr/operator"],
  },
  {
    prompt: "$",
    command: "wc -l /etc/passwd",
    output: ["18 /etc/passwd"],
  },
  {
    prompt: "$",
    command: "grep 'sh' /etc/passwd",
    output: ["root:x:0:0:Super-User:/:/bin/sh", "operator:x:100:100::/usr/operator"],
  },
  {
    prompt: "$",
    command: "awk -F: '{print $1}' /etc/passwd",
    output: ["root", "daemon", "bin", "operator", "nobody", "uucp", "lp"],
  },
  {
    prompt: "$",
    command: "tail -5 /var/adm/syslog",
    output: ["Jan 31 22:41 login: ROOT", "  LOGIN on console", "Jan 31 22:42 cron: CMD", "  /usr/lib/sa/sadc", "Jan 31 22:45 inetd[58]"],
  },
  {
    prompt: "$",
    command: "cut -d: -f1,3 /etc/group",
    output: ["root:0", "other:1", "bin:2", "sys:3", "adm:4", "users:100"],
  },
  {
    prompt: "$",
    command: "cat /etc/inittab | head -4",
    output: ["id:2:initdefault:", "si::sysinit:/etc/bcheckrc", "s2:2:wait:/etc/rc2", "co:2:respawn:/etc/getty console"],
  },
  {
    prompt: "$",
    command: "cat /etc/rc2.d/S80lp",
    output: ["#!/bin/sh", "# Start LP spooler", "/usr/lib/lpsched"],
  },
  // ── Permissions & Admin ───────────────────
  {
    prompt: "$",
    command: "chmod 600 .runcom",
    output: [],
  },
  {
    prompt: "$",
    command: "last -5",
    output: ["operator ttyp0 10.0.1.5", "root     console", "operator ttyp0 10.0.1.5", "reboot   ~      system boot"],
  },
  {
    prompt: "$",
    command: "su -",
    output: ["Password:", "su: Sorry"],
  },
  // ── UUCP & Communication ──────────────────
  {
    prompt: "$",
    command: "uuname",
    output: ["darkstar", "wopr", "norad"],
  },
  {
    prompt: "$",
    command: "mailx",
    output: ["No mail for operator"],
  },
  {
    prompt: "$",
    command: "write root",
    output: ["Permission denied"],
  },
  // ── Misc Tools ────────────────────────────
  {
    prompt: "$",
    command: "echo $PATH",
    output: ["/bin:/usr/bin:/usr/local/bin"],
  },
  {
    prompt: "$",
    command: "crontab -l",
    output: ["# operator crontab", "0 3 * * * /usr/local/backup", "0 * * * * /usr/lib/sa/sadc"],
  },
  {
    prompt: "$",
    command: "stty",
    output: ["speed 9600 baud", "rows 24; columns 80", "erase = ^H; kill = ^U"],
  },
  {
    prompt: "$",
    command: "tty",
    output: ["/dev/ttyp0"],
  },
  {
    prompt: "$",
    command: "sum /bin/sh",
    output: ["42struc 14 /bin/sh"],
  },
  {
    prompt: "$",
    command: "banner HELLO",
    output: ["#  #  #### #    #    ###", "#  #  #    #    #    # #", "####  ###  #    #    # #", "#  #  #    #    #    # #", "#  #  #### #### #### ###"],
  },
  // ── UUCP & Modem ──────────────────────────
  {
    prompt: "$",
    command: "uustat -a",
    output: ["darkstarN0042 01/31 22:14", "  norad!~/receive 847 bytes", "darkstarN0043 01/31 22:31", "  wopr!~/spool/batch 2.1K"],
  },
  {
    prompt: "$",
    command: "uulog -s norad",
    output: ["uucp norad (01/31-22:14)", "  OK (startup)", "  SUCCEEDED (call to norad)", "  OK (conversation complete)"],
  },
  {
    prompt: "$",
    command: "cu -s 2400 -l /dev/tty01",
    output: ["Connected.", "login:", "^d", "Disconnected."],
  },
  {
    prompt: "$",
    command: "cat /etc/uucp/Systems",
    output: ["norad  Any ACU 2400 5551234", "  ogin: uucp ssword: secret", "wopr   Any ACU 1200 5559876", "  ogin: guest ssword: joshua"],
  },
  // ── Printing ──────────────────────────────
  {
    prompt: "$",
    command: "lpstat -t",
    output: ["scheduler is running", "lp0 accepting requests", "  printer lp0 now printing", "  lp0-127 operator  2841 bytes"],
  },
  {
    prompt: "$",
    command: "lpstat -o",
    output: ["lp0-127 operator  2841 Jan 31", "lp0-128 root      1204 Jan 31"],
  },
  {
    prompt: "$",
    command: "cancel lp0-128",
    output: ["request \"lp0-128\" cancelled"],
  },
  // ── Editor ────────────────────────────────
  {
    prompt: "$",
    command: "ed /etc/motd",
    output: ["58", "1,$p", "*** AUTHORIZED USE ONLY ***", "All activity is monitored.", "q"],
  },
  {
    prompt: "$",
    command: "vi --version",
    output: ["Version SVR3.2 (10/15/84)"],
  },
  // ── Archiving & Tape ──────────────────────
  {
    prompt: "$",
    command: "tar tvf /dev/rmt/0",
    output: ["drwxr-xr-x root/sys", "  usr/spool/uucp/", "-rw-r--r-- uucp/uucp", "  LOGFILE 4217 Jan 31"],
  },
  {
    prompt: "$",
    command: "cpio -itv < /dev/rmt/0",
    output: ["-rw-r--r--  1 root", "  etc/passwd  847 Jan 30", "-rw-------  1 root", "  etc/shadow  412 Jan 30"],
  },
  {
    prompt: "$",
    command: "dd if=/dev/rmt/0 bs=512",
    output: ["142+0 records in", "142+0 records out"],
  },
  // ── System Admin ──────────────────────────
  {
    prompt: "$",
    command: "vmstat 1 3",
    output: [" procs  memory   page", " r b  avm  fre  fr  sr", " 1 0  842  312   0   0", " 0 0  842  312   0   0"],
  },
  {
    prompt: "$",
    command: "swap -l",
    output: ["swapfile       blocks  free", "/dev/dsk/0s2    16384  15840"],
  },
  {
    prompt: "$",
    command: "sysdef | head -4",
    output: ["* System Devices", "MC68020 processor", "4096K memory", "1 CDC Wren 72MB disk"],
  },
  {
    prompt: "$",
    command: "dmesg | tail -4",
    output: ["mem = 4096K", "hd0: CDC Wren IV 72MB", "  94 cyls, 9 heads, 17 sec", "clock: ticking at 100 Hz"],
  },
  {
    prompt: "$",
    command: "whodo",
    output: ["Fri Jan 31 22:51 darkstar", "console  root     22:14", "  init", "ttyp0    operator 22:33", "  sh"],
  },
  // ── Kermit ────────────────────────────────
  {
    prompt: "$",
    command: "kermit -l /dev/tty01",
    output: ["C-Kermit 4E(072)", "  for UNIX System V", "Type ? for help", "C-Kermit>"],
  },
  {
    prompt: "$",
    command: "tip -2400 norad",
    output: ["connected", "login:", "~.", "disconnected"],
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
  { type: "instant", text: "  telnetd        [ok]", delayAfter: 1800 },
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

  const usedIndicesRef = useRef<Set<number>>(new Set());
  const linesRef = useRef<string[]>([]);
  const abortRef = useRef<AbortController | null>(null);
  const sessionTimeRef = useRef<number>(0);
  const joshuaPlayedRef = useRef(false);

  const pickInteraction = useCallback((): TerminalEntry => {
    const used = usedIndicesRef.current;
    if (used.size >= INTERACTIONS.length) {
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
    lineRefsRef.current = [];
    setLines([]);
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
    if (!powered) return;

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

    /**
     * Simulates a human typing at a physical keyboard.
     *
     * Varies timing per character to mimic real keystrokes:
     * - Short bursts of fast typing (50–80ms) for familiar sequences
     * - Thinking pauses (300–600ms) after spaces and punctuation
     * - Occasional mid-word hesitation (200–350ms, ~15% chance)
     * - Slightly faster within a word, slower at boundaries
     */
    const typeUser = async (text: string, prefix = "") => {
      pushLine(prefix);
      for (let charIdx = 0; charIdx < text.length; charIdx++) {
        updateLastLine(prefix + text.slice(0, charIdx + 1));
        const char = text[charIdx];
        const nextChar = text[charIdx + 1];

        let delay: number;
        if (char === " " || char === "." || char === "," || char === "?") {
          /* Pause after word boundary or punctuation — thinking time. */
          delay = 250 + Math.random() * 350;
        } else if (nextChar === " " || charIdx === text.length - 1) {
          /* Slightly slower on last char of a word — finger lifting. */
          delay = 100 + Math.random() * 120;
        } else if (Math.random() < 0.15) {
          /* Occasional mid-word hesitation — hunting for the right key. */
          delay = 180 + Math.random() * 170;
        } else {
          /* Fast burst within a word. */
          delay = 45 + Math.random() * 55;
        }
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
  }, [powered, pickInteraction, pushLine, updateLastLine, clearScreen]);

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

  /* Powered off — no content, just dark glass. */
  if (!powered) return null;

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
        {lines.map((line, index) => (
          <div
            key={index}
            ref={(element) => { lineRefsRef.current[index] = element; }}
            className="whitespace-pre overflow-hidden"
          >
            {line.length > COLS ? line.slice(0, COLS) : line}
            {index === lines.length - 1 && cursorVisible && (
              <span className="opacity-80">_</span>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
