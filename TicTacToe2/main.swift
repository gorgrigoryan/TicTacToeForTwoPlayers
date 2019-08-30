//
//  main.swift
//  TicTacToe2
//
//  Created by 1 on 8/28/19.
//  Copyright © 2019 Gor Grigoryan. All rights reserved.
//

protocol Game {
    var name: String { get }
    var state: String { get }
}

protocol GameTracking {
    func gameDidStart(_ game: Game)
    func gameDidUpdateState(_ game: Game)
    func gameDidEnd(_ game: Game)
}

struct Tracker: GameTracking {
    func gameDidStart(_ game: Game) {
        print("\(game.name) did start!")
    }
    
    func gameDidUpdateState(_ game: Game) {
        print("Game did update:\n\(game.state)")
    }
    
    func gameDidEnd(_ game: Game) {
        print("\(game.name) did end")
    }
}

enum BoardType: Int {
    case small = 3
    case middle = 5
    case large = 7
}

enum Player: Character {
    case playX = "x"
    case playO = "o"
}

struct MatrixIndex: Hashable {
    let row: Int
    let column: Int
    
    init(_ row: Int, _ column: Int) {
        self.row = row
        self.column = column
    }
    
    func onMainDiagonal() -> Bool {
        return row == column
    }
    
    func onCounterDiagonal(_ matrixSize: Int) -> Bool {
        return row == matrixSize - 1 - column
    }
}

struct Matrix {
    
    let boardSize: Int
    let boardType: BoardType
    var board: [Character]
    
    init(_ type: BoardType) {
        self.boardType = type
        boardSize = type.rawValue
        board = Array(repeating: " ", count: boardSize * boardSize)
    }
    
    subscript(index: MatrixIndex) -> Character {
        set {
            board[index.row * boardSize + index.column] = newValue
        }
        get {
            return board[index.row * boardSize + index.column]
        }
    }
    
    subscript(row: Int, column: Int) -> Character {
        set {
            board[row * boardSize + column] = newValue
        }
        get {
            return board[row * boardSize + column]
        }
    }
}

struct TicTacToe {
    var matrix: Matrix
    var isXWinner: Bool?
    var tracker: GameTracking?

    private var player = Player.playX
    private var lastStep: MatrixIndex?
    private var completedStepsCount = 0
    
    init(_ boardType: BoardType, _ tracker: GameTracking? = nil) {
        matrix = Matrix(boardType)
        self.tracker = tracker
        self.tracker?.gameDidStart(self)
    }
    
    mutating func step() {
        let playerStep = readPlayerStep()
        guard let step = playerStep else {
            return
        }
        
        let rowIdxCond = (step.row >= 0) && (step.row < matrix.boardSize)
        guard rowIdxCond else {
            print("Try again.")
            return
        }
        
        let colIdxCond = (step.col >= 0) && (step.col < matrix.boardSize)
        guard colIdxCond else {
            print("Try again.")
            return
        }
        
        guard matrix[step.row, step.col] == " " else {
            print("Try again.")
            return
        }
        
        completedStepsCount += 1
        matrix[step.row, step.col] = player.rawValue
        player = (player == .playX) ? .playO : .playX
        lastStep = MatrixIndex(step.row, step.col)
        tracker?.gameDidUpdateState(self)
    }
    
    private func readPlayerStep() -> (row: Int, col: Int)? {
        var input: String?
        repeat {
            print("Input comma-separated matrix dimensions (w, h): ", terminator: "")
            input = readLine(strippingNewline: true)
            if let input = input, let size = parsePlayerStep(from: input) {
                return size
            }
            print("Please try again.")
        } while input != nil
        
        return nil
    }
    
    private func parsePlayerStep(from str: String) -> (Int, Int)? {
        let components = str.filter { !$0.isWhitespace }.split(separator: ",")
        guard components.count >= 2, let width = Int(components[0]), let height = Int(components[1]) else {
            return nil
        }
        return (width, height)
    }
    
    private func checkRowOnEqualValues(_ row: Int) -> Bool {
        for colInd in 0 ..< matrix.boardSize - 1 {
            if matrix[row, colInd] != matrix[row, colInd + 1] {
                return false
            }
        }
        return true
    }
    
    private func checkColumnOnEqualValues(_ col: Int) -> Bool {
        for rowInd in 0 ..< matrix.boardSize - 1 {
            if matrix[rowInd, col] != matrix[rowInd + 1, col] {
                return false
            }
        }
        return true
    }
    
    private func CheckMainDiagonalOnEqualValues() -> Bool {
        for idx in 0 ..< matrix.boardSize - 1 {
            if matrix[idx, idx] != matrix[idx + 1, idx + 1] {
                return false
            }
        }
        return true
    }
    
