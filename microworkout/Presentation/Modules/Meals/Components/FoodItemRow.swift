//
//  FoodItemRow.swift
//  microworkout
//

import SwiftUI

struct FoodItemRow: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            FoodThumbnail(imageUrl: item.imageUrl, size: 40)

            // Name and quantity
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .lineLimit(1)
                Text(item.formattedQuantity)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Calories
            Text("\(Int(item.actualNutrition.calories)) kcal")
                .font(.subheadline)
                .foregroundColor(.orange)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Editable Food Item Row

struct EditableFoodItemRow: View {
    @Binding var item: FoodItem
    let onDelete: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Product Image
                FoodThumbnail(imageUrl: item.imageUrl, size: 50)

                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(2)

                    // Nutrition badges
                    HStack(spacing: 6) {
                        NutritionBadge(value: item.actualNutrition.calories, unit: "kcal", color: .orange)
                        NutritionBadge(value: item.actualNutrition.proteins, unit: "P", color: .red)
                        NutritionBadge(value: item.actualNutrition.carbohydrates, unit: "C", color: .blue)
                    }
                }

                Spacer()

                // Delete button
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(8)
                }
            }

            // Quantity input
            VStack(spacing: 8) {
                HStack {
                    Text("Cantidad:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    HStack(spacing: 4) {
                        TextField("100", value: $item.quantity, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)

                        Text("g")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach([50, 100, 150, 200, 300], id: \.self) { preset in
                            Button(action: { item.quantity = Double(preset) }) {
                                Text("\(preset)g")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Int(item.quantity) == preset ? Color.blue : Color(.systemGray5))
                                    .foregroundColor(Int(item.quantity) == preset ? .white : .primary)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

// MARK: - Supporting Views

struct FoodThumbnail: View {
    let imageUrl: String?
    let size: CGFloat

    var body: some View {
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
                default:
                    FoodPlaceholder(size: size)
                }
            }
        } else {
            FoodPlaceholder(size: size)
        }
    }
}

struct FoodPlaceholder: View {
    let size: CGFloat

    var body: some View {
        Image(systemName: "leaf.fill")
            .foregroundColor(.green)
            .frame(width: size, height: size)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: size * 0.15))
    }
}

struct NutritionBadge: View {
    let value: Double
    let unit: String
    let color: Color

    var body: some View {
        Text("\(Int(value))\(unit)")
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(4)
    }
}

#Preview {
    VStack(spacing: 16) {
        FoodItemRow(item: FoodItem(
            name: "Manzana Fuji",
            nutritionPer100g: NutritionInfo(calories: 52, carbohydrates: 14, proteins: 0.3, fats: 0.2),
            quantity: 150
        ))
        .padding()

        EditableFoodItemRow(
            item: .constant(FoodItem(
                name: "Pechuga de pollo",
                nutritionPer100g: NutritionInfo(calories: 165, carbohydrates: 0, proteins: 31, fats: 3.6),
                quantity: 200
            )),
            onDelete: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
