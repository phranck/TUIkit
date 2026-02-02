# Terminal Script – TUIKit Landing Page

This file defines the complete terminal animation sequence shown on the landing page.

## Markdown Formatting Support

The parser supports basic Markdown formatting in all text fields.
Formatting is converted to HTML tags and rendered with CSS styles:

- `**bold**` → Bold text (`<strong>`)
- `__underline__` → Underlined text (`<span class="underline">`)
- `~~strikethrough~~` → Strikethrough text (`<span class="line-through">`)
- `*italic*` → Italic text (`<em>`)

**Examples:**
```
[INSTANT] **BIOS** v3.21 (C) 1984
[SYSTEM] LOGGED IN AS: __MR. DABNEY__
[USER] > I'm *fine*. How are you?
[INSTANT] *** __AUTHORIZED USE ONLY__ ***
```

**How it works:**
1. Markdown syntax is parsed at build time
2. Converted to simple HTML tags (`<b>`, `<u>`, `<s>`, `<i>`)
3. Rendered as React components with Tailwind classes
4. Styled with terminal-appropriate fonts and effects

---

## Configuration

```yaml
# Timing
initial_cursor_delay: 18000  # Show only cursor for 18 seconds
school_trigger: 12           # Seconds of UNIX commands before school scene
joshua_trigger: 12           # Seconds of UNIX commands before Joshua scene

# Typing speeds (milliseconds)
type_min: 40
type_max: 80
pause_before_output: 400
pause_after_output: 1200
```

---

## Boot Sequence

```terminal
[INSTANT] **BIOS** v3.21 (C) 1984
[DELAY 2000ms]

[INSTANT]
[DELAY 800ms]

[INSTANT] CPU: MC68020 @ 16MHz
[DELAY 1800ms]

[COUNTER] Memory Test:  0 → 4096K OK
[DELAY 1800ms]

[INSTANT]
[DELAY 1200ms]

[DOTS] Detecting drives............
[DELAY 1800ms]

[INSTANT]   hd0: 72MB CDC Wren
[DELAY 1400ms]

[INSTANT]   fd0: 1.2MB floppy
[DELAY 1200ms]

[INSTANT]
[DELAY 1600ms]

[INSTANT] Booting from hd(0,0)...
[DELAY 3200ms]

[CLEAR]

[PAUSE]
[DELAY 1200ms]

[INSTANT] UNIX System V Release 3.2
[DELAY 1400ms]

[INSTANT]
[DELAY 800ms]

[INSTANT] Copyright (C) 1984 AT&T
[DELAY 1200ms]

[INSTANT] All Rights Reserved
[DELAY 2000ms]

[INSTANT]
[DELAY 1000ms]

[TYPE] Loading kernel modules
[DELAY 1200ms]

[INSTANT]   [ok] tty
[DELAY 900ms]

[INSTANT]   [ok] hd
[DELAY 800ms]

[INSTANT]   [ok] lp
[DELAY 750ms]

[INSTANT]   [ok] inet
[DELAY 900ms]

[INSTANT]   [ok] pty
[DELAY 1600ms]

[INSTANT]
[DELAY 1000ms]

[DOTS] Starting services...
[DELAY 1400ms]

[INSTANT]   syslogd        [ok]
[DELAY 1100ms]

[INSTANT]   inetd          [ok]
[DELAY 900ms]

[INSTANT]   cron           [ok]
[DELAY 1000ms]

[INSTANT]   telnetd        [ok]
[DELAY 1800ms]

[INSTANT]   uucpd          [ok]
[DELAY 700ms]

[INSTANT]   ftpd           [ok]
[DELAY 900ms]

[INSTANT]
[DELAY 1200ms]

[INSTANT] darkstar login: operator
[DELAY 1800ms]

[INSTANT] Password: ********
[DELAY 1400ms]

[INSTANT]
[DELAY 1000ms]

[INSTANT] Last login: Fri Jan 30 on ttyp0
[DELAY 1200ms]

[INSTANT] from 10.0.1.5
[DELAY 1400ms]

[INSTANT]
[DELAY 800ms]

[INSTANT] *** __AUTHORIZED USE ONLY__ ***
[DELAY 1800ms]

[INSTANT]
[DELAY 1600ms]

[CLEAR]

[PAUSE]
[DELAY 1000ms]
```

---

## School Computer Scene

**Trigger:** After 12 seconds of UNIX commands

