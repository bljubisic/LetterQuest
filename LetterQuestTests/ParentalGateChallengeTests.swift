import Testing
@testable import LetterQuest

struct ParentalGateChallengeTests {

    private let challenge = ParentalGateChallenge(firstFactor: 7, secondFactor: 8)

    @Test("answer is the product of the two factors")
    func answerIsProduct() {
        #expect(challenge.answer == 56)
    }

    @Test("prompt shows both factors")
    func promptShowsFactors() {
        #expect(challenge.prompt.contains("7"))
        #expect(challenge.prompt.contains("8"))
    }

    @Test("isCorrect accepts the exact answer")
    func isCorrectAcceptsExactAnswer() {
        #expect(challenge.isCorrect("56") == true)
    }

    @Test("isCorrect tolerates surrounding whitespace")
    func isCorrectToleratesWhitespace() {
        #expect(challenge.isCorrect("  56  ") == true)
    }

    @Test("isCorrect rejects a wrong number")
    func isCorrectRejectsWrongNumber() {
        #expect(challenge.isCorrect("55") == false)
    }

    @Test("isCorrect rejects non-numeric input instead of crashing")
    func isCorrectRejectsNonNumericInput() {
        #expect(challenge.isCorrect("fifty-six") == false)
        #expect(challenge.isCorrect("") == false)
    }

    @Test("random() draws both factors from 6...9")
    func randomFactorsAreInExpectedRange() {
        for _ in 0..<100 {
            let generated = ParentalGateChallenge.random()
            #expect((6...9).contains(generated.firstFactor))
            #expect((6...9).contains(generated.secondFactor))
        }
    }
}
