//
//  ContentView.swift
//  vaccination-widget
//
//  Created by Collin Alpert on 10.02.22.
//

import SwiftUI
import CoreImage.CIFilterBuiltins
import CodeScanner
import EUDCCDecoder
import WidgetKit

struct ContentView: View {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    let decoder = EUDCCDecoder()
    
    @State var dataEntry: Entry?
    @State var showScanner = false
    
    init() {
        guard let data = getCertificateData() else {
            return
        }
        
        _dataEntry = State.init(initialValue: getDataEntry(rawData: data))
    }
    
    
    var body: some View {
        let displaySize = UIScreen.main.bounds.width - 100
        VStack {
            if let entry = dataEntry {
                if let qrCodeImage = generateQRCode(from: entry.certificateData, displaySize: CGSize(width: displaySize, height: displaySize)) {
                    HStack {
                        Text(entry.name)
                        Spacer()
                        Text("Dosis \(entry.dose)/\(entry.totalNumberOfDoses)")
                    }
                    Image(uiImage: qrCodeImage).interpolation(.none).resizable().scaledToFit()
                    Button("Scan new vaccination certificate") {
                        showScanner = true
                    }
                    Button("Delete certificate", role: .destructive) {
                        dataEntry = nil
                        setCertificateData(certificateData: nil)
                        WidgetCenter.shared.reloadTimelines(ofKind: "QR-Widget")
                    }.padding()
                } else {
                    Text("QR code could not be generated.")
                }
            } else {
                Text("No certificate found.")
                Button("Scan new vaccination certificate") {
                    showScanner = true
                }.padding()
            }
        }.padding()
            .sheet(isPresented: $showScanner) {
                CodeScannerView(codeTypes: [.qr]) { response in
                    switch response {
                    case .success(let result):
                        dataEntry = getDataEntry(rawData: result.string)
                        if dataEntry != nil {
                            setCertificateData(certificateData: result.string)
                            WidgetCenter.shared.reloadTimelines(ofKind: "QR-Widget")
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                    showScanner = false
                }
            }
        
    }
    
    func getDataEntry(rawData: String) -> Entry? {
        let decodeResult = decoder.decode(from: rawData)
        switch decodeResult {
        case .success(let result) where result.vaccination != nil:
            return Entry(certificateData: result.base45Representation, name: result.name.formatted(), dose: result.vaccination!.doseNumber, totalNumberOfDoses: result.vaccination!.totalSeriesOfDoses)
        case .failure(let error):
            print(error)
            return nil
        case .success(_):
            print("QR code ist not a vaccination certificate.")
            return nil
        }
    }
    
    func getCertificateData() -> String? {
        UserDefaults(suiteName: "group.com.github.collinalpert.vaccination-widget")?.string(forKey: "certificateData")
    }
    
    func setCertificateData(certificateData: String?) {
        UserDefaults(suiteName: "group.com.github.collinalpert.vaccination-widget")?.set(certificateData, forKey: "certificateData")
    }
    
    func generateQRCode(from string: String?, displaySize: CGSize) -> UIImage? {
        guard let data = string else {
            return nil
        }
        
        filter.message = Data(data.utf8)
        
        if let outputImage = filter.outputImage {
            if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
                return UIImage(cgImage: cgimg)
            }
        }
        
        return nil
    }
}

struct Entry {
    let certificateData: String
    let name: String
    let dose: Int
    let totalNumberOfDoses: Int
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
        }
    }
}

