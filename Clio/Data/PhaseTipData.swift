import Foundation

// MARK: - Phase Tip Model
struct PhaseTip: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
    let category: TipCategory
    let phase: CyclePhase
    let whyBenefits: [String]
    let howToEnjoy: [String]

    enum TipCategory: String, CaseIterable {
        case eat = "Eat"
        case move = "Move"

        var icon: String {
            switch self {
            case .eat: return "fork.knife"
            case .move: return "figure.run"
            }
        }
    }
}

// MARK: - Phase Tips Database
struct PhaseTipDatabase {

    // MARK: - Get Tips by Phase
    static func tips(for phase: CyclePhase, category: PhaseTip.TipCategory? = nil) -> [PhaseTip] {
        let allTips: [PhaseTip]

        switch phase {
        case .menstrual: allTips = menstrualTips
        case .follicular: allTips = follicularTips
        case .ovulation: allTips = ovulationTips
        case .luteal: allTips = lutealTips
        }

        if let category = category {
            return allTips.filter { $0.category == category }
        }
        return allTips
    }

    static func foodTips(for phase: CyclePhase) -> [PhaseTip] {
        tips(for: phase, category: .eat)
    }

    static func movementTips(for phase: CyclePhase) -> [PhaseTip] {
        tips(for: phase, category: .move)
    }

