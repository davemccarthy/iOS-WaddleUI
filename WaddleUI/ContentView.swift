//
//  ContentView.swift
//  WaddleUI
//
//  Created by David McCarthy on 22/03/2022.
//
import SwiftUI

let keyWidth:CGFloat = min(UIScreen.main.bounds.width / 12,50)
let letterWidth:CGFloat = UIScreen.main.bounds.height / 14

//  Letter status
enum LetterStatus:Int, Comparable {
    
    case STS_PENDING, STS_OUTCAST, STS_ILLPOSITIONED, STS_POSITIONED
    
    // Implement Comparable
    public static func < (a: LetterStatus, b: LetterStatus) -> Bool {
        return a.rawValue < b.rawValue
    }
}

//  Individual grid letter entry
struct GridEntry: Identifiable {
    
    var id:UUID = UUID()
    var value:String = ""
    var disabled = true
    
    var foreground:Color = .black
    var background:Color = .white
    var border:Color = .gray
}

//  Five letter row
struct GridRow: Identifiable {
    
    let id = UUID()
    var disabled = true
    
    var entries: [GridEntry] = [GridEntry(),GridEntry(),GridEntry(),GridEntry(),GridEntry()]
}

//  Matrix 5x6 letter entries
class Grid: ObservableObject {
    
    @Published var rows:[GridRow] = [GridRow(),GridRow(),GridRow(),GridRow(),GridRow(),GridRow()]
}

//  Individual keyboard key
struct Key: Identifiable {

    let id = UUID()
    var value:String
    
    var foreground:Color = .black
    var background:Color = .white
    
    var status:LetterStatus = .STS_PENDING
    var width:CGFloat
    
    init(value:String){
        self.value = value
        self.width = (value=="⏎" || value=="⌫" ? keyWidth * 1.5 : keyWidth)
    }
}

//  Row of keys
struct KeyRow: Identifiable {
    
    let id = UUID()
    var keys:[Key] = []
    
    init(values:String){
        
        for value in values {
            
            keys.append(Key(value: String(value)))
        }
    }
}

//  Interactive custom keyboard
class Keyboard: ObservableObject {

    @Published var rows:[KeyRow] = [
        
        KeyRow(values: "QWERTYUIOP"),
        KeyRow(values: "ASDFGHJKL"),
        KeyRow(values: "⏎ZXCVBNM⌫")
    ]
}

//  Header title/value subview
struct HeaderView: View {
    
    var title: String
    @Binding var value: Int
    
    var body: some View {
        
        Spacer()
        
        VStack {
            
            Text(title).font(.caption)
            Text(String(value)).font(.title)
                .transition(AnyTransition.opacity.animation(.easeInOut(duration:2)))
                .id(String(value))
        }
        
        Spacer()
    }
}

//  Game control
class Gamer {
    
    var answer: String = ""
    var over = false
    
    var cursorX = 0
    var cursorY = 0
}

//  Game UI
struct ContentView: View {
    
    @StateObject var dictionary = Dictionary()
    @StateObject var grid = Grid()
    @StateObject var keyboard = Keyboard()
    
    @State var streak: Int = 0
    @State var record: Int = 0
    @State var points: Int = 0
    
    @State var fontNorm:Font = .headline
    @State var fontBig:Font = .title
    @State var message = ""
    
    var game = Gamer()
    
    var praises:[[String]] = [
        
        ["INCREDULOUS","FANTASTIC"],
        ["WOW","STUPENDOUS","EXCEPTIONAL"],
        ["EXCELLENT","SUPERB","WONDERFUL"],
        ["WELL DONE"],
        ["CORRECT"],
        ["CORRECT (PHEW)"]
    ]
    
