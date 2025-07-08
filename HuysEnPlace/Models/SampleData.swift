//
//  SampleData.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/4/25.
//

import SwiftUI

let banhMiRecipeContent: AttributedString = """
    Makes 6 Bánh Mì (125g unbaked)

    Ingredients:
    450g Bread Flour https://amzn.to/3zfhQ9e
    260g Water
    1 Whole Egg (50g) https://amzn.to/3LZaPkH
    8g Instant Yeast https://amzn.to/3JSrUtU
    2g Salt https://amzn.to/40EMIf6
    2g Sugar https://amzn.to/3JWGsIO
    1g Ascorbic Acid https://amzn.to/40q71wY
    Vegetable Oil (as needed) https://amzn.to/42LKInd

    Equipment:
    Lava Rocks https://amzn.to/3omHgj9
    Stand Mixer https://amzn.to/3JV5cRB
    Kitchen Scale https://amzn.to/3KdNTNe
    Precision Scale https://amzn.to/3FZPofq
    Baguette Pans https://amzn.to/40rHS5a
    Rolling Pin https://amzn.to/3lMOSKM
    Plastic Dough Scraper https://amzn.to/40DlKV4
    Spray Bottle https://amzn.to/3lL4AX0
    Lame https://amzn.to/3nnrCDv
    Razor Blades https://amzn.to/3zbK1pI
     
    Instructions:
    In a mixing bowl, add egg, water, yeast, sugar, salt and ascorbic acid. Add in flour and combine.

    In a stand mixer, mix on low speed for 7 minutes. Then 3 minutes on high speed. Continue mixing until gluten is fully developed. (Total mixing times will vary depending on mixer).

    Lightly oil work surface. Remove dough from bowl. Slap and fold the dough 4-6 times and form a ball. Cover and let rest for 20 minutes.

    Divide the dough into six 120g portions. Roll into small balls. Cover and let rest for 20 minutes.

    Shape each using the method demonstrated in the video. Place the shaped dough onto a lightly oiled baguette pan.

    Proof in the oven with the light on and a pot of warm water for 60 minutes. Spray with water every 15 minutes.

    Remove from the oven and proof on a countertop for 30 additional minutes. Meanwhile, preheat the oven to Bake 450F (no fan, bottom only if possible) with 2 trays, one with lava rocks.

    Once the dough has grown 2.5 to 3 times in size, and the oven has preheated bowl a pot of water.  Score the loaves with a lame or razor.  Immediately spray with water after scoring.

    Place the baguette pans with the dough into the oven. Immediately pour boiling water onto lava rocks and secondary tray.

    Bake for 8 minutes without opening the door.

    Open the door to release any leftover steam, and bake 7-8 minutes depending on desired color.

    Remove the Bánh Mì from the oven and let cool.  Cracks should form after 5-10 minutes.
    """

let banhMiIngredients: [Ingredient] = [
    .init(name: "Bread Flour")
]

@MainActor let banhMiRecipe = Recipe(title: "Bánh Mì Bread", content: banhMiRecipeContent, ingredients: banhMiIngredients)
