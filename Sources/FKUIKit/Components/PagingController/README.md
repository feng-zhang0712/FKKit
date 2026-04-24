# FKPagingController

`FKPagingController` is a page container centered on two-way synchronization with `FKTabBar`.

## Highlights

- Bidirectional sync: tab tap drives page switch, page drag drives tab indicator progress.
- Stateful transition pipeline with interruption protection (`idle`, `dragging`, `settling`, `programmaticSwitch`, `interrupted`).
- Lazy page loading and memory-aware retention (`keepAll`, `keepNear`).
- Configurable gesture conflict strategy for nested scroll views and edge back gestures.
- Runtime updates for tabs/pages while preserving stable selected index.

## Quick Start

- Create `FKPagingController` with tab items and pages.
- Push or embed it as a normal child view controller.
- Observe transitions through `FKPagingControllerDelegate`.
