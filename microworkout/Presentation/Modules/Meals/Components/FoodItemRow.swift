//
//  FoodItemRow.swift
//  microworkout
//

import SwiftUI

struct FoodItemRow: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            // Product Image (placeholder if no image)
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 40, height: 40)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    case .failure:
                        Image(systemName: "photo")
                            .frame(width: 40, height: 40)
                            .foregroundColor(.secondary)
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "leaf.fill")
                    .frame(width: 40, height: 40)
                    .foregroundColor(.green)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

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
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Editable Food Item Row (for AddMealView)

struct EditableFoodItemRow: View {
    @Binding var item: FoodItem
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            if let imageUrl = item.imageUrl, let url = URL(string: imageUrl) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 50, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    default:
                        Image(systemName: "photo")
                            .frame(width: 50, height: 50)
                            .foregroundColor(.secondary)
                    }
                }
            } else {
                Image(systemName: "leaf.fill")
                    .frame(width: 50, height: 50)
                    .foregroundColor(.green)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Name and nutrition
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("\(Int(item.actualNutrition.calories)) kcal")
                    Text("P: \(Int(item.actualNutrition.proteins))g")
                    Text("C: \(Int(item.actualNutrition.carbohydrates))g")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            // Quantity controls
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    Button(action: {
                        if item.quantity > 10 {
                            item.quantity -= 10
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .foregroundColor(.blue)
                    }

                    Text("\(Int(item.quantity))g")
                        .font(.subheadline)
                        .frame(minWidth: 50)

                    Button(action: {
                        item.quantity += 10
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.blue)
                    }
                }

                Button(action: onDelete) {
                    Text("Eliminar")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    VStack {
        FoodItemRow(item: FoodItem(
            name: "Manzana",
            nutritionPer100g: NutritionInfo(calories: 52, carbohydrates: 14, proteins: 0.3, fats: 0.2),
            quantity: 150
        ))
        .padding()
    }
}
