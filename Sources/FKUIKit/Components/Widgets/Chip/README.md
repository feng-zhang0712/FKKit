# FKChip / FKTag / FKChipGroup

Capsule widgets for filter chips, read-only metadata tags, and grouped chip layout with selection orchestration.

## Requirements

- Swift 6 / iOS 15+
- `import FKUIKit`

## Which type to use

| Need | Use |
|------|-----|
| Toggle/filter/search token (interactive) | `FKChip` (+ `FKChipGroup` for bars) |
| Read-only category/promo label | `FKTag` |
| Workflow/order status word | `FKStatusPill` (separate module) |
| Numeric badge | `FKBadge` |
| Copy ID chip | `FKCopyChip` (separate module) |
| Anchor + dropdown filter panel | FKBusinessKit `TabBarFilter` (composes row chips) |

## Source layout

| Path | Role |
|------|------|
| `Public/FKChip.swift` | Interactive `UIControl` — filter, input, suggestion, choice modes |
| `Public/FKChipEnums.swift` | `FKChipMode`, `FKTagVariant`, `FKChipSize`, group layout/selection enums |
| `Public/FKChipConfiguration.swift` | Layered chip configuration |
| `Public/FKTag.swift` | Read-only metadata capsule (`UIView`) |
| `Public/FKTagConfiguration.swift` | Tag layout and appearance |
| `Public/FKChipGroup.swift` | Flow/scroll layout + selection modes |
| `Public/FKChipItem.swift` | Sendable chip row model |
| `Public/FKChipGroupConfiguration.swift` | Group layout and chip defaults |
| `Public/Bridge/` | `FKChipRepresentable`, `FKTagView`, `FKChipGroupRepresentable` |
| `Internal/` | `FKChipI18n`, `FKTagRenderer`, `FKChipGroupSelectionController`, `FKChipRemoveIcon`, lazy subviews (`FKChip+LazySubviews`, `FKTag+LazySubviews`), group layout (`FKChipGroup+LazyLayout`) |
| `../Core/` | `FKWidgetIcon`, `FKCapsuleLayoutEngine`, `FKCapsuleIntrinsicWidthConstraint`, `FKFlowLayoutView` |

## Quick start

```swift
import FKUIKit

// Filter chip
let chip = FKChip(mode: .filter, title: "Free shipping")
chip.isSelected = true
chip.addAction(UIAction { _ in print(chip.isSelected) }, for: .valueChanged)

// Read-only tag
let tag = FKTag(title: "NEW", variant: .brand)

// Filter bar
let group = FKChipGroup(
  chips: [
    FKChipItem(id: "1", title: "All"),
    FKChipItem(id: "2", title: "Sale"),
  ],
  selectionMode: .single
)
group.onSelectionChange = { ids in print(ids) }
group.onChipPrimaryAction = { id in print("suggestion:", id) }  // suggestion mode
group.onChipRemoved = { id in print("removed:", id) }          // input tokens
```

## Defaults

- `FKChipDefaults.configuration`
- `FKTagDefaults.configuration`
- `FKChipGroupDefaults.configuration`

## Examples

Open **FKKitExamples → FKUIKit → Chip** for grouped scenarios covering:

- **FKChip** — filter/choice/input/suggestion modes, configuration playground
- **FKTag** — all variants, sizes, truncation
- **FKChipGroup** — single/multiple selection, horizontal scroll, flow wrap
- **Integration** — list row tags, SwiftUI bridges, RTL & dark mode

## License

See the repository root `LICENSE`.
