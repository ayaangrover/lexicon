import SwiftUI

struct FeatureButtonView: View {
    var title: String
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(red: 63/255, green: 183/255, blue: 154/255))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding()
        }
        .frame(minHeight: 100)
    }
}
