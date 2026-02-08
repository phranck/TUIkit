# TUIkit Project Templates

Two ways to create new TUIkit projects:

## 🚀 Quick Start: Xcode Template (Basic)

**Best for:** Quick prototyping, simple projects

**Features:**
- ✅ Minimal TUIkit project setup
- ✅ Integrated into Xcode File > New > Project
- ❌ No conditional dependencies (SQLite, tests)

**Installation:**

```bash
mkdir -p ~/Library/Developer/Xcode/Templates
cp -r "TUIkit App.xctemplate" ~/Library/Developer/Xcode/Templates/
```

**Usage:**
1. Xcode > File > New > Project
2. Select "TUIkit App" under macOS
3. Enter project name
4. ⚠️ **Important:** Set run destination to "My Mac"

---

## ⚙️ Full Featured: Shell Script (Recommended)

**Best for:** Production projects, customization needed

**Features:**
- ✅ All TUIkit project setup options
- ✅ Optional SQLite.swift integration
- ✅ Test framework selection (Swift Testing / XCTest)
- ✅ Pre-configured scheme and settings
- ✅ Automatic Xcode configuration

**Usage:**

```bash
./create-tuikit-project.sh
```

Follow the prompts to configure:
1. Project name
2. Test framework (None / Swift Testing / XCTest)
3. SQLite.swift inclusion (y/n)

---

## 📊 Comparison

| Feature | Xcode Template | Shell Script |
|---------|---------------|--------------|
| Xcode Integration | ✅ Native | ❌ Terminal only |
| SQLite Option | ❌ | ✅ |
| Test Framework | ❌ | ✅ |
| Setup Speed | ⚡ Instant | ⚡ < 5 seconds |
| Customization | ⚠️ Limited | ✅ Full control |

---

## 🔧 Technical Details

### Why Two Approaches?

Xcode's Swift Package template system does not support conditional file inclusion. After research:

- ❌ `___IF___` conditionals don't work in Swift Package templates
- ❌ `Units`/`RequiredOptions` only work with `.xcodeproj` templates
- ✅ Shell script with `sed` replacements is the reliable solution

---

## 📚 Resources

- [TUIkit Documentation](https://tuikit.layered.work/documentation/tuikit/)
- [TUIkit GitHub](https://github.com/phranck/TUIkit)
