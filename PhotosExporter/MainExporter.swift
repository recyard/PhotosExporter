//
//  Main.swift
//  PhotosExporter
//

import Foundation
import Photos
import Cocoa

func export(subdir: String, startTime: String, endTime: String, console: NSView) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    
    let timeFilterStart = formatter.date(from: startTime)
    if timeFilterStart == nil {
        console.insertText("Wrong start date format, use yyyyMMdd format.\n")
        return
    }
    var timeFilterEnd = Date()
    if !endTime.isEmpty {
        let tempTimeFilterEnd = formatter.date(from: endTime)
        if tempTimeFilterEnd == nil {
            console.insertText("Wrong end date format, use yyyyMMdd format.\n")
            return
        }
        timeFilterEnd = tempTimeFilterEnd!
    }
        
    let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    if downloads == nil {
        console.insertText("Downloads folder doesn't exist.\n")
        return
    }
    if subdir.isEmpty {
        console.insertText("Destination folder is not set.\n")
        return
    }
    let backDir = downloads!.appendingPathComponent(subdir)
    if !FileManager.default.fileExists(atPath: backDir.path) {
        console.insertText("Destination folder desn't exist.\n")
        return
    }
    let contents = try! FileManager.default.contentsOfDirectory(atPath: backDir.path)
    if contents.count > 0 {
        console.insertText("Make sure the destination folder is empty before the export.\n")
        return
    }
    
    PHPhotoLibrary.requestAuthorization { (status) in
        switch status {
        case .authorized:
            print("Photo library access granted.")
        default:
            print("Photo library access denied.")
        }
    }
    
    while PHPhotoLibrary.authorizationStatus() != .authorized {
        sleep(1)
        if PHPhotoLibrary.authorizationStatus() == .denied {
            return
        }
    }
    
    let fetchOptions = PHFetchOptions()
    fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
    let assets = PHAsset.fetchAssets(with: fetchOptions)
    
    console.insertText("\nTotal " + String(assets.countOfAssets(with: .image)) + " Photos, " + String(assets.countOfAssets(with: .video)) + " Videos.\n")
    
    var assetsFlags = Array(repeating: 0, count: assets.count)
    var exportAssets = 0
    var exportAssetResources = 0
    for i in 0..<assets.count {
        let asset = assets.object(at: i)
        if isValidAsset(phAsset: asset, start: timeFilterStart!, end: timeFilterEnd) {
            exportAssets+=1
            let assetResources = PHAssetResource.assetResources(for: asset)
            for j in 0..<assetResources.count {
                let resource = assetResources[j]
                if isValidAssetResource(assetResource: resource) {
                    assetsFlags[i]+=1
                    exportAssetResources+=1
                }
            }
        }
    }
    
    console.insertText("\nExporting " + String(exportAssets) + " Photo Assets, " + String(exportAssetResources) + " AssetResources.\n\n")
    
    let arrOptions = PHAssetResourceRequestOptions()
    arrOptions.isNetworkAccessAllowed = false
    var namesPool: [String] = []
    let lock: NSLock = NSLock()
    for i in 0..<assets.count {
        if assetsFlags[i] <= 0 {
            continue
        }
        let asset = assets.object(at: i)
        let assetResources = PHAssetResource.assetResources(for: asset)
        for j in 0..<assetResources.count {
            let resource = assetResources[j]
            if !isValidAssetResource(assetResource: resource) {
                continue
            }
            let name = determineName(assetResource: resource, createTime: asset.creationDate!, pool: namesPool)
            namesPool.append(name)
            let url = backDir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                console.insertText(url.path + " already exists.\n")
                return
            }
            console.insertText(resource.originalFilename + " is exporting as " + name + "\n")
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: arrOptions, completionHandler: { (e) in
                if e != nil {
                    console.insertText(e!.localizedDescription + "\n")
                    exit(1)
                } else {
                    lock.lock()
                    assetsFlags[i]-=1
                    lock.unlock()
                }
            })
        }
    }
    
    while !allClear(array: assetsFlags) {
        sleep(5)
    }
    console.insertText("\nExport finished, " + String(exportAssets) + " Photo Assets, " + String(exportAssetResources) + " AssetResources.\n")
}

func allClear(array: [Int]) -> Bool {
    for i in 0..<array.count {
        if array[i] != 0 {
            return false
        }
    }
    return true
}

func isValidAsset(phAsset: PHAsset, start: Date, end: Date) -> Bool {
    if (phAsset.mediaType == .image || phAsset.mediaType == .video) && phAsset.creationDate != nil && phAsset.creationDate! >= start && phAsset.creationDate! <= end {
        return true
    }
    return false
}

func isValidAssetResource(assetResource: PHAssetResource) -> Bool {
    if assetResource.type == .photo || assetResource.type == .fullSizePhoto || assetResource.type == .video || assetResource.type == .pairedVideo || assetResource.type == .fullSizePairedVideo || assetResource.type == .fullSizeVideo  {
        return true
    }
    return false
}

func determineName(assetResource: PHAssetResource, createTime: Date, pool: [String]) -> String {
    let origNameSplit = assetResource.originalFilename.split(separator: ".")
    let beforeExt = origNameSplit[origNameSplit.count - 2].lowercased().suffix(4)
    let ext = origNameSplit[origNameSplit.count - 1].lowercased()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    formatter.timeZone = TimeZone.current
    let tentativeName = formatter.string(from: createTime) + "_" + beforeExt + "." + ext
    if pool.contains(tentativeName) {
        var i = 1
        while pool.contains(formatter.string(from: createTime) + "_" + beforeExt + "_" + String(i) + "." + ext) {
            i+=1
        }
        return formatter.string(from: createTime) + "_" + beforeExt + "_" + String(i) + "." + ext
    }
    return tentativeName
}

func printResourceType(type: PHAssetResourceType) {
    switch type {
    case .video:
        print("video")
    case .photo:
        print("photo")
    case .pairedVideo:
        print("pairedVideo")
    case .fullSizeVideo:
        print("fullSizeVideo")
    case .fullSizePhoto:
        print("fullSizePhoto")
    case .fullSizePairedVideo:
        print("fullSizePairedVideo")
    case .audio:
        print("audio")
    case .alternatePhoto:
        print("alternatePhoto")
    case .adjustmentData:
        print("adjustmentData")
    case .adjustmentBaseVideo:
        print("adjustmentBaseVideo")
    case .adjustmentBasePhoto:
        print("adjustmentBasePhoto")
    case .adjustmentBasePairedVideo:
        print("adjustmentBasePairedVideo")
    default:
        print("")
    }
}
