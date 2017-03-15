//
//  WSComm.swift
//  Voicebank
//
//  Created by Andre Natal on 2/27/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation
import UIKit

class WSComm: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
   
    var responseData = NSMutableData()
    let webserviceEndpoint = "https://murmur.vaani.io"
    override init(){
        
    }
    
    func uploadAudio(audioFile : URL, sentence : String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        do {
            let data: NSData = try NSData(contentsOfFile: audioFile.path)
            let sentenceHash = sentence.digest(length: CC_SHA1_DIGEST_LENGTH, gen: {(data, len, md) in CC_SHA1(data,len,md)})
            let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceEndpoint)/upload/\(sentenceHash)/") as! URL)
            request.httpMethod = "POST"
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue("audio/mp4a", forHTTPHeaderField: "content-type")
            request.setValue(UIDevice.current.identifierForVendor!.uuidString, forHTTPHeaderField: "uid")
            request.setValue(sentence, forHTTPHeaderField: "sentence")
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.uploadTask(with: request as URLRequest, from: data as Data, completionHandler: completion)
            task.resume()
        } catch let error as NSError{
            print("Error: \(error)")
        }
    }
    
    func uploadInfo(gender: String, age: String, language: String) {
        let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceEndpoint)/data/ios/") as! URL)
        request.httpMethod = "GET"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        request.setValue(UIDevice.current.identifierForVendor!.uuidString, forHTTPHeaderField: "id")
        request.setValue(gender, forHTTPHeaderField: "gender")
        request.setValue(age, forHTTPHeaderField: "age")
        request.setValue(language, forHTTPHeaderField: "langs1")
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest)
        task.resume()
    }
    
    func getSentences(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceEndpoint)/sentences.json") as! URL)
        request.httpMethod = "GET"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: completion)
        task.resume()
    }
    
}

extension String {
    
    func digest(length:Int32, gen:(_ data: UnsafeRawPointer, _ len: CC_LONG, _ md: UnsafeMutablePointer<UInt8>) -> UnsafeMutablePointer<UInt8>) -> String {
        var cStr = [UInt8](self.utf8)
        var result = [UInt8](repeating:0, count:Int(length))
        gen(&cStr, CC_LONG(cStr.count), &result)
        
        let output = NSMutableString(capacity:Int(length))
        
        for r in result {
            output.appendFormat("%02x", r)
        }
        
        return String(output)
    }
    
}
