# FKSmallComponents — Design Requirements

Implementation guide for FKKit **small UI components** (“widgets”): lightweight, single-purpose views and controls that appear constantly in lists, headers, filters, and profile surfaces — smaller in scope than **`FKEmptyState`**, **`FKActionSheet`**, or **`FKListKit`**, but requiring consistent FK styling and behavior.

**Document type:** Design requirements (normative for implementers)  
**Status:** Draft  
**Roadmap reference:** [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md) §2.2–2.3, Tier 3 `FKMarquee`  
**中文版本:** [FKSmallComponents_DESIGN.zh-CN.md](FKSmallComponents_DESIGN.zh-CN.md)

---

## Table of Contents

- [1. Executive Summary](#1-executive-summary)
- [2. Goals, Non-Goals, and Success Criteria](#2-goals-non-goals-and-success-criteria)
- [3. What Qualifies as a Small Component](#3-what-qualifies-as-a-small-component)
- [4. Shared Design Language](#4-shared-design-language)
- [5. Size, Density & Touch Targets](#5-size-density--touch-targets)
- [6. Component Catalog](#6-component-catalog)
- [7. FKAvatar](#7-fkavatar)
- [8. FKAvatarGroup](#8-fkavatargroup)
- [9. FKChip](#9-fkchip)
- [10. FKTag](#10-fktag)
- [11. FKChipGroup](#11-fkchipgroup)
- [12. FKStatusPill](#12-fkstatuspill)
- [13. FKPresenceIndicator](#13-fkpresenceindicator)
- [14. FKIconView](#14-fkiconview)
- [15. FKCopyChip](#15-fkcopychip)
- [16. FKMarqueeLabel](#16-fkmarqueelabel)
- [17. Existing Small Components (Reference)](#17-existing-small-components-reference)
- [18. Composition & Integration Patterns](#18-composition--integration-patterns)
- [19. SwiftUI Bridge Policy](#19-swiftui-bridge-policy)
- [20. Proposed Source Layout](#20-proposed-source-layout)
- [21. FKKitExamples Scenarios](#21-fkkitexamples-scenarios)
- [23. Open Questions](#23-open-questions)
- [24. Revision History](#24-revision-history)

---

## 1. Executive Summary

Large FKKit modules solve **screens and flows**. Small components solve **repeated atoms** that every app renders dozens of times:

- User avatar in navigation bar and comment rows
- Filter chips above product grids
- “VIP”, “Beta”, “Out of stock” tags on cards
- Online presence dot on avatar
- Copy-to-clipboard account IDs

Some atoms already ship (**`FKBadge`**, **`FKDivider`**, **`FKCornerShadow`**). The **FKSmallComponents** family standardizes the rest under one design contract so integrators get predictable configuration, defaults, accessibility, and SwiftUI bridges.

| Planned / new | Role |
|---------------|------|
| **`FKAvatar`** | Image / initials / placeholder user portrait |
| **`FKAvatarGroup`** | Stacked overlapping avatars (+N) |
| **`FKChip`** | Selectable / removable filter chip |
| **`FKTag`** | Read-only metadata label |
| **`FKChipGroup`** | Single/multi-select chip container |
| **`FKStatusPill`** | Semantic status capsule (success/warning/error) |
| **`FKPresenceIndicator`** | Online / busy / offline dot |
| **`FKIconView`** | Sized SF Symbol / template icon container |
| **`FKCopyChip`** | Truncated text + copy action |
| **`FKMarqueeLabel`** | Horizontal scrolling announcement text |

**Already production (same family conventions):** `FKBadge`, `FKDivider`, `FKCornerShadow`, `FKExpandableText` (compact text utility).

---

## 2. Goals, Non-Goals, and Success Criteria

### 2.1 Goals

1. **Single-purpose, small API surface** — each type fits in one README screen; no mini-frameworks.
2. **Shared configuration pattern** — `Sendable` nested config, `defaultConfiguration`, presets, `@MainActor` UIKit types.
3. **Composable** — embed in `FKListKit` cells, `FKTabBar`, navigation bar, `FKButton` accessories without special cases.
4. **HIG baseline** — 44pt expanded hit area when interactive; Dynamic Type; RTL; Dark Mode; Reduce Motion.
5. **Reuse FKKit** — `FKButton`, `FKBadge`, `FKImageView` (when available), `FKLayerBorderStyle`, `FKUIKitI18n`.
6. **SwiftUI** — thin `Representable` or native SwiftUI twin where cost is low (`FKDivider` model).

### 2.2 Non-Goals

| Excluded | Use instead |
|----------|-------------|
| Full empty/loading screens | `FKEmptyState`, `FKSkeleton` |
| Form controls (switch, slider) | `FKFormControls` |
| Toasts / banners | `FKToast`, `FKBanner` (roadmap) |
| Theme token system | Future `FKTheme` |
| Generic `UILabel` wrapper | Host styling or `FKExpandableText` |

### 2.3 Success Criteria

- [ ] Each new small component: README, Examples hub row, root index entry.
- [ ] Chip + Tag + StatusPill and Avatar family ship.
- [ ] Consistent `defaultConfiguration` story documented in umbrella README.
- [ ] Catalog decision tree: Chip vs Tag vs StatusPill vs Badge.

---

## 3. What Qualifies as a Small Component

### 3.1 Heuristics

| Criterion | Small component | Not small |
|-----------|-----------------|-----------|
| Primary responsibility | One visual atom | Orchestrates multiple atoms + state machine |
| Typical LOC (implementation) | ~200–800 | 2000+ |
| Configuration structs | 1–4 nested | 8+ layers |
| Standalone Example scenarios | 2–4 | 10+ |
| Depends on sheet/nav infrastructure | Rarely | Often |

### 3.2 Relationship to roadmap tiers

- **Tier 2** §2.2–2.3 explicitly lists Chip/Tag and Avatar.
- **Tier 3** `FKMarquee` included here as compact text motion widget.
- **Tier 1** items (ListKit, SearchBar) are **out of scope** for this document.

---

## 4. Shared Design Language

### 4.1 Configuration layering

Every new small component **should** use:

```swift
public struct FK<Component>Configuration: Sendable, Equatable {
  public var layout: FK<Component>LayoutConfiguration
  public var appearance: FK<Component>AppearanceConfiguration
  public var interaction: FK<Component>InteractionConfiguration  // when UIControl
  public var accessibility: FK<Component>AccessibilityConfiguration
}
```

Omit layers that do not apply (e.g. `FKTag` read-only may omit `interaction`).

### 4.2 Global defaults

```swift
public enum FK<Component>Defaults {
  @MainActor public static var configuration: FK<Component>Configuration
}
```

Mirror **`FKBadge.defaultConfiguration`** pattern; document launch-time override.

### 4.3 Control vs view

| Kind | Base class | Examples |
|------|------------|----------|
| Interactive | `UIControl` | `FKChip`, `FKCopyChip`, `FKAvatar` (when tappable) |
| Display-only | `UIView` | `FKTag`, `FKStatusPill`, `FKPresenceIndicator`, `FKDivider` |
| Overlay / attachment | Controller pattern | `FKBadgeController` |

### 4.4 Visual tokens (until `FKTheme`)

Use semantic colors:

- `label`, `secondaryLabel`, `tertiaryLabel`
- `systemFill`, `secondarySystemFill`
- Semantic: `.systemGreen`, `.systemOrange`, `.systemRed` for status

Corner radius: **capsule** for chips/tags/pills; **circle** for avatars; **8–12pt** for small rounded rects.

### 4.5 Motion

- Selection: short scale or fill cross-fade (≤ 0.2s)
- Respect **`UIAccessibility.isReduceMotionEnabled`**
- Optional haptics on chip toggle (`FKButton` feedback patterns)

---

## 5. Size, Density & Touch Targets

### 5.1 Size tiers

| Tier | Height (pt) | Typical use |
|------|-------------|-------------|
| **XS** | 20–24 | Inline tag in dense list |
| **S** | 28–32 | Filter chips, status pills |
| **M** | 36–40 | Avatar inline, standard chip |
| **L** | 48–56 | Profile header avatar |
| **XL** | 64–80 | Profile detail hero |

### 5.2 Touch expansion

Interactive components **must** expand hit area to **44×44pt** minimum via `point(inside:with:)` or layout padding without visually enlarging capsule (document in each README).

### 5.3 Dynamic Type

- Text in chips/tags: support at least **2** content size steps before switching to `adjustsFontForContentSizeCategory` truncation
- Avatar initials scale with tier config `scalesWithDynamicType`

---

## 6. Component Catalog

| Component | Interactive | Primary text/media | Badge overlap |
|-----------|-------------|-------------------|---------------|
| **FKAvatar** | Optional | Image / initials | `FKBadge`, `FKPresenceIndicator` |
| **FKAvatarGroup** | Optional | Stacked avatars | — |
| **FKChip** | Yes | Title + optional icon | Remove ✕ |
| **FKTag** | No* | Title + optional icon | — |
| **FKChipGroup** | Container | — | — |
| **FKStatusPill** | Optional | Short status word | — |
| **FKPresenceIndicator** | No | Colored dot | — |
| **FKIconView** | Optional | SF Symbol | `FKBadge` |
| **FKCopyChip** | Yes | Monospace / ID | Copy icon |
| **FKMarqueeLabel** | No | Marquee text | — |
| **FKBadge** (existing) | Optional tap | Dot/count/text | — |
| **FKDivider** (existing) | No | Line | — |

\* `FKTag` may become tappable in v1.1 for filter URLs; v1 read-only.

### 6.1 Decision tree

```text
Need overlay count on icon/tab?     → FKBadge
Need hairline separator?              → FKDivider
Need user portrait?                   → FKAvatar (+ Presence)
Need filter toggle / removable?       → FKChip (+ ChipGroup)
Need read-only category label?        → FKTag
Need success/warning/error word?      → FKStatusPill
Need copy ID action?                  → FKCopyChip
Need scrolling ticker text?           → FKMarqueeLabel
```

---

## 7. FKAvatar

**Module path:** `Sources/FKUIKit/Components/Widgets/Avatar/`  
### 7.1 Role

Circular or squircle portrait: remote/local image, initials fallback, loading/error states, optional tap.

### 7.2 Shapes

```swift
public enum FKAvatarShape: Sendable, Equatable {
  case circle
  case squircle(cornerRadius: CGFloat)  // continuous curve preferred
  case roundedRectangle(cornerRadius: CGFloat)
}
```

### 7.3 Content modes

| Mode | Source |
|------|--------|
| **Image** | `UIImage`, URL via `FKImageView`, or asset name |
| **Initials** | Derived from `displayName` (1–2 chars, localized rules) |
| **Placeholder** | SF Symbol `person.fill` or config icon |
| **Loading** | `FKSkeleton` circular or spinner overlay |

### 7.4 Public API

```swift
@MainActor
public final class FKAvatar: UIControl {
  public var configuration: FKAvatarConfiguration
  public var displayName: String?       // drives initials
  public var imageURL: URL?
  public var image: UIImage?

  public func setImageURL(_ url: URL?, placeholder: UIImage?)
  public func setDisplayName(_ name: String?)
}
```

### 7.5 Size presets

`FKAvatarSize`: `.xs(24)`, `.s(32)`, `.m(40)`, `.l(56)`, `.xl(72)`, `.custom(diameter:)`

### 7.6 Border & ring

- Optional `FKLayerBorderStyle` (story ring, unread ring)
- **Story** preset: gradient ring via `FKCornerShadow` / CAGradientLayer mask (document performance)

### 7.7 Accessories

| Accessory | Integration |
|-----------|-------------|
| Online status | **`FKPresenceIndicator`** anchored bottom-trailing |
| Notification count | **`FKBadge`** on avatar view |
| Verified check | Small overlay icon (config `showsVerifiedBadge`)

### 7.8 Accessibility

- Label: “Avatar for {name}” or “User avatar”
- Traits: `.image` or `.button` when `isUserInteractionEnabled`

### 7.9 States

- Loading, loaded, failed (retry tap optional), empty initials

---

## 8. FKAvatarGroup

### 8.1 Role

Overlapping stack for “+3 collaborators” UI.

### 8.2 Layout

```swift
public struct FKAvatarGroupConfiguration: Sendable, Equatable {
  public var maxVisible: Int           // default 4
  public var overlap: CGFloat          // negative spacing
  public var size: FKAvatarSize
  public var showsOverflowCount: Bool  // “+N” pill
  public var direction: FKAvatarGroupDirection  // .leadingOnTop
}
```

### 8.3 API

```swift
@MainActor
public final class FKAvatarGroup: UIView {
  public var avatars: [FKAvatarContent]  // image URL or initials
  public var onOverflowTap: (() -> Void)?
  public var onAvatarTap: ((Int) -> Void)?
}
```

### 8.4 RTL

Mirror overlap direction; maintain z-order policy (leading avatar on top vs trailing).

---

## 9. FKChip

**Module path:** `Sources/FKUIKit/Components/Widgets/Chip/`  
### 9.1 Role

Compact **toggle** or **filter** control: selected vs normal, optional leading icon, optional remove affordance.

### 9.2 Modes

| `FKChipMode` | Behavior |
|--------------|----------|
| `.filter` | Tap toggles selected; used in `FKChipGroup` |
| `.input` | Removable token (shows ✕); no selected fill |
| `.suggestion` | Tap fires action once; does not stay selected |
| `.choice` | Radio-like exclusive selection within group |

### 9.3 Public type

```swift
@MainActor
public final class FKChip: UIControl {
  public var configuration: FKChipConfiguration
  public var title: String
  public var isSelected: Bool
  public var leadingIcon: FKChipIcon?
  public var showsRemoveButton: Bool

  public var onRemove: (() -> Void)?
}
```

Emit `UIControl.Event.valueChanged` on selection toggle.

### 9.4 Appearance states

| State | Visual |
|-------|--------|
| Normal | `secondarySystemFill` background |
| Selected | `tintColor` fill or outline+fill per config |
| Disabled | Reduced opacity |
| Highlighted | Scale 0.97 |

### 9.5 Remove button

- Trailing ✕ `UIButton` subview; 44pt hit area
- `onRemove` does not trigger selection toggle
- Accessibility: “Remove {title}”

### 9.6 Icons

```swift
public enum FKChipIcon: Sendable, Equatable {
  case systemName(String)
  case asset(String)
  case none
}
```

---

## 10. FKTag

### 10.1 Role

**Read-only** metadata capsule — category, promo label, “NEW”, role name. Not a control v1 (UIView).

### 10.2 Variants

```swift
public enum FKTagVariant: Sendable, Equatable {
  case neutral
  case brand
  case success
  case warning
  case error
  case outline
  case custom(FKTagColors)
}
```

### 10.3 API

```swift
@MainActor
public final class FKTag: UIView {
  public var configuration: FKTagConfiguration
  public var title: String
  public var leadingIcon: FKChipIcon?
}
```

### 10.4 Chip vs Tag (normative)

| Aspect | FKChip | FKTag |
|--------|--------|-------|
| Interactive | Yes (`UIControl`) | No (display) |
| Selected state | Yes | No |
| Remove button | Optional | No |
| Use | Filters, tokens | Labels on cards |

---

## 11. FKChipGroup

### 11.1 Role

Horizontal (or vertical) layout of **`FKChip`** with selection policy.

### 11.2 Selection policies

```swift
public enum FKChipGroupSelectionMode: Sendable, Equatable {
  case none           // chips manage own state independently
  case single         // radio behavior
  case multiple(max: Int?)
}
```

### 11.3 Layout

- Flow layout with wrapping (`UICollectionView` compositional or custom `FKFlowLayout`)
- `spacing`, `lineSpacing`, `contentInsets`
- Scrollable horizontal variant for filter bars (`showsHorizontalScrollIndicator = false`)

### 11.4 API

```swift
@MainActor
public final class FKChipGroup: UIView {
  public var chips: [FKChipItem]  // Sendable model: id, title, icon
  public var selectionMode: FKChipGroupSelectionMode
  public var selectedIDs: Set<String>

  public var onSelectionChange: ((Set<String>) -> Void)?
}
```

### 11.5 Accessibility

- Group trait with “Filter options” label
- Selected chips announce “selected”

---

## 12. FKStatusPill

### 12.1 Role

Short **semantic status** text: “Active”, “Pending”, “Failed”, “Shipped”.

### 12.2 Difference from FKTag

StatusPill maps **workflow state** with fixed semantic colors; Tag is **taxonomic** (category, promo).

### 12.3 API

```swift
public enum FKStatusPillStyle: Sendable, Equatable {
  case success, warning, error, info, neutral, custom(FKStatusPillColors)
}

@MainActor
public final class FKStatusPill: UIView {
  public var title: String
  public var style: FKStatusPillStyle
  public var showsDot: Bool   // leading 6pt dot
  public var configuration: FKStatusPillConfiguration
}
```

### 12.4 Optional interaction

When `configuration.interaction.isTappable`, subclass `UIControl` behavior — show help `FKCallout` on tap (host wiring).

---

## 13. FKPresenceIndicator

### 13.1 Role

8–12pt dot: online, offline, busy, away.

```swift
public enum FKPresenceState: Sendable, Equatable {
  case online
  case offline
  case busy
  case away
  case custom(UIColor)
}
```

### 13.2 Placement

- Attach to **`FKAvatar`** via configuration
- Standalone with white border ring for contrast on photos

### 13.3 Animation

Optional pulse for `.online` when Reduce Motion off.

---

## 14. FKIconView

### 14.1 Role

Fixed-size template icon container (24/28/32pt) with optional circular background — used in list rows before **`FKChip`** leading icons unify.

```swift
@MainActor
public final class FKIconView: UIView {
  public var symbolName: String?
  public var image: UIImage?
  public var configuration: FKIconViewConfiguration  // size, tint, background fill
}
```

Supports `FKBadge` attachment via existing extensions.

---

## 15. FKCopyChip

### 15.1 Role

Monospace or truncated ID with copy action (“Order #A1288… 📋”).

### 15.2 Behavior

- Tap copies `UIPasteboard.general.string`
- Optional `FKToast` success feedback (host injects or config flag)
- Haptic light impact

```swift
@MainActor
public final class FKCopyChip: UIControl {
  public var text: String
  public var copyText: String?  // nil = full text
  public var configuration: FKCopyChipConfiguration
}
```

---

## 16. FKMarqueeLabel

### 16.1 Role

Single-line announcement ticker; pauses on drag; **stops** when Reduce Motion enabled (static truncate + accessibility full text).

### 16.2 API

```swift
@MainActor
public final class FKMarqueeLabel: UIView {
  public var text: String
  public var configuration: FKMarqueeLabelConfiguration  // speed, spacing, fade edges
}
```

---

## 17. Existing Small Components (Reference)

Implementers **must not** rebuild these; extend via configuration:

| Component | Role | Doc |
|-----------|------|-----|
| **FKBadge** | Dot/count/text overlay | `Components/Badge/README.md` |
| **FKDivider** | Separators | `Components/Divider/README.md` |
| **FKCornerShadow** | Rounded rect + shadow | `Components/CornerShadow/README.md` |
| **FKExpandableText** | Truncation + expand | `Components/ExpandableText/README.md` |

New avatars use **`FKBadge`** — do not duplicate badge rendering inside Avatar.

---

## 18. Composition & Integration Patterns

### 18.1 FKListKit cells

- Leading: `FKAvatar` + title stack; trailing: `FKTag` / `FKStatusPill`
- Filter header: `FKChipGroup` in supplementary view

### 18.2 Navigation bar

- `FKAvatar` `.s` in `leftBarButtonItem` custom view
- Do not embed `FKChipGroup` in nav bar (use filter row below)

### 18.3 FKButton

- Leading `FKIconView` inside button content — prefer `FKButton` built-in image slots when possible; `FKIconView` for standalone icon atoms

### 18.4 Image loading

- **`FKAvatar`** uses **`FKImageView`** when shipped; until then UIImage/URL placeholder API with documented swap

---

## 19. SwiftUI Bridge Policy

| Component | Bridge style |
|-----------|--------------|
| FKTag, FKStatusPill, FKPresenceIndicator | Native SwiftUI `View` twin optional |
| FKChip, FKAvatar | `UIViewRepresentable` |
| FKChipGroup | Representable + `Binding<Set<String>>` |
| FKMarqueeLabel | Representable |

Follow **`FKDividerView`** precedent for dual stacks when layout is simple.

---

## 20. Proposed Source Layout

The family lives under a **single** module folder: `Sources/FKUIKit/Components/Widgets/` (in-app UI widgets — **not** WidgetKit extensions). Each type uses a **subfolder**; shared helpers live in `Widgets/Core/`.

```text
Sources/FKUIKit/Components/Widgets/
├── README.md                         # Catalog + shared conventions
├── Core/
│   ├── Public/
│   │   └── FKWidgetIcon.swift        # Shared icon descriptor for Chip/Tag if needed
│   └── Internal/
│       ├── FKCapsuleLayoutEngine.swift
│       ├── FKFlowLayoutView.swift
│       └── FKWidgetLayoutMetrics.swift
├── Avatar/
│   ├── Public/                       # FKAvatar, FKAvatarGroup, configurations
│   └── Internal/
├── Chip/
│   ├── Public/                       # FKChip, FKTag, FKChipGroup
│   └── Internal/
├── StatusPill/
│   ├── Public/
│   └── Internal/
├── PresenceIndicator/
│   ├── Public/
│   └── Internal/
├── IconView/
│   ├── Public/
│   └── Internal/
├── CopyChip/
│   ├── Public/
│   └── Internal/
└── Marquee/
    ├── Public/                       # FKMarqueeLabel
    └── Internal/
```

**Naming:** **`Widgets`** denotes lightweight reusable UI atoms, sibling to other `Components/<Name>/` modules — not separate top-level folders under `Components/` (e.g. not `Components/Avatar/` alongside `Components/Button/`).

---

## 21. FKKitExamples Scenarios

Path: `Examples/.../FKUIKit/Widgets/`

| # | Scenario | Components |
|---|----------|------------|
| 1 | `FilterChipBar` | FKChipGroup single/multi |
| 2 | `RemovableInputChips` | FKChip input mode |
| 3 | `ProductTags` | FKTag variants |
| 4 | `OrderStatusPills` | FKStatusPill |
| 5 | `ProfileAvatar` | FKAvatar + Presence + Badge |
| 6 | `AvatarGroupRow` | FKAvatarGroup +N |
| 7 | `CopyOrderID` | FKCopyChip + Toast |
| 8 | `ListRowComposition` | Avatar + Tag + Status |
| 9 | `DarkModeRTL` | All |
| 10 | `DynamicType` | Chips/tags AX5 |
| 11 | `SwiftUIRepresentables` | Bindings |
| 12 | `MarqueeAnnouncement` | FKMarqueeLabel |

---

## 23. Open Questions

| ID | Question | Proposed default |
|----|----------|------------------|
| Q1 | Single folder for Tag with Chip? | Yes, under `Widgets/Chip/` with shared Core |
| Q2 | FKTag tappable v1? | No |
| Q3 | Avatar without FKImageView initially? | Stub UIImage; full integration when FKImageView ships |
| Q4 | StatusPill vs Tag merge? | Separate types |
| Q5 | Native SwiftUI twins for all? | Divider/Tag only first |

---

## 24. Revision History

| Date | Change |
|------|--------|
| 2026-06-08 | Initial umbrella design for FKSmallComponents family |

---

## Related Documents

- [COMPONENT_ROADMAP.md](COMPONENT_ROADMAP.md)
- [FKListKit_DESIGN.md](FKListKit_DESIGN.md)
- [FKImageLoader-FKImageView_DESIGN.md](FKImageLoader-FKImageView_DESIGN.md)
- [FKFormControls_DESIGN.md](FKFormControls_DESIGN.md)
