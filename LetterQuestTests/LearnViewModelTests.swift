import Testing
import Foundation
import RxSwift
@testable import LetterQuest

// MARK: - Helpers

private final class MockLetterRepository: LetterRepositoryProtocol {

    let letters: [Letter]

    init(letters: [Letter] = Letter.alphabet) {
        self.letters = letters
    }

    func fetchAll() -> Single<[Letter]> {
        .just(letters)
    }

    func fetch(by id: UUID) -> Single<Letter?> {
        .just(letters.first { $0.id == id })
    }

    func fetchNext(after id: UUID) -> Single<Letter?> {
        guard let idx = letters.firstIndex(where: { $0.id == id }),
              idx + 1 < letters.count else { return .just(nil) }
        return .just(letters[idx + 1])
    }
}

// MARK: - Letter loading

struct LearnViewModelLetterTests {

    @Test("letter is populated after init")
    func letterIsPopulatedAfterInit() {
        let target = Letter.alphabet.first { $0.character == "B" }!
        let vm     = LearnViewModel(letterId: target.id,
                                    letterRepository: MockLetterRepository(),
                                    router: AppRouter())
        // Drain the main queue so the MainScheduler-dispatched onNext fires.
        DispatchQueue.main.sync {}
        #expect(vm.letter?.id == target.id)
        #expect(vm.letter?.character == "B")
    }

    @Test("letter is nil when id is unknown")
    func letterIsNilForUnknownId() {
        let vm = LearnViewModel(letterId: UUID(),
                                letterRepository: MockLetterRepository(),
                                router: AppRouter())
        DispatchQueue.main.sync {}
        #expect(vm.letter == nil)
    }
}

// MARK: - Replay token

struct LearnViewModelReplayTests {

    @Test("play() changes replayToken")
    func playChangesReplayToken() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let vm     = LearnViewModel(letterId: letter.id,
                                    letterRepository: MockLetterRepository(),
                                    router: AppRouter())
        let before = vm.replayToken
        vm.play()
        #expect(vm.replayToken != before)
    }

    @Test("each play() call produces a distinct token")
    func eachPlayProducesDistinctToken() {
        let letter = Letter.alphabet.first { $0.character == "A" }!
        let vm     = LearnViewModel(letterId: letter.id,
                                    letterRepository: MockLetterRepository(),
                                    router: AppRouter())
        let first  = vm.replayToken
        vm.play()
        let second = vm.replayToken
        vm.play()
        let third  = vm.replayToken
        #expect(first != second)
        #expect(second != third)
    }
}

// MARK: - Navigation

struct LearnViewModelNavigationTests {

    @Test("navigateToPractice pushes one route onto the stack")
    func navigateToPracticePushesRoute() {
        let letter = Letter.alphabet.first { $0.character == "C" }!
        let router = AppRouter()
        let vm     = LearnViewModel(letterId: letter.id,
                                    letterRepository: MockLetterRepository(),
                                    router: router)
        #expect(router.path.count == 0)
        vm.navigateToPractice()
        // Drain the main queue so the relay's MainScheduler dispatch fires.
        DispatchQueue.main.sync {}
        #expect(router.path.count == 1)
    }
}
