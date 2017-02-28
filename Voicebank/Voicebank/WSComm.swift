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
    
    override init(){
        
    }
    
    func uploadAudio(audioFile : URL) {

        do {
            
            let data: NSData = try NSData(contentsOfFile: audioFile.path)
            
            let request = NSMutableURLRequest(url: NSURL(string: "https://127.0.0.1:4343/upload/s1245/") as! URL)
            request.httpMethod = "POST"
            request.setValue("Keep-Alive", forHTTPHeaderField: "Connection")
            
            let configuration = URLSessionConfiguration.default
            let session = URLSession(configuration: configuration, delegate: self, delegateQueue: OperationQueue.main)
            let task = session.uploadTask(with: request as URLRequest, from: data as Data)
            task.resume()
            
        } catch let error as NSError{
            print("Error: \(error)")
        }
    }
    
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.responseData.append(data as Data)
    }
    
    
}