    //  SCREEN BLUEPRINT
    var body: some View {
        
        Spacer()
        
        VStack(spacing: 0){
        
            HStack{
                
                HeaderView(title: "Streak", value: $streak)
                
                VStack {
                    Text("WaddleUI")
                        .font(fontBig)
                        .fontWeight(.bold)
                
                    Text(String(format: "Points %05d",points)).font(.caption)
                        .transition(AnyTransition.opacity.animation(.easeInOut(duration:2)))
                }
                
                HeaderView(title: "Record", value: $record)
            }
            .padding()
            .border(.gray, width: 1)
            .background(.white)
            .foregroundColor(.black)
            .onAppear {
                
                if UIDevice.current.userInterfaceIdiom == .pad {
                    
                    fontBig = .system(size: 48, weight: .bold, design: .default)
                    fontNorm = .title
                }
                
                loadGame()
            }
        }
        .padding(letterWidth / 7)
        .background(Color("lightGray"))
        
        Spacer()
        
        //  WORD GRID
        VStack{
            
            //  Vertical
            ForEach(grid.rows, id: \.id) { row in
                
                //  Horizontal
                HStack{
                
                    ForEach(row.entries, id: \.id) { entry in
                        
                        Button(action: {
                            
                            selectEntry(id: entry.id)
                        }){
                        Text(entry.value)
                            .font(fontBig)
                            .fontWeight(.bold)
                            .frame(width: letterWidth, height: letterWidth, alignment: .center)
                            .border(entry.border)
                            .foregroundColor(entry.foreground)
                            .background(entry.background)
                            .animation(.easeOut(duration: 1.0), value: entry.foreground)
                        }
                        .disabled(!entry.disabled)
                    }
                }
                .disabled(row.disabled)
                .onTapGesture(count: 2) {
                    copyRow(id: row.id)
                }
            }
        }
        .padding(letterWidth / 7)
        .background(Color("lightGray"))
        
        Spacer()
        
        //  KEYBOARD
        if message == "" {
            
            VStack(spacing: 0) {
                
                //  Vertical
                ForEach(keyboard.rows, id: \.id) { row in
                    
                    //  Horizontal
                    HStack(spacing: 4){
                        
                        ForEach(row.keys, id: \.id) { key in
                            
                            Button(action: {
                                keyPressed(key: key.value)
                            }){
                                Text(key.value)
                                    .frame(width: key.width, height: keyWidth * 1.5, alignment: .center)
                                    .font(fontNorm)
                            }
                            .foregroundColor(key.foreground)
                            .background(key.background)
                            .border(Color.gray)
                            .animation(.easeOut(duration: 1.0), value: key.foreground)
                        }
                    }
                    .padding(4)
                    //.background(Color(red: 0.95, green: 0.95, blue: 0.95))
                    .background(Color("lightGray"))
                }
                
            }
            .frame(width: keyWidth * 11, height: keyWidth * 5, alignment: .center)
            .padding(letterWidth / 7)
            //.background(Color("lightGray"))
        }
        //  MESSAGE BUTTON
        else{
            
            Button(action: {
                
                showMessage(text: "", delay: 0)
                
                dictionary.cancelQuery()
                
                if game.over == true {
                 
                    self.resetGame()
                 
                    //  Reset grid
                    for (y,row) in grid.rows.enumerated() {
                        for (x,_) in row.entries.enumerated() {
                            
                            updateLetter(row: y, index: x, value: "")
                        }
                    }
                    
                    //  Reset keyboard
                    for row in keyboard.rows {
                        for key in row.keys {
                            
                            updateKeyboard(value: key.value, status: .STS_PENDING)
                        }
                    }
                    
                    highlightCursor()
                }
            }){
                
                VStack{
                    
                    Spacer()
                    
                    //  Main message
                    if dictionary.explanation == "" {
                    
                        Text(message)
                            .font(fontNorm)
                    }
                    //  Dictionary description
                    else {
                    
                        Text(dictionary.explanation)
                            .font(fontNorm)
                    }
                    Spacer()
                    
                }.frame(width: keyWidth * 10, height: keyWidth * 5, alignment: .center)
            }
            .frame(width: keyWidth * 11, height: keyWidth * 5, alignment: .center)
            .foregroundColor(.white)
            .background(.black)
            .border(Color.gray)
            .padding(letterWidth / 7)
            .background(Color("lightGray"))
        }
        
        Spacer()
    }
    
    //  Keyboard entry
    func keyPressed(key:String){
        
        //  Examine key press
        switch key {
            
        //  Backspace
        case "⌫":
            
            if game.cursorX >= 5 {
                game.cursorX -= 1
            }
            
            if game.cursorX > 0 && grid.rows[game.cursorY].entries[game.cursorX].value == "" {
                game.cursorX -= 1
            }
            
            grid.rows[game.cursorY].entries[game.cursorX].value = ""
            
        case "⏎":
            
            if game.cursorY < 6 && getWord(row: game.cursorY).count == 5 {
                
                analyseWord()
            }
        
        default:
            
            if game.cursorX < 5 {
                
                grid.rows[game.cursorY].entries[game.cursorX].value = key
                game.cursorX += 1
            }
        }
        
        highlightCursor()
    }
    
    //  Cursor
    func highlightCursor() {
        
        if game.cursorY > 5 || game.over == true {
            return
        }
    
        for n in 0..<5 {
            grid.rows[game.cursorY].entries[n].border = .gray
        }
        
        if(game.cursorX < 5){
            grid.rows[game.cursorY].entries[game.cursorX].border = .cyan
        }
    }
        
