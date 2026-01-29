# Theme Usage Guide

## Quick Reference

### Using Theme Colors
```dart
// Backgrounds
Theme.of(context).scaffoldBackgroundColor
Theme.of(context).cardColor

// Text
Theme.of(context).textTheme.bodyLarge?.color      // Primary text
Theme.of(context).textTheme.bodySmall?.color      // Secondary text
Theme.of(context).textTheme.titleLarge?.color     // Headings

// Icons & Dividers
Theme.of(context).iconTheme.color
Theme.of(context).dividerTheme.color

// Color Scheme
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.surface
Theme.of(context).colorScheme.error
```

### Toggle Theme
```dart
Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
```

### Check Current Theme
```dart
final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
```

## Common Patterns

### AppBar
```dart
AppBar(
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  iconTheme: IconThemeData(color: Theme.of(context).iconTheme.color),
  title: Text(
    'Title',
    style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color),
  ),
)
```

### Card/Container
```dart
Container(
  decoration: BoxDecoration(
    color: Theme.of(context).cardColor,
    border: Border.all(color: Theme.of(context).dividerTheme.color ?? Colors.grey.shade200),
  ),
)
```

### List Item
```dart
ListTile(
  leading: Icon(icon, color: Theme.of(context).iconTheme.color),
  title: Text(
    title,
    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
  ),
  subtitle: Text(
    subtitle,
    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
  ),
)
```

## Best Practices

✅ Always use `Theme.of(context)` instead of hardcoded colors
✅ Test your UI in both light and dark modes
✅ Keep semantic colors (success green, error red) as explicit colors
✅ Use theme colors for backgrounds, text, icons, and borders