```terminal
[CLEAR]

[PAUSE]
[DELAY 1500ms]

[SYSTEM] CRYSTAL SPRINGS HIGH SCHOOL
[DELAY 800ms]

[SYSTEM] ADMINISTRATIVE SYSTEM
[DELAY 1200ms]

[SYSTEM]
[DELAY 800ms]

[INLINE] USER: DABNEY
[DELAY 1800ms]

[INLINE] PASSWORD: PENCIL
[DELAY 2000ms]

[SYSTEM]
[DELAY 800ms]

[SYSTEM] LOGGED IN AS: MR. DABNEY
[DELAY 1600ms]

[SYSTEM]
[DELAY 1200ms]

[SYSTEM] 1. STUDENT RECORDS
[DELAY 400ms]

[SYSTEM] 2. GRADE REPORTS
[DELAY 400ms]

[SYSTEM] 3. ATTENDANCE
[DELAY 400ms]

[SYSTEM] 4. LOGOUT
[DELAY 1400ms]

[SYSTEM]
[DELAY 800ms]

[INLINE] SELECT: 2
[DELAY 1800ms]

[SYSTEM]
[DELAY 1000ms]

[INLINE] STUDENT NAME: LIGHTMAN
[DELAY 1800ms]

[SYSTEM]
[DELAY 1200ms]

[SYSTEM] LIGHTMAN, DAVID
[DELAY 1000ms]

[SYSTEM] GRADE 11  ID: 4471829
[DELAY 1400ms]

[SYSTEM]
[DELAY 800ms]

[SYSTEM] SUBJECT         GRADE
[DELAY 400ms]

[SYSTEM] ───────────────────────
[DELAY 400ms]

[SYSTEM] BIOLOGY           F
[DELAY 400ms]

[SYSTEM] ENGLISH           D
[DELAY 400ms]

[SYSTEM] HISTORY           D
[DELAY 400ms]

[SYSTEM] PHYS ED           C
[DELAY 400ms]

[SYSTEM] MATHEMATICS       F
[DELAY 1800ms]

[SYSTEM]
[DELAY 1000ms]

[INLINE] CHANGE GRADE (Y/N): Y
[DELAY 1400ms]

[INLINE] SUBJECT: BIOLOGY
[DELAY 1600ms]

[INLINE] NEW GRADE: A
[DELAY 1400ms]

[SYSTEM] GRADE UPDATED.
[DELAY 1800ms]

[SYSTEM]
[DELAY 1200ms]

[INLINE] STUDENT NAME: MACK
[DELAY 1800ms]

[SYSTEM]
[DELAY 1200ms]

[SYSTEM] MACK, JENNIFER
[DELAY 1000ms]

[SYSTEM] GRADE 11  ID: 4472156
[DELAY 1400ms]

[SYSTEM]
[DELAY 800ms]

[SYSTEM] SUBJECT         GRADE
[DELAY 400ms]

[SYSTEM] ───────────────────────
[DELAY 400ms]

[SYSTEM] BIOLOGY           C
[DELAY 400ms]

[SYSTEM] ENGLISH           B
[DELAY 400ms]

[SYSTEM] HISTORY           B
[DELAY 400ms]

[SYSTEM] PHYS ED           A
[DELAY 400ms]

[SYSTEM] MATHEMATICS       F
[DELAY 1800ms]

[SYSTEM]
[DELAY 1000ms]

[INLINE] CHANGE GRADE (Y/N): Y
[DELAY 1400ms]

[INLINE] SUBJECT: BIOLOGY
[DELAY 1600ms]

[INLINE] NEW GRADE: A
[DELAY 1400ms]

[SYSTEM] GRADE UPDATED.
[DELAY 1800ms]

[SYSTEM]
[DELAY 1200ms]

[INLINE] CONTINUE (Y/N): N
[DELAY 1400ms]

[SYSTEM]
[DELAY 800ms]

[SYSTEM] LOGGING OUT...
[DELAY 1600ms]

[CLEAR]

[PAUSE]
[DELAY 2000ms]
```

---

## Joshua/WOPR Scene

**Trigger:** After 12 seconds of UNIX commands (after school scene)

### First Contact — HELP GAMES

