//
//  Widget.swift
//  Widget
//
//  Created by Collin Alpert on 10.02.22.
//

import WidgetKit
import SwiftUI
import CoreImage.CIFilterBuiltins
import EUDCCDecoder

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(certificateData: getCertificateData())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(certificateData: getCertificateData())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = SimpleEntry(certificateData: getCertificateData())

        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
    
    func getCertificateData() -> String? {
        UserDefaults(suiteName: "group.com.github.collinalpert.vaccination-widget")?.string(forKey: "certificateData")
    }
}

struct SimpleEntry: TimelineEntry {
    let date = Date()
    let certificateData: String?
}

struct QR_WidgetEntryView : View {
    static let context = CIContext()
    static let filter = CIFilter.qrCodeGenerator()
    let decoder = EUDCCDecoder()
    
    var entry: Provider.Entry

    var body: some View {
        GeometryReader { g in
            if let qrCodeImage = QR_WidgetEntryView.generateQRCode(from: entry.certificateData, displaySize: g.size) {
                let cert = try! decoder.decode(from: entry.certificateData!).get()
                VStack {
                    HStack {
                        Text(cert.name.formatted()).padding(.leading, 8).padding(.top, 4)
                        Spacer()
                        Text("Dose \(cert.vaccination!.doseNumber)/\(cert.vaccination!.totalSeriesOfDoses)").padding(.trailing, 8).padding(.top, 4)
                    }.padding(.bottom, 0)
                    Image(uiImage: qrCodeImage).interpolation(.none).resizable().scaledToFit().padding(.top, -12).padding(.bottom, 4)
                }.background(Color.black)
            } else {
                VStack(alignment: .center) {
                    Text("No certificate found.").frame(alignment: .center)
                }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
    }
    
    static func generateQRCode(from string: String?, displaySize: CGSize) -> UIImage? {
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

@main
struct QR_Widget: Widget {
    let kind: String = "QR-Widget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QR_WidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Vaccination QR code")
        .description("This is a widget which displays a vaccination certificate QR code.")
        .supportedFamilies([.systemLarge])
    }
}

struct QR_Widget_Previews: PreviewProvider {
    
    // Test certificate data here
    static let certificateData: String? = nil
    
    static var previews: some View {
        QR_WidgetEntryView(entry: SimpleEntry(certificateData: certificateData))
            .previewContext(WidgetPreviewContext(family: .systemLarge))
    }
}

