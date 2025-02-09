import SwiftUI

struct MenuView: View {
    @ObservedObject var viewModel: MenuViewModel

    var body: some View {
        StackView(root: {
            List {
                ForEach(viewModel.menuOptions) { option in
                    Text(option.title).onTapGesture {
                        viewModel.goTo(option.destination)
                    }
                }
            }
        })
    }
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        MenuBuilder().build()
    }
}