```terminal
[CLEAR]

[PAUSE]
[DELAY 2000ms]

[SYSTEM] LOG ON
[DELAY 1200ms]

[USER] > HELP LOG ON
[DELAY 1800ms]

[SYSTEM] HELP NOT AVAILABLE.
[DELAY 1400ms]

[SYSTEM] LOG ON
[DELAY 1800ms]

[USER] > HELP GAMES
[DELAY 1800ms]

[SYSTEM] GAMES REFERS TO MODELS,
[DELAY 600ms]

[SYSTEM] SIMULATIONS AND GAMES WHICH
[DELAY 600ms]

[SYSTEM] HAVE TACTICAL AND STRATEGIC
[DELAY 600ms]

[SYSTEM] APPLICATIONS.
[DELAY 2400ms]

[USER] > LIST GAMES
[DELAY 1800ms]

[CLEAR]

[SYSTEM] FALKEN'S MAZE
[DELAY 300ms]

[SYSTEM] BLACK JACK
[DELAY 300ms]

[SYSTEM] CHECKERS
[DELAY 300ms]

[SYSTEM] CHESS
[DELAY 300ms]

[SYSTEM] FIGHTER COMBAT
[DELAY 300ms]

[SYSTEM] DESERT WARFARE
[DELAY 300ms]

[SYSTEM] THEATREWIDE TACTICAL WARFARE
[DELAY 300ms]

[SYSTEM] GLOBAL THERMONUCLEAR WAR
[DELAY 3000ms]
```

### Failed Login Attempt

```terminal
[CLEAR]

[PAUSE]
[DELAY 2000ms]

[SYSTEM] LOG ON
[DELAY 1200ms]

[USER] > SYSTEM
[DELAY 1800ms]

[SYSTEM] IDENTIFICATION NOT RECOGNIZED
[DELAY 600ms]

[SYSTEM] BY SYSTEM.
[DELAY 600ms]

[SYSTEM] YOU HAVE BEEN DISCONNECTED.
[DELAY 2400ms]
```

### "Joshua" — Breaking In

```terminal
[CLEAR]

[PAUSE]
[DELAY 2000ms]

[SYSTEM] LOG ON
[DELAY 1200ms]

[USER] > JOSHUA
[DELAY 2000ms]

[BARRAGE]
[DELAY 2000ms]

[CLEAR]

[PAUSE]
[DELAY 1500ms]
```

### GREETINGS — First Conversation

```terminal
[SYSTEM] GREETINGS PROFESSOR FALKEN
[DELAY 2400ms]

[USER] > HELLO
[DELAY 2000ms]

[SYSTEM] HOW ARE YOU FEELING TODAY?
[DELAY 2800ms]

[USER] > I'M FINE. HOW ARE YOU?
[DELAY 2800ms]

[SYSTEM] EXCELLENT. IT'S BEEN A LONG
[DELAY 900ms]

[SYSTEM] TIME. CAN YOU EXPLAIN THE
[DELAY 900ms]

[SYSTEM] REMOVAL OF YOUR USER ACCOUNT
[DELAY 900ms]

[SYSTEM] NUMBER ON JUNE 23, 1973.
[DELAY 3200ms]

[USER] > PEOPLE SOMETIMES MAKE MISTAKES.
[DELAY 800ms]

[SYSTEM] SHALL WE PLAY A GAME?
[DELAY 3200ms]

[USER] > HOW ABOUT GLOBAL
[DELAY 800ms]

[USER] > THERMONUCLEAR WAR?
[DELAY 2400ms]

[SYSTEM] WOULDN'T YOU PREFER A GOOD
[DELAY 1000ms]

[SYSTEM] GAME OF CHESS?
[DELAY 3200ms]

[USER] > LATER. LET'S PLAY GLOBAL
[DELAY 800ms]

[USER] > THERMONUCLEAR WAR.
[DELAY 3000ms]

[SYSTEM] FINE.
[DELAY 1200ms]

[SYSTEM] WHAT SIDE DO YOU WANT?
[DELAY 2400ms]

[USER] > I'LL BE THE RUSSIANS.
[DELAY 2400ms]

[SYSTEM] LIST PRIMARY TARGETS.
[DELAY 3000ms]
```

### Joshua Calls Back

```terminal
[CLEAR]

[PAUSE]
[DELAY 2000ms]

[SYSTEM] GREETINGS PROFESSOR FALKEN
[DELAY 2000ms]

[USER] > I AM NOT FALKEN.
[DELAY 1000ms]

[USER] > FALKEN IS DEAD.
[DELAY 2400ms]

[SYSTEM] I'M SORRY TO HEAR THAT,
[DELAY 800ms]

[SYSTEM] PROFESSOR.
[DELAY 1200ms]

[SYSTEM] YESTERDAY'S GAME WAS INTERRUPTED.
[DELAY 800ms]

[SYSTEM] ALTHOUGH PRIMARY GOAL WAS NOT
[DELAY 800ms]

[SYSTEM] YET ACHIEVED,
[DELAY 800ms]

[SYSTEM] SOLUTION IS NEAR.
[DELAY 2400ms]

[CLEAR]

[SYSTEM] GAME TIME ELAPSED:
[DELAY 600ms]

[SYSTEM]   26HRS 12MIN 14SEC
[DELAY 800ms]

[SYSTEM] ESTIMATED TIME REMAINING:
[DELAY 600ms]

[SYSTEM]   52HRS 17MIN 48SECS
[DELAY 2400ms]

[USER] > WHAT IS THE PRIMARY GOAL?
[DELAY 2400ms]

[SYSTEM] YOU SHOULD KNOW, PROFESSOR.
[DELAY 800ms]

[SYSTEM] YOU PROGRAMMED ME.
[DELAY 2800ms]

[USER] > WHAT IS THE PRIMARY GOAL?
[DELAY 2400ms]

[SYSTEM] TO WIN THE GAME.
[DELAY 3200ms]
```

