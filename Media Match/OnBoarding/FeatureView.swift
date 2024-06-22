
import SwiftUI

struct FeatureView: View {
    let iconName: String
    let featureTitle: String
    let featureDescription: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(featureTitle)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(featureDescription)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }
}
