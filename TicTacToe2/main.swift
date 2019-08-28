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
    var lastStep: MatrixIndex?
    var tracker: GameTracking?
    var player = Player.playX
    
    init(_ boardType: BoardType, _ tracker: GameTracking? = nil) {
        matrix = Matrix(boardType)
        self.tracker = tracker
        self.tracker?.gameDidStart(self)
    }
    
    mutating func stepPlayerX(_ matrIdx: MatrixIndex) {
        print("\nStep of player X")
        matrix[matrIdx] = "x"
        lastStep = matrIdx
        tracker?.gameDidUpdateState(self)
    }
    
    mutating func stepPlayerO(_ matrIdx: MatrixIndex) {
        print("Step of player O")
        matrix[matrIdx] = "o"
    }
    
    mutating func step() {
        let step = readPlayerStep()
        matrix[step!.row, step!.col] = player.rawValue
        player = (player == .playX) ? .playO : .playX
        lastStep = MatrixIndex(step!.row, step!.col)
        tracker?.gameDidUpdateState(self)
    }
    
    func readPlayerStep() -> (row: Int, col: Int)? {
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
    
    func parsePlayerStep(from str: String) -> (Int, Int)? {
        let components = str.filter { !$0.isWhitespace }.split(separator: ",")
        guard components.count >= 2, let width = Int(components[0]), let height = Int(components[1]) else {
            return nil
        }
        return (width, height)
    }
    
    func checkRowOnEqualValues(_ step: MatrixIndex) -> Bool {
        for colInd in 0 ..< matrix.boardSize - 1 {
            if matrix[step.row, colInd] != matrix[step.row, colInd + 1] {
                return false
            }
        }
        return true
    }
    
    func checkColumnOnEqualValues(_ step: MatrixIndex) -> Bool {
        for rowInd in 0 ..< matrix.boardSize - 1 {
            if matrix[rowInd, step.column] != matrix[rowInd + 1, step.column] {
                return false
            }
        }
        return true
    }
    
    func CheckMainDiagonalOnEqualValues() -> Bool {
        for idx in 0 ..< matrix.boardSize - 1 {
            if matrix[idx, idx] != matrix[idx + 1, idx + 1] {
                return false
            }
        }
        return true
    }
    
    func CheckCounterDiagonalOnEqualValues() -> Bool {
        for idx in 0 ..< matrix.boardSize - 1 {
            if (matrix[idx, matrix.boardSize - 1 - idx] != matrix[idx + 1, matrix.boardSize - 2 - idx]) {
                return false
            }
        }
        return true
    }
    
    mutating func checkEnd() -> Bool {
        guard let step = lastStep else {
            return false
        }
        
        var isEnd = checkRowOnEqualValues(step)
        
        if !isEnd {
            isEnd = checkColumnOnEqualValues(step)
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
        
        if !onMainDiagonal || !onCounterDiagonal {
            return isEnd
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
        
        return isEnd
    }
}

extension TicTacToe: Game {
    var name: String {
        return "TicTacToe"
    }
    
    var state: String {
        let firstLine = "┏━━━" + String(repeating: "┳━━━", count: matrix.boardSize - 1) + "┓"
        let verticalSeparatingLine = "┣━━━" + String(repeating: "╋━━━", count: matrix.boardSize - 1) + "┫"
        let lastLine = "┗━━━" + String(repeating: "┻━━━", count: matrix.boardSize - 1) + "┛"
        
        var lines = [firstLine]
        
        for i in 0 ..< matrix.boardSize {
            var line = ""
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
        print("(input \"small\", \"middle\" or \"large\") 👉: ", terminator: "")
        input = readLine(strippingNewline: true)
    } while input != nil && input!.isEmpty
    
    return input
}








var welcomed = false
var greetedPlayer1 = false
var greetedPlayer2 = false
var boardInitialized = false

var game: TicTacToe

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
        case "small":
            boardInitialized = true
            game = TicTacToe(.small, Tracker())
        case "middle":
            boardInitialized = true
            game = TicTacToe(.middle, Tracker())
        case "large":
            boardInitialized = true
            game = TicTacToe(.large, Tracker())
        default:
            print("\nPlease try again.")
            break gameLoop
        }
    }
    
    // game process
}
