//
//  Stream.swift
//  StreamUsingSwift
//
//  Created by Static Ga on 14-9-19.
//  Copyright (c) 2014年 Static Ga. All rights reserved.
//

import Foundation

class Stream {
    class func getStreamsToHostWithName(hostname: CFString, port: UInt32, inputStream: AutoreleasingUnsafeMutablePointer<NSInputStream?>, outputStream: AutoreleasingUnsafeMutablePointer<NSOutputStream?>) {
//   
//        var readStream:  Unmanaged<CFReadStream>?
//        var writeStream: Unmanaged<CFWriteStream>?
//        
//        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, hostname, port, &readStream, &writeStream)
//        
//        if var read = readStream {
//            inputStream = readStream!.takeUnretainedValue()
//        }
//        
//        if let write = writeStream {
//            outputStream = writeStream!.takeUnretainedValue()
//        }
    }
}