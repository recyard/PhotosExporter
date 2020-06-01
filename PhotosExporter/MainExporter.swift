//
//  Main.swift
//  PhotosExporter
//
//  Created by Andreas Bentele on 10.02.18.
//  Copyright © 2018 Andreas Bentele. All rights reserved.
//

import Foundation
import Photos

func export() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let timeFilterStart = formatter.date(from: "20160101")
    if timeFilterStart == nil {
        print("Wrong date format??")
        return
    }
    let timeFilterEnd = Date()
    
    let downloads = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
    if downloads == nil {
        print("Downloads???")
        return
    }
    let backDir = downloads!.appendingPathComponent("temp")
    
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
    
    print("Total " + String(assets.countOfAssets(with: .image)) + " Photos," + String(assets.countOfAssets(with: .video)) + " Videos.")
    
    var assetsFlags = Array(repeating: 0, count: assets.count)
    for i in 0..<assets.count {
        let asset = assets.object(at: i)
        if isValidAsset(phAsset: asset, start: timeFilterStart!, end: timeFilterEnd) {
            let assetResources = PHAssetResource.assetResources(for: asset)
            for j in 0..<assetResources.count {
                let resource = assetResources[j]
                print(resource.originalFilename)
                printResourceType(type: resource.type)
            }
            assetsFlags[i]+=1
        }
    }
    
    let arrOptions = PHAssetResourceRequestOptions()
    arrOptions.isNetworkAccessAllowed = false
    
    
    for i in 0..<0 {
        let asset = assets.object(at: i)
        
        let assetResources = PHAssetResource.assetResources(for: asset)
        for j in 0..<assetResources.count {
            let resource = assetResources[j]
            print(resource.originalFilename)
            
            let url = backDir.appendingPathComponent(resource.originalFilename)
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: arrOptions, completionHandler: { (e) in
                if e != nil {
                    print(e!.localizedDescription)
                } else {
                    assetsFlags[i]-=1
                }
            })
        }
        
        print()
    }
    
}

func isValidAsset(phAsset: PHAsset, start: Date, end: Date) -> Bool {
    if (phAsset.mediaType == .image || phAsset.mediaType == .video) && phAsset.creationDate != nil && phAsset.creationDate! >= start && phAsset.creationDate! <= end {
        return true
    }
    return false
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
