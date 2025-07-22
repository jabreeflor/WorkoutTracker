import SwiftUI

struct StoreView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Coming Soon")
                    .font(.largeTitle)
                    .padding()
                
                Text("Store features will be available in a future update.")
                    .foregroundColor(.gray)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Store")
        }
    }
}

#Preview {
    StoreView()
}