    //  Figure out results
    func analyseWord() {
        
        //  Get next guess word
        let word:String = getWord(row: game.cursorY)
        
        //  Check for valid 5 letter word
        if dictionary.isValidWord(word: word.lowercased()) == false {
            
            showMessage(text: "NOT A WORD: \(word.uppercased()) 😔", delay: 0)
            return
        }
        
        //  Iterate thru letters
        for n in 0...4 {
        
            let charIndex = word.index(word.startIndex, offsetBy: n)
            
            let ansChar:Character = game.answer[charIndex]
            let wordChar:Character = word[charIndex]
            
            //  Right letter right position
            if wordChar == ansChar {
                
                updateLetter(row: game.cursorY, index: n, value: String(wordChar),status: .STS_POSITIONED)
                continue
            }
            
            //  Letter in wrong position
            if game.answer.contains(wordChar) {
                
                let wordOccurances = word.occurances(subject:wordChar,endIndex:n)
                let answerOccurances = game.answer.occurances(subject:wordChar,endIndex:4)
                let matches = game.answer.matches(compareTo: word, subject: wordChar, fromIndex: n)
                
                //  Hairy bit
                if(wordOccurances > answerOccurances || matches >= 1){
                    print("wordOccurances: \(wordOccurances) answerOccurances: \(answerOccurances) Matches: \(matches) \(wordChar)")
                }
                else{
                    updateLetter(row: game.cursorY, index: n, value: String(wordChar),status: .STS_ILLPOSITIONED)
                    continue
                }
            }
            
            //  Default to outcast
            updateLetter(row: game.cursorY, index: n, value: String(wordChar),status: .STS_OUTCAST)
        }
        
        //  Disable editing on current line
        grid.rows[game.cursorY].disabled = true
        
        game.cursorY += 1
        game.cursorX = 0
        
        //  Correct word?
        if(word == game.answer){
            
            streak = streak + 1
            points += (7 - game.cursorY)
            
            if streak > record {
                record = streak
            }
            
            let defaults = UserDefaults.standard
            
            defaults.set(streak, forKey: "Streak")
            defaults.set(record, forKey: "Record")
            defaults.set(points, forKey: "Points")
            
            //  Chooses praise word
            let praise = praises[game.cursorY-1][Int.random(in: 0..<praises[game.cursorY-1].count)]
            
            showMessage(text: "\(praise): \(word.uppercased()) 😊\n\(7-game.cursorY) points",delay: 1000)
            
            dictionary.explainWord(word: game.answer)
            
            game.over = true
        }
        //  Incorrect word
        else if game.cursorY == 6 {
        
            showMessage(text: "THE WORD WAS \(game.answer) 😭",delay: 1)
            
            dictionary.explainWord(word: game.answer)
            
            streak = 0
            points = 0
            
            let defaults = UserDefaults.standard
            
            defaults.set(streak, forKey: "Streak")
            defaults.set(record, forKey: "Record")
            defaults.set(points, forKey: "Points")
            
            game.over = true
        }
        //  Enable editing on new line
        else {
            grid.rows[game.cursorY].disabled = false
        }
        
        //  Store it
        saveGame()
    }
    
    //  Select entry
    func selectEntry(id:UUID) {
        
        var col:Int = 0
        
        for entry in grid.rows[game.cursorY].entries {
            
            if entry.id == id {
                game.cursorX = col
            }
            
            col += 1
        }
        
        highlightCursor()
    }
    
    //  Select row
    func copyRow(id:UUID) {
        
        var y:Int = 0
        
        game.cursorX = 0
        
        for (r,row) in grid.rows.enumerated() {
            
            if row.id == id {
                
                for e in (0...4).reversed(){
                    
                    if(grid.rows[r].entries[e].background == .green){
                        grid.rows[game.cursorY].entries[e].value = grid.rows[r].entries[e].value
                    }
                    else{
                        
                        grid.rows[game.cursorY].entries[e].value = ""
                        game.cursorX = e
                    }
                }
                
                break
                
                /*
                setWord(row: game.cursorY, word: getWord(row: y))
                
                for _ in 0..<5 {
                    
                    if grid.rows[r].entries[game.cursorX].background != .green {
                        break
                    }
                    else {
                        game.cursorX += 1
                    }
                }*/
            }
            
            y += 1
        }
        
        highlightCursor()
    }
    
