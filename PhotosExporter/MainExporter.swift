//
//  Main.swift
//  PhotosExporter
//

import Foundation
import Photos

func export() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd"
    let timeFilterStart = formatter.date(from: "20150101")
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
    let backDir = downloads!.appendingPathComponent("tmp")
    let contents = try! FileManager.default.contentsOfDirectory(atPath: backDir.path)
    if contents.count > 0 {
        print("Make sure the destination folder is empty.")
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
    
    print("Total " + String(assets.countOfAssets(with: .image)) + " Photos," + String(assets.countOfAssets(with: .video)) + " Videos.")
    
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
    
    print("Exporting " + String(exportAssets) + " Photo Assets, " + String(exportAssetResources) + " AssetResources.")
    
    let arrOptions = PHAssetResourceRequestOptions()
    arrOptions.isNetworkAccessAllowed = false
    var namesPool: [String] = []
    for i in 0..<assets.count {
        if assetsFlags[i] <= 0 {
            continue
        }
        
        let asset = assets.object(at: i)
        let assetResources = PHAssetResource.assetResources(for: asset)
        for j in 0..<assetResources.count {
            let resource = assetResources[j]
            let name = determineName(assetResource: resource, createTime: asset.creationDate!, pool: namesPool)
            print(name)
            namesPool.append(name)
            continue
            
            let url = backDir.appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: url.path) {
                print(url.absoluteString + " already exists.")
                return
            }
            PHAssetResourceManager.default().writeData(for: resource, toFile: url, options: arrOptions, completionHandler: { (e) in
                if e != nil {
                    print(e!.localizedDescription)
                    exit(1)
                } else {
                    assetsFlags[i]-=1
                }
            })
        }
    }
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
    let ext = origNameSplit[origNameSplit.count - 1].lowercased()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmm"
    formatter.timeZone = TimeZone.current
    return formatter.string(from: createTime) + "." + ext
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
