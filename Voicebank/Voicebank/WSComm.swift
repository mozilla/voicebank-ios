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
    let webserviceHostname = "http://127.0.0.1:8000"
    override init(){
        
    }
    
    func uploadAudio(audioFile : URL) {
        
        do {
            let data: NSData = try NSData(contentsOfFile: audioFile.path)
            let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceHostname)/upload/s1245/") as! URL)
            request.httpMethod = "POST"
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            request.setValue("audio/mp4a", forHTTPHeaderField: "content-type")
            
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.uploadTask(with: request as URLRequest, from: data as Data)
            task.resume()
            
        } catch let error as NSError{
            print("Error: \(error)")
        }
    
    }
    
    func getSentences() {
        
        let request = NSMutableURLRequest(url: NSURL(string: "\(self.webserviceHostname)/sentences.json") as! URL)
        request.httpMethod = "GET"
        request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
        let task = session.uploadTask(withStreamedRequest: request as URLRequest)
        task.resume()
    
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.responseData.append(data as Data)
        NSLog(String(data:self.responseData as Data, encoding: String.Encoding.utf8)!)
    }
    
    
}
