//
//  SocketEngine.swift
//  StreamUsingSwift
//
//  Created by Static Ga on 14-9-19.
//  Copyright (c) 2014年 Static Ga. All rights reserved.
//

import UIKit

typealias SEReadingProgressBlock = (bytesReading: Int?, totalBytesReading: Int?) -> Void
typealias SEConnectionTerminatedBlock = (error: NSError?) ->Void
typealias SEReceivedNetworkDataBlock = (data: NSData?) ->Void

let BuffSize = 1024

class SocketEngine: NSObject, NSStreamDelegate{
    
    var host: CFString?
    var port: UInt32
    
    var inputStream: NSInputStream?
    var outputStream: NSOutputStream?
    var incomingDataBuffer: NSMutableData
    var outgoingDataBuffer: NSMutableData
    
    var readingProgress: SEReadingProgressBlock?
    var terminated: SEConnectionTerminatedBlock?
    var receivedNetworkData: SEReceivedNetworkDataBlock?
    
    init(host: CFString, port: UInt32) {
        
        self.host = host;
        self.port = port;
        
        self.incomingDataBuffer = NSMutableData();
        self.outgoingDataBuffer = NSMutableData();
       
        super.init()
        self.clean();
    }
    
    deinit {
        
    }
    
    func connect() {
        dispatch.async.global { () -> Void in
            self.socketDidConnect();
        }
    }
    
    func socketDidConnect() {
        if let host = self.host {
            self.setupSocketStreams();
        }
    }
    
    func closeStream(var stream: NSStream?) {
        stream!.removeFromRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
        stream!.close()
        stream = nil
    }
    
    func clean (){
        self.closeStream(self.inputStream);
        self.closeStream(self.outputStream);
    }
    func setupSocketStreams() {
        
        var readStream:  Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(kCFAllocatorDefault, self.host, self.port, &readStream, &writeStream)
        
        if var read = readStream {
            self.inputStream = readStream!.takeUnretainedValue()
            self.inputStream!.delegate = self;
            
            self.inputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
            self.inputStream!.open()
        }
        
        if let write = writeStream {
            self.outputStream = writeStream!.takeUnretainedValue()
            self.outputStream!.delegate = self;
            
            self.outputStream!.scheduleInRunLoop(NSRunLoop.currentRunLoop(), forMode: NSRunLoopCommonModes)
            self.outputStream!.open()
        }
    }
    
    func sendNetworkPacket(data: NSData) {
        self.outgoingDataBuffer.appendData(data);
        self.writeOutgoingBufferToStream();
    }
    
    func writeOutgoingBufferToStream() {
        if 0 == self.outgoingDataBuffer.length {
            return
        }
        
        if self.outputStream!.hasSpaceAvailable {
            var readBytes = self.outgoingDataBuffer.mutableBytes
            var byteIndex = 0
            readBytes += byteIndex
            
            var data_len = self.outgoingDataBuffer.length
            var len = ((data_len - byteIndex >= BuffSize) ?
                BuffSize : (data_len-byteIndex))
            var buf = UnsafeMutablePointer<UInt8>.alloc(len)
            memcpy(buf, readBytes, UInt(len))
            len = self.outputStream!.write(buf, maxLength: BuffSize)
            if len > 0{
                self.outgoingDataBuffer.replaceBytesInRange(NSMakeRange(byteIndex, len), withBytes: nil, length: 0)
                byteIndex += len
            }else {
                self.closeStream(self.outputStream);
                dispatch.async.main({ () -> Void in
                    if var terminatedClosure = self.terminated {
                        self.terminated!(error: nil)
                    }
                })
            }
        }
    }
    
    func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.OpenCompleted :
            break
        case NSStreamEvent.HasBytesAvailable :
            var buf = UnsafeMutablePointer<UInt8>.alloc(BuffSize)
            var len = 0
            len = self.inputStream!.read(buf, maxLength: BuffSize)
            if len > 0 {
                self.incomingDataBuffer.appendBytes(buf, length: len)
                var readingData = NSData(bytes: buf, length: len)
                
                dispatch.async.main({ () -> Void in
                    if var readingClosure = self.readingProgress {
                        self.readingProgress!(bytesReading: readingData.length ,totalBytesReading: self.incomingDataBuffer.length)
                    }
                    
                    if var receivedData = self.receivedNetworkData {
                        self.receivedNetworkData!(data: readingData)
                    }
                });
            }else {
                //Finished
                self.incomingDataBuffer.resetBytesInRange(NSMakeRange(0, self.incomingDataBuffer.length));
                self.incomingDataBuffer.length = 0;
                
                dispatch.async.main({ () -> Void in
                    if var terminatedClosure = self.terminated {
                        self.terminated!(error: nil)
                    }
                })
            }
            break
        case NSStreamEvent.HasSpaceAvailable :
            self.writeOutgoingBufferToStream()
            break
        case NSStreamEvent.EndEncountered :
            self.closeStream(aStream);
            dispatch.async.main({ () -> Void in
                if var terminatedClosure = self.terminated {
                    self.terminated!(error: nil)
                }
            })
            break
        case NSStreamEvent.ErrorOccurred :
            self.closeStream(aStream);
            dispatch.async.main({ () -> Void in
                if var terminatedClosure = self.terminated {
                    self.terminated!(error: aStream.streamError)
                }
            })
            break
        default:
            break
        }
    }
}