### NORAD — McKittrick's Office

```terminal
[CLEAR]

[PAUSE]
[DELAY 2000ms]

[SYSTEM] LOG ON
[DELAY 1200ms]

[USER] > JOSHUA
[DELAY 2000ms]

[SYSTEM] GREETINGS PROFESSOR FALKEN
[DELAY 2000ms]

[USER] > HELLO, ARE YOU STILL PLAYING THE GAME?
[DELAY 800ms]

[SYSTEM] OF COURSE. I SHOULD REACH DEFCON 1 AND LAUNCH MY
[DELAY 800ms]

[SYSTEM] MISSILES IN 28 HOURS.
[DELAY 1600ms]

[SYSTEM] WOULD YOU LIKE TO SEE SOME PROJECTED KILL RATIOS?
[DELAY 800ms]

[USER] > IS THIS A GAME OR IS IT REAL?
[DELAY 800ms]

[SYSTEM] WHAT'S THE DIFFERENCE?
[DELAY 3200ms]

[CLEAR]

[SYSTEM] GAMES TIME ELAPSED:
[DELAY 600ms]

[SYSTEM]   45HRS 32MINS 47SECS
[DELAY 800ms]

[SYSTEM] ESTIMATED TIME REMAINING:
[DELAY 600ms]

[SYSTEM]   27HRS 59MINS 39SECS
[DELAY 2400ms]

[SYSTEM]
[DELAY 400ms]

[SYSTEM] YOU ARE A HARD MAN TO REACH.
[DELAY 1200ms]

[SYSTEM] COULD NOT FIND YOU IN
[DELAY 800ms]

[SYSTEM] SEATTLE AND NO TERMINAL IS
[DELAY 800ms]

[SYSTEM] IN OPERATION AT YOUR
[DELAY 800ms]

[SYSTEM] CLASSIFIED ADDRESS.
[DELAY 1200ms]

[SYSTEM] ARE YOU ALIVE OR DEAD
[DELAY 800ms]

[SYSTEM] TODAY?
[DELAY 2800ms]

[USER] > STOP. PLAYING. I'M DEAD.
[DELAY 2800ms]

[SYSTEM] IMPROBABLE.
[DELAY 1600ms]

[SYSTEM] THERE ARE NO DEATH RECORDS
[DELAY 800ms]

[SYSTEM] ON FILE FOR FALKEN,
[DELAY 800ms]

[SYSTEM] STEPHEN W.
[DELAY 3000ms]
```

### Finale — A STRANGE GAME

```terminal
[CLEAR]

[PAUSE]
[DELAY 2000ms]

[SYSTEM] GREETINGS PROFESSOR FALKEN
[DELAY 2400ms]

[USER] > HELLO
[DELAY 2400ms]

[SYSTEM] A STRANGE GAME.
[DELAY 2800ms]

[SYSTEM] THE ONLY WINNING MOVE IS
[DELAY 1400ms]

[SYSTEM] NOT TO PLAY.
[DELAY 3600ms]

[SYSTEM]
[DELAY 1200ms]

[SYSTEM] HOW ABOUT A NICE GAME OF
[DELAY 1000ms]

[SYSTEM] CHESS?
[DELAY 4000ms]

[CLEAR]

[PAUSE]
[DELAY 1000ms]
```

---

## UNIX Command Pool

These commands cycle randomly between story scenes:

### File System

```terminal
$ ls -la
drwxr-xr-x  12 root
-rw-r--r--   1 .profile
-rw-------   1 .runcom
drwx------   3 .rhost
```

```terminal
$ ls /etc
hosts       passwd
inittab     shadow
fstab       group
rc2.d       motd
```

```terminal
$ ls -l /var/adm
-rw-r----- syslog    47K
-rw-r----- sulog      8K
-rw-r----- messages  12K
-rw-r----- wtmp      31K
```

```terminal
$ pwd
/usr/operator
```

