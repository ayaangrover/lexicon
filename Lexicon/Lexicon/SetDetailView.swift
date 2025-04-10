// File: SetDetailView.swift
import SwiftUI

struct SetDetailView: View {
    var set: FlashcardSet
    @State private var currentIndex: Int = 0
    @State private var showEditView = false
    @State private var showLearnView = false
    @State private var showTestView = false  // New state variable

    var body: some View {
        VStack {
            if !set.cards.isEmpty {
                ZStack {
                    FlashcardView(card: set.cards[currentIndex])
                        .padding()
                        .id(currentIndex)
                        .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                  removal: .move(edge: .leading)))
                }
                .animation(.easeInOut, value: currentIndex)

                HStack {
                    Button(action: {
                        if currentIndex > 0 {
                            withAnimation { currentIndex -= 1 }
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.largeTitle)
                    }
                    .padding()

                    Spacer()

                    Text("\(currentIndex + 1)/\(set.cards.count)")
                        .font(.headline)

                    Spacer()

                    Button(action: {
                        if currentIndex < set.cards.count - 1 {
                            withAnimation { currentIndex += 1 }
                        }
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.largeTitle)
                    }
                    .padding()
                }
                .padding(.horizontal)
            } else {
                Text("No flashcards available")
            }
            Spacer()
        }
        .navigationTitle(set.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Edit Cards") {
                        showEditView = true
                    }
                    Button(action: {
                        showLearnView = true
                    }) {
                        HStack {
                            Image(systemName: "q.circle")
                            Text("Learn")
                        }
                        .padding(8)
                        .background(Color.purple.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    Button("Test") {   // New Test button
                        showTestView = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            EditSetView(set: set)
        }
        .sheet(isPresented: $showLearnView) {
            LearnView(set: set)
        }
        .sheet(isPresented: $showTestView) {  // Present TestView
            TestView(set: set)
        }
    }
}
