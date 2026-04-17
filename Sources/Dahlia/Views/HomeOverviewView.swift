import SwiftUI

/// Home の仮実装。Meetings / Projects と同じ overview レイアウトに寄せる。
struct HomeOverviewView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.home)
                        .font(.largeTitle.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(L10n.homeUnderConstruction)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(.background)
    }
}
