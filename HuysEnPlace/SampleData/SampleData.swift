//
//  SampleData.swift
//  HuysEnPlace
//
//  Created by Huy Nguyen on 7/4/25.
//

import SwiftUI

let banhMiRecipeMarkdown: String = """
## Bánh Mì — Makes 6 (≈ 125 g unbaked each)

### Ingredients
- 450 g Bread Flour
- 260 g Water
- 1 Whole Egg (50 g)
- 8 g Instant Yeast
- 2 g Salt
- 2 g Sugar
- 1 g Ascorbic Acid (Vitamin C)
- Vegetable Oil (as needed)

### Equipment
- Lava Rocks
- Stand Mixer
- Kitchen Scale
- Precision Scale
- Baguette Pans
- Rolling Pin
- Plastic Dough Scraper
- Spray Bottle
- Lame (bread-scoring tool)
- Razor Blades

### Instructions
1. **Mix the dough**  
   In a mixing bowl, combine egg, water, yeast, sugar, salt, and ascorbic acid.  
   Add the flour and mix until just combined.

2. **Develop gluten**  
   Using a stand mixer, mix on low speed for **7 minutes**.  
   Increase to high speed and mix for **3 minutes**, or until the gluten is fully developed (total time varies by mixer).

3. **Bench rest**  
   Lightly oil your work surface.  
   Turn the dough out, slap-and-fold 4–6 times, and shape into a ball.  
   Cover and rest for **20 minutes**.

4. **Portion & pre-shape**  
   Divide into **six 120 g** pieces. Roll each into a tight ball.  
   Cover and rest for **20 minutes**.

5. **Final shape**  
   Shape each ball into a baguette (tapered ends, seam side down).  
   Place on a lightly oiled baguette pan.

6. **Proof**  
   Proof in the oven **with the light on** and a pot of warm water for **60 minutes**, misting with water every 15 minutes.  
   Remove from the oven and proof on the countertop for **30 minutes**.  
   Meanwhile, preheat the oven to **450 °F / 232 °C** (bottom heat only if possible) with two trays—one filled with lava rocks.

7. **Score & steam**  
   When the loaves have risen to **2.5–3×** their original size and the oven is ready, bring water to a boil.  
   Score each loaf with a lame or razor, then mist immediately with water.

8. **Bake**  
   Load the baguette pans into the oven and carefully pour boiling water over the lava rocks (and into the secondary tray if using) to generate steam.  
   Bake **8 minutes** without opening the door.  
   Vent the oven to release excess steam, then bake for an additional **7–8 minutes** (or until the desired color is reached).

9. **Cool & crackle**  
   Remove the loaves and cool on a rack.  
   Signature cracks should appear within **5–10 minutes**.

_Enjoy your fresh, crackly-crusted Bánh Mì!_
"""

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

let allIngredients: [Ingredient] = [
    .init(id: "bread-flour", name: "Bread Flour"),
    .init(id: "water", name: "Water"),
    .init(id: "yeast", name: "Yeast"),
    .init(id: "sugar", name: "Sugar"),
    .init(id: "salt", name: "Salt"),
    .init(id: "ascorbic-acid", name: "Ascorbic Acid"),
    .init(id: "vegetable-oil", name: "Vegetable Oil")
]

@MainActor let banhMiRecipe = Recipe(title: "Bánh Mì Bread", content: banhMiRecipeContent, ingredients: [])