    private func CheckCounterDiagonalOnEqualValues() -> Bool {
        for idx in 0 ..< matrix.boardSize - 1 {
            if matrix[idx, matrix.boardSize - 1 - idx] != matrix[idx + 1, matrix.boardSize - 2 - idx] {
                return false
            }
        }
        return true
    }
    
    mutating func checkEnd() -> Bool {
        guard let step = lastStep else {
            return false
        }
        
        var isEnd = checkRowOnEqualValues(step.row)
        
        if !isEnd {
            isEnd = checkColumnOnEqualValues(step.column)
        } else {
            isXWinner = (matrix[step] == "x") ? true : false
            return true
        }
        
        if isEnd {
            isXWinner = (matrix[step] == "x") ? true : false
            return true
        }
        
        // check step situation on diagonal or counter-diagonal
        let onMainDiagonal = step.onMainDiagonal()
        let onCounterDiagonal = step.onCounterDiagonal(matrix.boardSize)
        
        let drawSituation = (completedStepsCount == matrix.board.count)
        if !onMainDiagonal || !onCounterDiagonal {
            return (isEnd || drawSituation)
        }
        
        if onMainDiagonal {
            isEnd = CheckMainDiagonalOnEqualValues()
        }
        
        if isEnd {
            isXWinner = (matrix[step] == "x") ? true : false
            return true
        }
        
        if onCounterDiagonal {
            isEnd = CheckCounterDiagonalOnEqualValues()
        }
        
        if isEnd {
            isXWinner = (matrix[step] == "x") ? true : false
            return true
        }
        
        return (isEnd || drawSituation)
    }
}

extension TicTacToe: Game {
    var name: String {
        return "TicTacToe"
    }
    
    var state: String {
        var numberArray = ["  "]
        for i in 0 ..< matrix.boardSize {
            numberArray.append("  " + String(i) + " ")
        }
        let numberLine = numberArray.joined()
        let firstLine = "  ┏━━━" + String(repeating: "┳━━━", count: matrix.boardSize - 1) + "┓"
        let verticalSeparatingLine = "  ┣━━━" + String(repeating: "╋━━━", count: matrix.boardSize - 1) + "┫"
        let lastLine = "  ┗━━━" + String(repeating: "┻━━━", count: matrix.boardSize - 1) + "┛"
        
        var lines = [numberLine, firstLine]
        
        for i in 0 ..< matrix.boardSize {
            var line = String(i) + " "
            for j in 0 ..< matrix.boardSize {
                line += "┃ " + String(matrix[MatrixIndex(i, j)]) + String(" ")
            }
            line += "┃"
            lines += [line]
            if i != matrix.boardSize - 1 {
                lines += [verticalSeparatingLine]
            }
        }
        
        lines += [lastLine]
        return lines.joined(separator: "\n")
    }
}

// MARK: - User Input
func readUsername() -> String? {
    var input: String?
    repeat {
        print("Input your name 👉: ", terminator: "")
        input = readLine(strippingNewline: true)
    } while input != nil && input!.isEmpty
    
    return input
}

func readBoardType() -> String? {
    var input: String?
    repeat {
        print("Please select type of board for TicTacToe")
        print("(input \"small\", \"middle\" or \"large\", another input is \"small\") 👉: ", terminator: "")
        input = readLine(strippingNewline: true)
    } while input != nil && input!.isEmpty
    
    return input
}

var welcomed = false
var greetedPlayer1 = false
var greetedPlayer2 = false
var boardInitialized = false

var game: TicTacToe = TicTacToe(.small, Tracker())

gameLoop: while true {
    if !welcomed {
        print("Welcome to TicTacToe!")
        welcomed = true
    }
    
    if !greetedPlayer1 {
        guard let username = readUsername() else {
            print("\nGoodbye stranger...")
            break gameLoop
        }
        print("Hi \(username)!")
        greetedPlayer1 = true
    }
    
    if !greetedPlayer2 {
        guard let username = readUsername() else {
            print("\nGoodbye stranger...")
            break gameLoop
        }
        print("Hi \(username)!")
        greetedPlayer2 = true
    }
    
    if !boardInitialized {
        guard let type = readBoardType() else {
            break gameLoop
        }
        switch type {
        case "middle":
            print("Selected 5x5 board")
            game = TicTacToe(.middle, Tracker())
        case "large":
            print("Selected 7x7 board")
            game = TicTacToe(.large, Tracker())
        default:
            print("Selected 3x3 board")
        }
        
        boardInitialized = true
        print(game.state)
    }
    
    game.step()
    
    if game.checkEnd() {
        break gameLoop
    }
}

switch game.isXWinner {
case .some(let x):
    if x {
        print("The winner is X")
    } else {
        print("The winner is O")
    }
case nil:
    print("Draw")
}
