//
//  RecipeSettings.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/4/25.
//

import SwiftUI
import PhotosUI

struct RecipeSettings: View {
    @Bindable var recipe: Recipe

    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        Form {
            HStack(alignment: .center) {
                PhotosPicker(
                    selection: $selectedPhoto,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    Text("Recipe Image")
                }

                Spacer()

//                ImageWithPlaceholder(recipe.image) {
//                    ZStack {
//                        Color.gray
//                        Image(systemName: "photo.fill")
//                    }
//                }
//                .frame(width: 50, height: 50)
//                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto else {
                    return
                }

                let image = try? await selectedPhoto.loadTransferable(type: Image.self)
//                recipe.image = try? await image?.exported(as: .image)
            }
        }
    }
}


//#Preview {
//    RecipeSettings()
//}
