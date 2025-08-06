import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel

    var body: some View {
        Text("perfil")
    }
}

#Preview {
    CurrentSessionBuilder().build()
}