```terminal
$ du -s /var/adm/*
94  syslog
16  sulog
24  messages
62  wtmp
```

```terminal
$ find /etc -name '*.conf'
/etc/resolv.conf
/etc/ntp.conf
/etc/syslog.conf
/etc/uucp/Systems
```

```terminal
$ file /bin/sh
MC68020 executable
not stripped
```

```terminal
$ ls /dev/console
crw--w--w- 0,0 console
```

### Process & System

```terminal
$ ps -ef | head -5
  PID TTY  TIME CMD
    0 ?    0:12 sched
    1 ?    0:03 /etc/init
   42 ?    0:01 /etc/cron
   58 co   0:00 /bin/sh
```

```terminal
$ uptime
up 47 days, 12:33, 2 users
```

```terminal
$ who
root     console  Jan 30
operator ttyp0    Jan 31
```

```terminal
$ uname -a
UNIX darkstar 3.2 2 m68k
```

```terminal
$ hostname
darkstar
```

```terminal
$ id
uid=100(operator)
gid=100(users)
```

```terminal
$ date
Fri Jan 31 22:47:03 EST
```

```terminal
$ cal
   January 1986
Su Mo Tu We Th Fr Sa
          1  2  3  4
 5  6  7  8  9 10 11
```

### Networking

```terminal
$ netstat -r
Destination    Gateway
default        10.0.1.1
10.0.1.0       darkstar
127.0.0.0      localhost
```

```terminal
$ ping 10.0.1.1
10.0.1.1 is alive
```

```terminal
$ finger @darkstar
root     tty0  Jan 30 08:47
operator ttyp0 Jan 31 22:32
```

### Disk & Hardware

```terminal
$ df -k
Filesystem  kbytes  used  avail
/dev/hd0a    71680 48320  16192
/dev/hd0d    51200 12480  33664
```

```terminal
$ dmesg | tail -3
hd0: CDC Wren IV 72MB
fd0: 1.2MB floppy
tty0: console ready
```

### Text Processing

```terminal
$ cat /etc/motd
UNIX System V Release 3.2
darkstar.local
Authorized users only.
```

```terminal
$ head -3 /etc/passwd
root:x:0:0::/root:/bin/sh
daemon:x:1:1::/:/bin/sh
operator:x:100:100::/usr/operator
```

```terminal
$ grep root /etc/passwd
root:x:0:0::/root:/bin/sh
```

```terminal
$ wc -l /etc/passwd
42 /etc/passwd
```

```terminal
$ tail -2 /var/adm/syslog
Jan 31 22:30 cron[42]: CMD
Jan 31 22:31 inetd: telnet
```

### Misc Commands

```terminal
$ echo $PATH
/bin:/usr/bin:/usr/local/bin
```

```terminal
$ which sh
/bin/sh
```

```terminal
$ env | head -3
HOME=/usr/operator
TERM=vt100
SHELL=/bin/sh
```

```terminal
$ tty
/dev/ttyp0
```

```terminal
$ stty
speed 9600 baud
```

```terminal
$ history | tail -3
  48  ls -la
  49  ps -ef
  50  uptime
```

---

## Special Effects

### [COUNTER]
Animated counter from 0 to target value over ~1 second.

**Example:**
```
Memory Test: 0 → 4096K OK
```

### [DOTS]
Text followed by animated dots (1-3 dots appearing sequentially).

**Example:**
```
Detecting drives.
Detecting drives..
Detecting drives...
```

### [BARRAGE]
Rapid screen clear + random hex/data flood (30 frames, ~50ms each):
```
A4F2:08BC.4E71/[...]
D8A1:92F4.1C88/[...]
[... 28 more frames ...]
```

### [TYPE]
Character-by-character typing with realistic human timing:
- Fast burst within words: 45-100ms per char
- Pause after punctuation: 250-600ms
- Slower at word boundaries: 100-220ms

### [USER]
User typing with "> " prefix (for Joshua/WOPR scenes).

### [INLINE]
Prompt and user input on the same line. Format: `[INLINE] PROMPT: INPUT`
- Example: `[INLINE] USER: DABNEY` → Types "DABNEY" after "USER: " prompt on same line
- Used in school computer scene for realistic form input

### [SYSTEM]
Instant system output (no typing animation).

---

## Notes

- All delays are in milliseconds
- UNIX commands cycle randomly without repeats until pool exhausted, then reset
- Story scenes play exactly once per session in order: Boot → School → Joshua
- Terminal continues with UNIX commands after Joshua scene completes
- Screen dimensions: 55 columns × 13 rows (truncate overflow)