    //  Update grid and keyboard
    func updateLetter(row:Int, index:Int,value:String,status:LetterStatus = .STS_PENDING) {
        
        updateGrid(row: row, index: index, value: value,status: status)
        updateKeyboard(value: value, status: status)
    }
    
    //  Colorise grid
    func updateGrid(row:Int, index:Int,value:String,status:LetterStatus) {
        
        //  Check status and colorize
        switch status {
            
        case .STS_PENDING:
            grid.rows[row].entries[index].foreground = .black
            grid.rows[row].entries[index].background = .white
            
        case .STS_POSITIONED:
            grid.rows[row].entries[index].foreground = .white
            grid.rows[row].entries[index].background = .green
            
        case .STS_ILLPOSITIONED:
            grid.rows[row].entries[index].foreground = .white
            grid.rows[row].entries[index].background = .orange
            
        case .STS_OUTCAST:
            grid.rows[row].entries[index].foreground = .white
            grid.rows[row].entries[index].background = .gray
        }
        
        grid.rows[row].entries[index].border = .gray
        grid.rows[row].entries[index].value = value
    }
    
    //  Colorise key
    func updateKeyboard(value:String,status: LetterStatus){
        
        //  Find corresponding value
        for (y,row) in keyboard.rows.enumerated() {
        
            for (x,key) in row.keys.enumerated() {
                
                if key.value == value {
                    
                    if(key.status > status && status != .STS_PENDING){
                        return
                    }
                    
                    keyboard.rows[y].keys[x].status = status
                    
                    //  Check status and colorize
                    switch status {
                        
                    case .STS_PENDING:
                        keyboard.rows[y].keys[x].foreground = .black
                        keyboard.rows[y].keys[x].background = .white
                        
                    case .STS_POSITIONED:
                        keyboard.rows[y].keys[x].foreground = .white
                        keyboard.rows[y].keys[x].background = .green
                        
                    case .STS_ILLPOSITIONED:
                        keyboard.rows[y].keys[x].foreground = .white
                        keyboard.rows[y].keys[x].background = .orange
                        
                    case .STS_OUTCAST:
                        keyboard.rows[y].keys[x].foreground = .white
                        keyboard.rows[y].keys[x].background = .gray
                    }
                }
            }
        }
    }
    
    //  Reset
    func resetGame() {
        
        game.answer = dictionary.randomWord()
        game.over = false
        
        game.cursorX = 0
        game.cursorY = 0
        
        grid.rows[0].disabled = false
    }
    
    //  Read status
    func loadGame() {
        
        let defaults = UserDefaults.standard
        
        print("Loading game \(keyWidth)")
        
        //  Load values
        if let streakStr = defaults.object(forKey:"Streak") {
            streak = streakStr as! Int
        }
        
        if let recordStr = defaults.object(forKey:"Record") {
            record = recordStr as! Int
        }
        
        if let pointStr = defaults.object(forKey:"Points") {
            points = pointStr as! Int
        }
        
        resetGame()
        
        //  Load exisiting game
        if let answerStr = defaults.string(forKey: "Answer") {
         
            game.answer = answerStr
            print("--> \(game.answer)")
        }
        
        if let words = defaults.stringArray(forKey: "Words") {
        
            for (n,word) in words.enumerated() {
                
                setWord(row: n, word: word)
                analyseWord()
            }
        }
        
        highlightCursor()
    }
    
    //  Save game info
    func saveGame() {
        
        let words = getWords(row:game.cursorY)
        let defaults = UserDefaults.standard
        
        if(game.over){
            
            UserDefaults.standard.removeObject(forKey: "Words")
            UserDefaults.standard.removeObject(forKey: "Answer")
        }
        else{
            
            defaults.set(words, forKey: "Words")
            defaults.set(game.answer, forKey: "Answer")
        }
    }
    
    //  Build word
    func getWord(row:Int) -> String {
        
        var word:String = ""
        
        for entry in grid.rows[row].entries {
            
            if entry.value != "" {
                word += entry.value
            }
        }
        
        return word
    }
    
    //  Retrive words
    func getWords(row:Int) -> [String] {
    
        var result:[String] = []
        
        for n in 0..<row {
            
            result.append(getWord(row: n))
        }
    
        return result
    }
    
    //  Set word
    func setWord(row:Int,word:String){
    
        for n in 0...4 {
        
            let index = word.index(word.startIndex, offsetBy: n)
            
            grid.rows[row].entries[n].value = String(word[index])
        }
    }
    
    //  Raise alert
    func showMessage(text:String,delay:Int) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delay)) {
            message = text
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
