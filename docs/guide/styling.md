# Styling

TUIKit provides powerful styling capabilities for your terminal UI.

## Text Styling

```swift
Text("Bold").bold()
Text("Italic").italic()
Text("Underline").underline()
Text("Strikethrough").strikethrough()
```

## Colors

```swift
Text("Red").foregroundColor(.red)
Text("Green").foregroundColor(.green)
Text("Custom RGB").foregroundColor(.rgb(100, 200, 50))
Text("Hex").foregroundColor(.hex("#FF5733"))
```

## Borders

```swift
Text("Rounded border").border(.rounded)
Text("Line border").border(.line)
Text("Thick border").border(.thick)
```

## More Details

Visit the API reference for the complete styling API.
