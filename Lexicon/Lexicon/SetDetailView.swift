
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct SetDetailView: View {
    var set: FlashcardSet
    @State private var currentIndex: Int = 0
    @State private var showEditView = false
    @State private var showLearnView = false
    @State private var showTestView = false
    @State private var showShareView = false
    @State private var flashcardTransition: AnyTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
    
    var body: some View {
        VStack {
            if !set.cards.isEmpty {
                ZStack {
                    FlashcardView(card: set.cards[currentIndex])
                        .padding()
                        .id(currentIndex)
                        .transition(flashcardTransition)
                }
                .animation(.easeInOut, value: currentIndex)
                
                HStack {
                    Button(action: {
                        if currentIndex > 0 {
                            flashcardTransition = .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
                            withAnimation {
                                currentIndex -= 1
                            }
                        }
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.largeTitle)
                            .foregroundColor(Color.appIcon)
                    }
                    .padding()

                    Spacer()

                    Text("\(currentIndex + 1)/\(set.cards.count)")
                        .font(.headline)
                        .foregroundColor(Color.appText)

                    Spacer()

                    Button(action: {
                        if currentIndex < set.cards.count - 1 {
                            flashcardTransition = .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
                            withAnimation {
                                currentIndex += 1
                            }
                        }
                    }) {
                        Image(systemName: "arrow.right")
                            .font(.largeTitle)
                            .foregroundColor(Color.appIcon)
                    }
                    .padding()
                }
                .padding(.horizontal)
            } else {
                Text("No flashcards available")
                    .foregroundColor(Color.appText)
            }
            Spacer()
        }
        .navigationTitle(set.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button("Edit") {
                        showEditView = true
                    }
                    .foregroundStyle(Color(red: 63/255, green: 183/255, blue: 154/255))
                    Button(action: { showLearnView = true }) {
                        HStack {
                            Text("Learn")
                        }
                        .padding(8)
                        .foregroundStyle(Color(red: 63/255, green: 183/255, blue: 154/255))
                        .cornerRadius(8)
                    }
                    Button("Test") {
                        showTestView = true
                    }
                    .foregroundStyle(Color(red: 63/255, green: 183/255, blue: 154/255))

                    Button(action: {
                        showShareView = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(Color(red: 63/255, green: 183/255, blue: 154/255))


                }
            }
        }
        .sheet(isPresented: $showEditView) {
            EditSetView(set: set)
        }
        .sheet(isPresented: $showLearnView) {
            LearnView(set: set)
        }
        .sheet(isPresented: $showTestView) {
            TestView(set: set)
        }
        .sheet(isPresented: $showShareView) {
            ShareSetView(set: set)
        }
    }
}
