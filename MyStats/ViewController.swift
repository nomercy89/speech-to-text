//
//  ViewController.swift
//  MyStats
//
//  Created by Elia Montecchio on 03/12/18.
//  Copyright © 2018 Elia Montecchio. All rights reserved.
//

import UIKit
import AVFoundation
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate{

   
    @IBOutlet weak var microphoneButton: UIButton!
    @IBOutlet weak var speech_result: UILabel!
    @IBOutlet weak var loading_bar: UIImageView!
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.init(identifier: "it-IT"))
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        SFSpeechRecognizer.requestAuthorization { (authStatus) in  //4
            
            switch authStatus {  //5
            case .authorized:
                print("Autorizzato")
    
                
            case .denied:
                print("User denied access to speech recognition")
                
            case .restricted:
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                print("Speech recognition not yet authorized")
            }
        }
 
        
    }
    
    func make_request(msg:String){
    print("preparo url " + msg)
    let url = URL(string: "http://192.168.1.99:3000/url?msg=" + msg)!

        let task = URLSession.shared.dataTask(with: url) {
        (data, response, error) in
        // check for any errors
        guard error == nil else {
            print("error calling GET on /todos/1")
            print(error!)
            return
        }
        // make sure we got data
        guard let responseData = data else {
            print("Error: did not receive data")
            return
        }
        
        
        guard let todo = try? JSONDecoder().decode(WitAiResponse.self, from: responseData)
            else {
                print("RESP" , responseData);
                
                print("error trying to convert data to JSON")
                return
        }
        
        print( todo.resp);
        let voice = AVSpeechSynthesisVoice(language: "it-IT");
        let spk = AVSpeechSynthesizer()
        let toSay = AVSpeechUtterance(string : todo.resp);
        toSay.voice = voice
        spk.speak(toSay)

        return
        
        
    }
    task.resume()
        
       
    }
    

    
    @IBAction func ac(_ sender: Any) {
        

        if isRecording == true {
            audioEngine.stop()
            audioEngine.reset()
            request.endAudio()
            recognitionTask?.finish()
            recognitionTask?.cancel()
            isRecording = false
            microphoneButton.setTitle("Avvia..", for: UIControl.State.normal);
            make_request(msg: self.speech_result.text!)
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
            microphoneButton.setTitle("Ferma..", for: UIControl.State.normal);
            
            
        }

      
        
    }

    
func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(message: "Speech recognition is not currently available. Check back at a later time.")
            // Recognizer is not available right now
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if result != nil{
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                self.speech_result.text = bestString
  
            } else if let error = error {
                self.sendAlert(message: "There has been a speech recognition error.")
                print(error)
            }
            }
        })
    }
    
    //MARK: - Check Authorization Status
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.microphoneButton.isEnabled = true
                case .denied:
                    self.microphoneButton.isEnabled = false
                    self.speech_result.text = "User denied access to speech recognition"
                case .restricted:
                    self.microphoneButton.isEnabled = false
                    self.speech_result.text = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.microphoneButton.isEnabled = false
                    self.speech_result.text = "Speech recognition not yet authorized"
                }
            }
        }
    }
    
    
    func sendAlert(message: String) {
        let alert = UIAlertController(title: "Speech Recognizer Error", message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
}
    
}

