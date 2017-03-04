//
//  WSComm.swift
//  Voicebank
//
//  Created by Andre Natal on 2/27/17.
//  Copyright © 2017 Andre Natal. All rights reserved.
//

import Foundation

class WSComm: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
   
    var responseData = NSMutableData()
    let webserviceHostname = "https://murmur.vaani.io"
    override init(){
        
    }
    
    func uploadAudio(audioFile : URL, sentenceKey : String, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        do {
            let data: NSData = try NSData(contentsOfFile: audioFile.path)
            
            let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceHostname)/upload/\(sentenceKey)/") as! URL)
            request.httpMethod = "POST"
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue("audio/mp4a", forHTTPHeaderField: "content-type")
            request.setValue(UUID().uuidString, forHTTPHeaderField: "uid")
            
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.uploadTask(with: request as URLRequest, from: data as Data, completionHandler: completion)
            task.resume()
        } catch let error as NSError{
            print("Error: \(error)")
        }
    }
    
    func getSentences(completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceHostname)/sentences.json") as! URL)
        request.httpMethod = "GET"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.dataTask(with: request as URLRequest, completionHandler: completion)
        task.resume()
    }
    
}
