import UIKit
#if canImport(SwiftUI)
import SwiftUI
import FKUIKit

private struct FKChipSwiftUIDemoRoot: View {
  @State private var filterSelected = true
  @State private var barSelectedIDs: Set<String> = ["all"]
  @State private var multiSelectedIDs: Set<String> = []
  @State private var limitAlert = false

  private let groupChips = FKChipExampleSupport.filterBarItems()

  var body: some View {
    NavigationView {
      Form {
        Section {
          FKChipRepresentable(
            mode: .filter,
            title: "SwiftUI filter",
            isSelected: $filterSelected,
            leadingIcon: .symbol(name: "sparkles")
          )
          .frame(maxWidth: .infinity, minHeight: 44)
        } header: {
          Text("FKChipRepresentable")
        } footer: {
          Text("Wraps FKChip with a Binding<Bool> for selection state.")
        }

        Section {
          FKChipRepresentable(
            mode: .input,
            title: "Removable",
            isSelected: .constant(false),
            showsRemoveButton: true,
            onRemove: {}
          )
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        } header: {
          Text("Input + remove")
        }

        Section("FKChipGroupRepresentable") {
          FKChipGroupRepresentable(
            chips: groupChips,
            selectionMode: .single,
            selectedIDs: $barSelectedIDs
          )
          .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)

          Text("Selected: \(barSelectedIDs.sorted().joined(separator: ", "))")
            .font(.footnote)
            .foregroundStyle(.secondary)
        }

        Section("FKTagView") {
          HStack(spacing: 8) {
            FKTagView(title: "NEW", variant: .brand)
            FKTagView(title: "Hot", variant: .warning, leadingIcon: .symbol(name: "flame.fill"))
            FKTagView(title: "VIP", variant: .custom(FKTagCustomVariant(
              backgroundColor: UIColor.systemIndigo.withAlphaComponent(0.15),
              foregroundColor: .systemIndigo
            )))
          }
        }

        Section("Group limit demo") {
          FKChipGroupRepresentable(
            chips: FKChipExampleSupport.categoryItems(),
            selectionMode: .multiple(max: 2),
            selectedIDs: $multiSelectedIDs,
            onSelectionLimitReached: { limitAlert = true }
          )
          .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
        }
      }
      .navigationTitle("SwiftUI bridges")
      .alert("Selection limit reached", isPresented: $limitAlert) {
        Button("OK", role: .cancel) {}
      }
    }
    .navigationViewStyle(.stack)
  }
}

final class FKChipExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridges"

    let host = UIHostingController(rootView: FKChipSwiftUIDemoRoot())
    addChild(host)
    host.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(host.view)
    NSLayoutConstraint.activate([
      host.view.topAnchor.constraint(equalTo: view.topAnchor),
      host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    host.didMove(toParent: self)
  }
}
#endif

#if !canImport(SwiftUI)
import UIKit

final class FKChipExampleSwiftUIViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "SwiftUI bridges"
    view.backgroundColor = .systemBackground
    let label = UILabel()
    label.text = "SwiftUI is unavailable in this build configuration."
    label.textAlignment = .center
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)
    NSLayoutConstraint.activate([
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
    ])
  }
}
#endif
