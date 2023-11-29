//
//  GlowView.swift
//  CustomView
//
//  Created by David McCarthy on 11/11/2023.
//

import SwiftUI
import MapKit

class UIGlowView: UIView {
    
    var rect = CGRect.zero
    
    var red:Int
    var green:Int
    var blue:Int
    
    var incRed = 1//Int.random(in: 10..<25)
    var incGreen = 2//Int.random(in: 10..<25)
    var incBlue = 3//Int.random(in: 10..<25)
    
    init(red:Int,green:Int,blue:Int) {
    
        self.red = red
        self.green = green
        self.blue = blue
        
        super.init(frame: rect)
        //super.init(frame: CGRect(x: 10, y: 10, width: 100, height: 100))
        
        //self.backgroundColor = UIColor.yellow
        //self.layoutMargins = UIEdgeInsets.zero
        
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { (_) in
            self.setNeedsDisplay()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        //let path = UIBezierPath(roundedRect: rect, cornerRadius: rect.height * 0.25)
        let path = UIBezierPath(rect: rect)
        
        red += incRed
        green += incGreen
        blue += incBlue
        
        if(red > 1000 || red < 0){
            incRed = -incRed
            red += incRed
        }
        
        if(green > 1000 || green < 0){
            incGreen = -incGreen
            green += incGreen
        }
        
        if(blue > 1000 || blue < 0){
            incBlue = -incBlue
            blue += incBlue
        }
        
        UIColor(red: CGFloat(Float(red) / 1000), green: CGFloat(Float(green) / 1000), blue: CGFloat(Float(blue) / 1000), alpha: 1.0).setFill()
        
        path.fill()
        path.close()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UIGlowController: UIViewController {
    
    let glows = 300
    
    //  Start up
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        var rect = UIScreen.main.bounds
        let height = rect.height/Double(glows)
        
        print(rect)
        
        //rect.height = rect.height/Double(glows)
        
        for g in 0..<glows {
            
            let sub = UIGlowView(red: g, green: g, blue: g)
        
            rect = CGRect(x: 0, y: height*Double(g), width: rect.width, height:height)
            sub.frame = rect
            
            view.addSubview(sub)
        }
        
        var textView = UITextView()
        textView.font = UIFont.systemFont(ofSize: 48)
        
        textView.text = "HELLO WORLD"
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        textView.frame = UIScreen.main.bounds
        
        //view.addSubview(textView)
        
        /*
        view.addSubview(UIGlowView(red: 0, green: 0, blue: 0))
        view.addSubview(UIGlowView(red: 10, green: 10, blue: 10))*/
    }
}

struct GlowController: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> some UIGlowController {
        UIGlowController()
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