    // MARK: - Menstrual Phase Tips (Days 1-5)
    static let menstrualTips: [PhaseTip] = [
        // Foods
        PhaseTip(
            id: "menstrual_spinach",
            name: "Spinach",
            icon: "leaf.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "High in iron to replenish what's lost during menstruation",
                "Contains magnesium which may help reduce cramps",
                "Rich in folate for energy support"
            ],
            howToEnjoy: [
                "Add to smoothies with banana and almond milk",
                "Sauté with garlic as a quick side",
                "Mix into soups or stews"
            ]
        ),
        PhaseTip(
            id: "menstrual_salmon",
            name: "Salmon",
            icon: "fish.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Omega-3 fatty acids may help reduce inflammation and cramps",
                "High-quality protein for sustained energy",
                "Vitamin D supports mood regulation"
            ],
            howToEnjoy: [
                "Bake with lemon and herbs",
                "Add to grain bowls",
                "Make salmon salad for lunch"
            ]
        ),
        PhaseTip(
            id: "menstrual_darkchocolate",
            name: "Dark chocolate",
            icon: "cup.and.saucer.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Magnesium may help ease cramps",
                "Iron content helps with blood loss",
                "Can satisfy cravings without excess sugar"
            ],
            howToEnjoy: [
                "Choose 70%+ cacao for best benefits",
                "Have a few squares as an afternoon treat",
                "Add to oatmeal or yogurt"
            ]
        ),
        PhaseTip(
            id: "menstrual_lentils",
            name: "Lentils",
            icon: "circle.grid.2x2.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Excellent source of iron",
                "High fiber keeps blood sugar stable",
                "Plant protein for sustained energy"
            ],
            howToEnjoy: [
                "Make a warming lentil soup",
                "Add to salads for protein",
                "Cook into dal with warming spices"
            ]
        ),
        PhaseTip(
            id: "menstrual_ginger",
            name: "Ginger",
            icon: "leaf.arrow.triangle.circlepath",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "May help reduce nausea and bloating",
                "Anti-inflammatory properties",
                "Can help with cramp relief"
            ],
            howToEnjoy: [
                "Make fresh ginger tea",
                "Add to stir-fries",
                "Grate into smoothies"
            ]
        ),
        PhaseTip(
            id: "menstrual_banana",
            name: "Bananas",
            icon: "moon.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Potassium helps reduce water retention",
                "Natural sugars for gentle energy",
                "Vitamin B6 may help with mood"
            ],
            howToEnjoy: [
                "Slice onto oatmeal",
                "Blend into smoothies",
                "Eat as a quick snack"
            ]
        ),
        PhaseTip(
            id: "menstrual_redmeat",
            name: "Lean red meat",
            icon: "fork.knife",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Highly absorbable heme iron",
                "Vitamin B12 for energy",
                "Zinc supports immune function"
            ],
            howToEnjoy: [
                "Grass-fed beef in stir-fry",
                "Lean steak with vegetables",
                "Add to hearty soups"
            ]
        ),
        PhaseTip(
            id: "menstrual_warmsoups",
            name: "Warm soups",
            icon: "square.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Easy to digest during low-energy days",
                "Hydrating and nourishing",
                "Comforting and warming"
            ],
            howToEnjoy: [
                "Make bone broth-based soups",
                "Add lots of vegetables",
                "Include protein like chicken or tofu"
            ]
        ),
        PhaseTip(
            id: "menstrual_oatmeal",
            name: "Oatmeal",
            icon: "circle.grid.3x3.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Complex carbs provide steady energy",
                "Fiber helps with digestion",
                "Warming and comforting"
            ],
            howToEnjoy: [
                "Top with berries and honey",
                "Add nut butter for protein",
                "Sprinkle with cinnamon"
            ]
        ),
        PhaseTip(
            id: "menstrual_eggs",
            name: "Eggs",
            icon: "oval.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "High-quality protein for energy",
                "Vitamin D supports mood",
                "Easy to digest"
            ],
            howToEnjoy: [
                "Soft scrambled for comfort",
                "Poached on toast",
                "In a warming egg drop soup"
            ]
        ),
        PhaseTip(
            id: "menstrual_chickpeas",
            name: "Chickpeas",
            icon: "circle.grid.2x2.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Plant-based iron source",
                "Fiber keeps you satisfied",
                "Protein for sustained energy"
            ],
            howToEnjoy: [
                "Blend into hummus",
                "Add to curries and stews",
                "Roast for a crunchy snack"
            ]
        ),
        PhaseTip(
            id: "menstrual_herbalTea",
            name: "Herbal tea",
            icon: "mug.fill",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Hydrating without caffeine",
                "Chamomile and peppermint can soothe cramps",
                "Warming and calming"
            ],
            howToEnjoy: [
                "Ginger tea for nausea",
                "Chamomile before bed",
                "Peppermint after meals"
            ]
        ),
        PhaseTip(
            id: "menstrual_beetroot",
            name: "Beetroot",
            icon: "figure.pool.swim",
            category: .eat,
            phase: .menstrual,
            whyBenefits: [
                "Supports blood production",
                "High in folate and iron",
                "Naturally sweet and satisfying"
            ],
            howToEnjoy: [
                "Roasted with goat cheese",
                "Blended into smoothies",
                "In a warming borscht soup"
            ]
        ),

        // Movements
        PhaseTip(
            id: "menstrual_gentleyoga",
            name: "Gentle yoga",
            icon: "figure.yoga",
            category: .move,
            phase: .menstrual,
            whyBenefits: [
                "Low intensity respects lower energy",
                "May help relieve cramps through gentle stretching",
                "Promotes relaxation and stress relief"
            ],
            howToEnjoy: [
                "Focus on restorative poses",
                "Try child's pose for comfort",
                "Include gentle hip openers"
            ]
        ),
        PhaseTip(
            id: "menstrual_walking",
            name: "Walking",
            icon: "figure.walk",
            category: .move,
            phase: .menstrual,
            whyBenefits: [
                "Gentle movement without strain",
                "Can help reduce bloating",
                "Fresh air supports mood"
            ],
            howToEnjoy: [
                "Take a 20-30 minute walk",
                "Keep pace comfortable",
                "Walk in nature if possible"
            ]
        ),
        PhaseTip(
            id: "menstrual_stretching",
            name: "Stretching",
            icon: "figure.cooldown",
            category: .move,
            phase: .menstrual,
            whyBenefits: [
                "Relieves tension without exhaustion",
                "Can ease lower back pain",
                "Gentle on the body"
            ],
            howToEnjoy: [
                "Focus on hips and lower back",
                "Hold stretches for 30+ seconds",
                "Use props like pillows for support"
            ]
        ),
        PhaseTip(
            id: "menstrual_swimming",
            name: "Light swimming",
            icon: "drop.fill",
            category: .move,
            phase: .menstrual,
            whyBenefits: [
                "Water supports the body",
                "Can relieve cramps",
                "Low-impact movement"
            ],
            howToEnjoy: [
                "Easy laps at comfortable pace",
                "Try water walking",
                "Focus on how it feels, not performance"
            ]
        ),
        PhaseTip(
            id: "menstrual_rest",
            name: "Rest day",
            icon: "bed.double.fill",
            category: .move,
            phase: .menstrual,
            whyBenefits: [
                "Your body is working hard - rest is recovery",
                "Prevents burnout",
                "Honors your body's signals"
            ],
            howToEnjoy: [
                "Light movement only if it feels good",
                "Focus on sleep quality",
                "Gentle stretching if desired"
            ]
        ),
        PhaseTip(
            id: "menstrual_yinyoga",
            name: "Yin yoga",
            icon: "figure.yoga",
            category: .move,
            phase: .menstrual,
            whyBenefits: [
                "Long holds for deep release",
                "Activates parasympathetic nervous system",
                "Meditative and calming"
            ],
            howToEnjoy: [
                "Hold poses for 3-5 minutes",
                "Use lots of props",
                "Focus on breath"
            ]
        )
    ]

    // MARK: - Follicular Phase Tips (Days 6-13)
    static let follicularTips: [PhaseTip] = [
        // Foods
        PhaseTip(
            id: "follicular_eggs",
            name: "Eggs",
            icon: "oval.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Complete protein to support rising energy",
                "Choline supports brain function",
                "Versatile and quick to prepare"
            ],
            howToEnjoy: [
                "Scrambled with vegetables",
                "Poached on avocado toast",
                "Hard-boiled for meal prep"
            ]
        ),
        PhaseTip(
            id: "follicular_citrus",
            name: "Citrus fruits",
            icon: "circle.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Vitamin C supports estrogen metabolism",
                "Refreshing and energizing",
                "Supports immune function"
            ],
            howToEnjoy: [
                "Fresh orange or grapefruit",
                "Lemon in water",
                "Citrus in salad dressings"
            ]
        ),
        PhaseTip(
            id: "follicular_avocado",
            name: "Avocado",
            icon: "leaf.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Healthy fats support hormone production",
                "Fiber for gut health",
                "B vitamins for energy"
            ],
            howToEnjoy: [
                "On toast with everything bagel seasoning",
                "In smoothies for creaminess",
                "Sliced in salads"
            ]
        ),
        PhaseTip(
            id: "follicular_fermented",
            name: "Fermented foods",
            icon: "bubbles.and.sparkles.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Probiotics support gut health",
                "May help with estrogen metabolism",
                "Supports immune system"
            ],
            howToEnjoy: [
                "Kimchi or sauerkraut as sides",
                "Kombucha as afternoon drink",
                "Yogurt with breakfast"
            ]
        ),
        PhaseTip(
            id: "follicular_chicken",
            name: "Chicken",
            icon: "bird.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Lean protein for building energy",
                "Supports muscle recovery",
                "Versatile for many dishes"
            ],
            howToEnjoy: [
                "Grilled chicken salads",
                "Stir-fry with vegetables",
                "Meal prep for the week"
            ]
        ),
        PhaseTip(
            id: "follicular_quinoa",
            name: "Quinoa",
            icon: "circle.grid.3x3.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Complete protein source",
                "Complex carbs for sustained energy",
                "High in iron and magnesium"
            ],
            howToEnjoy: [
                "Base for grain bowls",
                "Breakfast porridge style",
                "Cold in salads"
            ]
        ),
        PhaseTip(
            id: "follicular_sprouts",
            name: "Sprouts",
            icon: "leaf.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Support estrogen metabolism",
                "High in nutrients",
                "Fresh and crunchy"
            ],
            howToEnjoy: [
                "Add to salads and sandwiches",
                "Top grain bowls",
                "Blend into smoothies"
            ]
        ),
        PhaseTip(
            id: "follicular_berries",
            name: "Fresh berries",
            icon: "heart.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Antioxidants support cell health",
                "Natural sweetness without blood sugar spike",
                "Fiber for gut health"
            ],
            howToEnjoy: [
                "Add to yogurt or oatmeal",
                "Blend into smoothies",
                "Eat fresh as snacks"
            ]
        ),
        PhaseTip(
            id: "follicular_greentea",
            name: "Green tea",
            icon: "mug.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Antioxidants boost metabolism",
                "Gentle caffeine for focus",
                "Supports estrogen metabolism"
            ],
            howToEnjoy: [
                "Hot or iced",
                "Matcha lattes",
                "As an afternoon pick-me-up"
            ]
        ),
        PhaseTip(
            id: "follicular_salmon",
            name: "Salmon",
            icon: "fish.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Omega-3s support brain function",
                "Protein for muscle building",
                "Vitamin D for energy"
            ],
            howToEnjoy: [
                "Grilled with lemon",
                "In poke bowls",
                "Baked with herbs"
            ]
        ),
        PhaseTip(
            id: "follicular_seeds",
            name: "Pumpkin seeds",
            icon: "leaf.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Zinc supports hormone balance",
                "Magnesium for energy",
                "Protein-rich snack"
            ],
            howToEnjoy: [
                "Sprinkle on salads",
                "Add to trail mix",
                "Blend into smoothies"
            ]
        ),
        PhaseTip(
            id: "follicular_broccoli",
            name: "Broccoli",
            icon: "leaf.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Supports estrogen metabolism",
                "High in vitamin C",
                "Fiber for gut health"
            ],
            howToEnjoy: [
                "Roasted with garlic",
                "Steamed as a side",
                "In stir-fries"
            ]
        ),
        PhaseTip(
            id: "follicular_lentils",
            name: "Lentils",
            icon: "circle.grid.2x2.fill",
            category: .eat,
            phase: .follicular,
            whyBenefits: [
                "Plant protein for building",
                "Iron for energy",
                "Fiber keeps you full"
            ],
            howToEnjoy: [
                "In warming dals",
                "Cold lentil salads",
                "Added to soups"
            ]
        ),

        // Movements
        PhaseTip(
            id: "follicular_cardio",
            name: "Cardio",
            icon: "figure.run",
            category: .move,
            phase: .follicular,
            whyBenefits: [
                "Rising estrogen supports endurance",
                "Energy is building - use it",
                "Great time to push cardiovascular fitness"
            ],
            howToEnjoy: [
                "Running or jogging",
                "Cycling classes",
                "Dance cardio"
            ]
        ),
        PhaseTip(
            id: "follicular_hiit",
            name: "HIIT",
            icon: "figure.highintensity.intervaltraining",
            category: .move,
            phase: .follicular,
            whyBenefits: [
                "Body can handle higher intensity",
                "Efficient calorie burn",
                "Builds strength and endurance"
            ],
            howToEnjoy: [
                "20-30 minute sessions",
                "Mix strength and cardio intervals",
                "Allow recovery between sets"
            ]
        ),
        PhaseTip(
            id: "follicular_dance",
            name: "Dance cardio",
            icon: "figure.dance",
            category: .move,
            phase: .follicular,
            whyBenefits: [
                "Rising energy makes movement fun",
                "Boosts mood and creativity",
                "Great cardio without feeling like exercise"
            ],
            howToEnjoy: [
                "Join a Zumba or dance class",
                "Follow along to dance videos",
                "Put on music and move freely"
            ]
        ),
        PhaseTip(
            id: "follicular_strength",
            name: "Strength training",
            icon: "figure.strengthtraining.traditional",
            category: .move,
            phase: .follicular,
            whyBenefits: [
                "Muscles recover well in this phase",
                "Building phase for fitness",
                "Energy supports heavier weights"
            ],
            howToEnjoy: [
                "Progressive overload",
                "Compound movements",
                "Full body or split routines"
            ]
        ),
        PhaseTip(
            id: "follicular_running",
            name: "Running",
            icon: "figure.run",
            category: .move,
            phase: .follicular,
            whyBenefits: [
                "Endurance is higher",
                "Good time for longer runs",
                "Speed work is effective"
            ],
            howToEnjoy: [
                "Increase distance gradually",
                "Try interval runs",
                "Run with friends for motivation"
            ]
        ),
        PhaseTip(
            id: "follicular_spinning",
            name: "Spinning",
            icon: "figure.indoor.cycle",
            category: .move,
            phase: .follicular,
            whyBenefits: [
                "High intensity is well tolerated",
                "Great for cardiovascular health",
                "Energizing group atmosphere"
            ],
            howToEnjoy: [
                "Join a class for motivation",
                "Push through challenging intervals",
                "Stay hydrated"
            ]
        )
    ]

    // MARK: - Ovulation Phase Tips (Days 14-16)
    static let ovulationTips: [PhaseTip] = [
        // Foods
        PhaseTip(
            id: "ovulation_salmon",
            name: "Wild salmon",
            icon: "fish.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Omega-3s support hormone balance",
                "High protein for peak energy",
                "Anti-inflammatory benefits"
            ],
            howToEnjoy: [
                "Grilled with herbs",
                "In poke bowls",
                "Baked with vegetables"
            ]
        ),
        PhaseTip(
            id: "ovulation_leafygreens",
            name: "Leafy greens",
            icon: "leaf.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Support liver in processing estrogen",
                "Fiber for gut health",
                "Rich in folate and minerals"
            ],
            howToEnjoy: [
                "Big salads for lunch",
                "Sautéed as sides",
                "Green smoothies"
            ]
        ),
        PhaseTip(
            id: "ovulation_wholegrains",
            name: "Whole grains",
            icon: "circle.grid.3x3.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Sustained energy for peak phase",
                "B vitamins support metabolism",
                "Fiber keeps you satisfied"
            ],
            howToEnjoy: [
                "Brown rice or farro bowls",
                "Whole grain toast",
                "Oatmeal for breakfast"
            ]
        ),
        PhaseTip(
            id: "ovulation_cruciferousveggies",
            name: "Cruciferous vegetables",
            icon: "leaf.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Help metabolize excess estrogen",
                "High in fiber",
                "Cancer-protective compounds"
            ],
            howToEnjoy: [
                "Roasted broccoli or cauliflower",
                "Raw in salads",
                "Steamed as sides"
            ]
        ),
        PhaseTip(
            id: "ovulation_leanprotein",
            name: "Lean protein",
            icon: "fork.knife",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Supports high energy demands",
                "Keeps blood sugar stable",
                "Muscle maintenance during active phase"
            ],
            howToEnjoy: [
                "Grilled chicken or fish",
                "Tofu stir-fry",
                "Turkey in lettuce wraps"
            ]
        ),
        PhaseTip(
            id: "ovulation_lightmeals",
            name: "Light, fresh meals",
            icon: "sun.max.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Digestion is efficient",
                "Matches high energy",
                "Won't weigh you down"
            ],
            howToEnjoy: [
                "Colorful salads",
                "Grain bowls",
                "Fresh smoothie bowls"
            ]
        ),
        PhaseTip(
            id: "ovulation_almonds",
            name: "Almonds",
            icon: "oval.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Healthy fats for hormone production",
                "Protein for sustained energy",
                "Magnesium for muscle function"
            ],
            howToEnjoy: [
                "Handful as snack",
                "Almond butter on fruit",
                "Sliced on salads"
            ]
        ),
        PhaseTip(
            id: "ovulation_waterrichfoods",
            name: "Water-rich foods",
            icon: "figure.pool.swim",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Stay hydrated during active phase",
                "Refreshing and light",
                "Support energy levels"
            ],
            howToEnjoy: [
                "Cucumbers, watermelon, celery",
                "Add to salads",
                "Blend into smoothies"
            ]
        ),
        PhaseTip(
            id: "ovulation_eggs",
            name: "Eggs",
            icon: "oval.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Complete protein for peak energy",
                "Choline supports brain function",
                "Quick and versatile"
            ],
            howToEnjoy: [
                "Veggie-packed omelettes",
                "Hard-boiled for snacks",
                "Egg salad on greens"
            ]
        ),
        PhaseTip(
            id: "ovulation_quinoa",
            name: "Quinoa",
            icon: "circle.grid.3x3.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Complete plant protein",
                "Sustained energy for active phase",
                "High in fiber"
            ],
            howToEnjoy: [
                "In power bowls",
                "As a salad base",
                "Mixed with roasted veggies"
            ]
        ),
        PhaseTip(
            id: "ovulation_citrus",
            name: "Citrus fruits",
            icon: "circle.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Vitamin C for energy",
                "Refreshing and hydrating",
                "Supports immune function"
            ],
            howToEnjoy: [
                "Fresh orange segments",
                "Lemon in water",
                "Grapefruit for breakfast"
            ]
        ),
        PhaseTip(
            id: "ovulation_chickensalad",
            name: "Chicken",
            icon: "fork.knife",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Lean protein for muscle support",
                "B vitamins for energy",
                "Light and satisfying"
            ],
            howToEnjoy: [
                "Grilled on salads",
                "In lettuce wraps",
                "With fresh vegetables"
            ]
        ),
        PhaseTip(
            id: "ovulation_spinach",
            name: "Spinach",
            icon: "leaf.fill",
            category: .eat,
            phase: .ovulation,
            whyBenefits: [
                "Iron for sustained energy",
                "Folate supports cell function",
                "Light and nutrient-dense"
            ],
            howToEnjoy: [
                "Fresh in salads",
                "Blended in smoothies",
                "Sautéed as a side"
            ]
        ),

        // Movements
        PhaseTip(
            id: "ovulation_hiit",
            name: "HIIT",
            icon: "figure.highintensity.intervaltraining",
            category: .move,
            phase: .ovulation,
            whyBenefits: [
                "Peak energy phase - go for it",
                "Testosterone peaks support power",
                "Maximum performance potential"
            ],
            howToEnjoy: [
                "Push intensity",
                "Try challenging intervals",
                "Track PRs"
            ]
        ),
        PhaseTip(
            id: "ovulation_strength",
            name: "Heavy lifting",
            icon: "figure.strengthtraining.traditional",
            category: .move,
            phase: .ovulation,
            whyBenefits: [
                "Hormones support strength gains",
                "Good time for PRs",
                "Energy is highest"
            ],
            howToEnjoy: [
                "Increase weights",
                "Focus on compound lifts",
                "Challenge yourself safely"
            ]
        ),
        PhaseTip(
            id: "ovulation_spinning",
            name: "Spinning",
            icon: "figure.indoor.cycle",
            category: .move,
            phase: .ovulation,
            whyBenefits: [
                "Cardiovascular capacity is high",
                "Can push harder",
                "Social energy matches group classes"
            ],
            howToEnjoy: [
                "High-intensity rides",
                "Climb challenges",
                "Push through sprints"
            ]
        ),
        PhaseTip(
            id: "ovulation_groupfitness",
            name: "Group fitness",
            icon: "person.3.fill",
            category: .move,
            phase: .ovulation,
            whyBenefits: [
                "Social energy is high",
                "Motivation from others",
                "Fun atmosphere"
            ],
            howToEnjoy: [
                "Try a dance class",
                "Join bootcamp",
                "Partner workouts"
            ]
        ),
        PhaseTip(
            id: "ovulation_powerworkouts",
            name: "Power workouts",
            icon: "bolt.fill",
            category: .move,
            phase: .ovulation,
            whyBenefits: [
                "Explosive movements feel easier",
                "Coordination is sharpest",
                "Ideal for athletic training"
            ],
            howToEnjoy: [
                "Box jumps, sprints",
                "Plyometrics",
                "Sports practice"
            ]
        ),
        PhaseTip(
            id: "ovulation_running",
            name: "Speed runs",
            icon: "figure.run",
            category: .move,
            phase: .ovulation,
            whyBenefits: [
                "Speed and endurance peak",
                "Good time for race training",
                "Recovery is efficient"
            ],
            howToEnjoy: [
                "Tempo runs",
                "Interval training",
                "Time trials"
            ]
        )
    ]

    // MARK: - Luteal Phase Tips (Days 17-28)
    static let lutealTips: [PhaseTip] = [
        // Foods
        PhaseTip(
            id: "luteal_sweetpotato",
            name: "Sweet potato",
            icon: "oval.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Complex carbs support serotonin production",
                "Vitamin A for hormone balance",
                "Satisfies carb cravings healthily"
            ],
            howToEnjoy: [
                "Baked with cinnamon",
                "Mashed as a side",
                "Cubed in bowls"
            ]
        ),
        PhaseTip(
            id: "luteal_darkcholoate",
            name: "Dark chocolate",
            icon: "cup.and.saucer.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Magnesium may help with PMS",
                "Satisfies cravings mindfully",
                "Mood-boosting compounds"
            ],
            howToEnjoy: [
                "Small serving after dinner",
                "In trail mix",
                "Melted over fruit"
            ]
        ),
        PhaseTip(
            id: "luteal_complexpcarbs",
            name: "Complex carbs",
            icon: "circle.grid.3x3.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Support serotonin production",
                "Help manage cravings",
                "Sustained energy"
            ],
            howToEnjoy: [
                "Whole grain pasta",
                "Brown rice dishes",
                "Oatmeal with toppings"
            ]
        ),
        PhaseTip(
            id: "luteal_magnesiumfoods",
            name: "Magnesium-rich foods",
            icon: "sparkles",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "May reduce PMS symptoms",
                "Supports muscle relaxation",
                "Helps with sleep"
            ],
            howToEnjoy: [
                "Pumpkin seeds as snacks",
                "Dark leafy greens",
                "Almonds and cashews"
            ]
        ),
        PhaseTip(
            id: "luteal_turkey",
            name: "Turkey",
            icon: "bird.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Tryptophan supports serotonin",
                "Lean protein for stability",
                "B vitamins for mood"
            ],
            howToEnjoy: [
                "Ground turkey in bowls",
                "Turkey lettuce wraps",
                "Roasted turkey breast"
            ]
        ),
        PhaseTip(
            id: "luteal_rootveggies",
            name: "Root vegetables",
            icon: "carrot.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Grounding and satisfying",
                "Complex carbs for energy",
                "Warming and comforting"
            ],
            howToEnjoy: [
                "Roasted carrots and parsnips",
                "Root veggie soup",
                "Mashed root vegetables"
            ]
        ),
        PhaseTip(
            id: "luteal_warmingspices",
            name: "Warming spices",
            icon: "flame.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Anti-inflammatory properties",
                "Support digestion",
                "Comforting flavors"
            ],
            howToEnjoy: [
                "Turmeric in golden milk",
                "Cinnamon in oatmeal",
                "Ginger in teas"
            ]
        ),
        PhaseTip(
            id: "luteal_healthyfats",
            name: "Healthy fats",
            icon: "figure.pool.swim",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Support hormone production",
                "Keep you satisfied longer",
                "Help absorb fat-soluble vitamins"
            ],
            howToEnjoy: [
                "Avocado on everything",
                "Olive oil dressings",
                "Nut butters as snacks"
            ]
        ),
        PhaseTip(
            id: "luteal_oats",
            name: "Oats",
            icon: "circle.grid.3x3.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Complex carbs support serotonin",
                "Fiber stabilizes blood sugar",
                "Warming and comforting"
            ],
            howToEnjoy: [
                "Overnight oats",
                "Warm porridge with toppings",
                "In baked goods"
            ]
        ),
        PhaseTip(
            id: "luteal_salmon",
            name: "Salmon",
            icon: "fish.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Omega-3s may reduce PMS symptoms",
                "Protein keeps you satisfied",
                "Vitamin D supports mood"
            ],
            howToEnjoy: [
                "Baked with herbs",
                "In warming bowls",
                "With roasted vegetables"
            ]
        ),
        PhaseTip(
            id: "luteal_bananas",
            name: "Bananas",
            icon: "moon.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Potassium reduces bloating",
                "Vitamin B6 supports mood",
                "Natural sweetness for cravings"
            ],
            howToEnjoy: [
                "In smoothies",
                "Sliced on oatmeal",
                "Frozen as nice cream"
            ]
        ),
        PhaseTip(
            id: "luteal_eggs",
            name: "Eggs",
            icon: "oval.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Choline supports mood",
                "Protein for stable energy",
                "Versatile comfort food"
            ],
            howToEnjoy: [
                "Scrambled with veggies",
                "Baked in dishes",
                "As egg muffins for meal prep"
            ]
        ),
        PhaseTip(
            id: "luteal_chickpeas",
            name: "Chickpeas",
            icon: "circle.grid.2x2.fill",
            category: .eat,
            phase: .luteal,
            whyBenefits: [
                "Fiber for digestive support",
                "Plant protein and iron",
                "B6 for mood regulation"
            ],
            howToEnjoy: [
                "Roasted for snacking",
                "In warming curries",
                "Blended as hummus"
            ]
        ),

        // Movements
        PhaseTip(
            id: "luteal_pilates",
            name: "Pilates",
            icon: "figure.pilates",
            category: .move,
            phase: .luteal,
            whyBenefits: [
                "Controlled movements match energy",
                "Core strength without strain",
                "Mind-body connection"
            ],
            howToEnjoy: [
                "Mat or reformer classes",
                "Focus on breath and form",
                "Moderate intensity"
            ]
        ),
        PhaseTip(
            id: "luteal_yoga",
            name: "Yoga flow",
            icon: "figure.yoga",
            category: .move,
            phase: .luteal,
            whyBenefits: [
                "Balances energy as it dips",
                "Reduces stress and anxiety",
                "Supports flexibility"
            ],
            howToEnjoy: [
                "Vinyasa or hatha classes",
                "Focus on hip openers",
                "Include restorative poses"
            ]
        ),
        PhaseTip(
            id: "luteal_walking",
            name: "Walking",
            icon: "figure.walk",
            category: .move,
            phase: .luteal,
            whyBenefits: [
                "Gentle as energy decreases",
                "Reduces bloating",
                "Mood-boosting"
            ],
            howToEnjoy: [
                "30-45 minute walks",
                "Listen to podcasts",
                "Walk in nature"
            ]
        ),
        PhaseTip(
            id: "luteal_moderatestrength",
            name: "Moderate strength",
            icon: "figure.strengthtraining.traditional",
            category: .move,
            phase: .luteal,
            whyBenefits: [
                "Maintain strength without overexertion",
                "Focus on form over weight",
                "Supports metabolism"
            ],
            howToEnjoy: [
                "Lighter weights, more reps",
                "Bodyweight exercises",
                "Resistance bands"
            ]
        ),
        PhaseTip(
            id: "luteal_swimming",
            name: "Swimming",
            icon: "figure.pool.swim",
            category: .move,
            phase: .luteal,
            whyBenefits: [
                "Low impact on joints",
                "Water soothes bloating",
                "Full body without strain"
            ],
            howToEnjoy: [
                "Easy laps",
                "Water aerobics",
                "Focus on how it feels"
            ]
        ),
        PhaseTip(
            id: "luteal_stretching",
            name: "Deep stretching",
            icon: "figure.cooldown",
            category: .move,
            phase: .luteal,
            whyBenefits: [
                "Releases tension",
                "Supports relaxation",
                "Prepares body for menstrual phase"
            ],
            howToEnjoy: [
                "Foam rolling",
                "Static stretches",
                "Focus on tight areas"
            ]
        )
    ]
}
