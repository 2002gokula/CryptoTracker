
//  PopoverCoinView.swift
//  CryptoTracker
//
//  Created by Alfian Losari on 03/02/22.
//

import SwiftUI
import SwiftUICharts
import Charts

struct PriceChart: Identifiable, Hashable , Decodable {
    let prices, marketCaps, totalVolumes: [[Double]]
    var id = UUID()
    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
    
}

enum Duration: String, CaseIterable {
 
//        case tenMinutes = "10m"
//        case thirtyMinutes = "30m"
    case oneHour = "1h"
//        case fourHours = "4h"
//        case eightHours = "8h"
    case day = "24h"
    case sevenDays = "7d"
    case fourteenDays = "14d"
    case thirtyDays = "30d"
    case ninetyDays = "90d"
    case oneEightyDays = "180d"
    case oneYear = "1 Year"


    var isActive: Bool {
        return self == .sevenDays // Set .sevenDays as default active
    }

    var timeInterval: TimeInterval {
        switch self {
 
//            case .tenMinutes: return 60 * 10 // 60 seconds in 1 minute * 10 minutes
//            case .thirtyMinutes: return 60 * 30 // 60 seconds in 1 minute * 30 minutes
//            case .fourHours: return 3600 * 4 // 3600 seconds in 1 hour * 4 hours
//            case .eightHours: return 3600 * 8 // 3600 seconds in 1 hour * 8 hours
        case .oneHour: return 3600 // 3600 seconds in 1 hour
            case .day: return 86400 // Replace with actual time interval for "24h"
            case .sevenDays: return 604800 // 604800 seconds in 7 days
            case .fourteenDays: return 86400 * 14 // 86400 seconds in 1 day * 14 days
            case .thirtyDays: return 86400 * 30 // 86400 seconds in 1 day * 30 days
            case .ninetyDays: return 86400 * 90 // 86400 seconds in 1 day * 90 days
            case .oneEightyDays: return 86400 * 180 // 86400 seconds in 1 day * 180 days
            case .oneYear: return 86400 * 365 // 86400 seconds in 1 day * 365 days
          // 60 seconds in 1 minute * 5 minutes
        }
    }
}

struct Food: Identifiable {
    let name: String
    let price: Double
    let date: Date
    let id = UUID()


    init(name: String, price: Double, year: Int) {
        self.name = name
        self.price = price
        let calendar = Calendar.autoupdatingCurrent
        self.date = calendar.date(from: DateComponents(year: year))!
    }
}


struct PopoverCoinView: View {

    @ObservedObject var viewModel: PopoverCoinViewModel
    @State private var selectedDuration: Duration = {
           if let storedDuration = UserDefaults.standard.string(forKey: "selectedDuration"),
              let duration = Duration(rawValue: storedDuration) {
               return duration
           } else {
               return .day // Default value if no stored value found
           }
       }()


    @State private var chartData: [PriceChart] = []
    
    
    var dateFormat: String {
        switch selectedDuration {
        case .oneHour:
            return "HH:mm"
        case .day:
            return "yyyy-MM-dd HH:mm:ss"
        case .sevenDays, .fourteenDays, .thirtyDays,
             .ninetyDays, .oneEightyDays, .oneYear:
            return "yyyy-MM-dd HH:mm:ss"
        }
    }

    // Use a local variable to capture self as an unowned reference within the closure
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = self.dateFormat
        return formatter
    }

    // Usage of dateFormatter
   
 
    var cheeseburgerCost: [Food] {
        var result: [Food] = []


        for (_, item) in chartData.enumerated() {
            for price in item.prices {
                let timestamp = price[0] / 1000 // Assuming the timestamp is in milliseconds
                       let date = Date(timeIntervalSince1970: timestamp)
                      
                let formattedDate = dateFormatter.string(from: date)
                let food = Food(name: formattedDate, price: Double(price[1]), year: Int(price[0]))
                result.append(food)
            }
        }

        return result
    }
    
    
    var body: some View {
        VStack(spacing: 16) {
            VStack {
                Text(viewModel.title).font(.largeTitle)
                Text(viewModel.subtitle).font(.title.bold())
            }
            
            Divider()
            
            Picker("Select Coin", selection: $viewModel.selectedCoinType) {
                
                ForEach(viewModel.coinTypes) { type in
                    HStack {
                        Text(type.description).font(.headline)
                        Spacer()
                        Text(viewModel.valueText(for: type))
                            .frame(alignment: .trailing)
                            .font(.body)
                        
                        Link(destination: type.url) {
                            Image(systemName: "safari")
                        }
                    }
                    .tag(type)
                }
            }
            .pickerStyle(RadioGroupPickerStyle())
            .labelsHidden()
            
            Divider()
            VStack{
                HStack{
                    Text("Price")
                    
                    Picker("Duration", selection: $selectedDuration) {
                               ForEach(Duration.allCases, id: \.self) { duration in
                                   Text(duration.rawValue).tag(duration)
                               }
                           }
                           .pickerStyle(.segmented)
                           .onChange(of: selectedDuration) { newValue in
                               UserDefaults.standard.set(newValue.rawValue, forKey: "selectedDuration")
                               print(newValue.timeInterval)
                               fetchData()
                           }
                }
                VStack(alignment: .leading) {
                    Text(viewModel.subtitle)
                        .padding(.leading)
                        .font(.title.bold())
                }
                
                AnimatedChart(item: cheeseburgerCost)
//                AnimatedChart()
            }
            Button("Quit") {
                NSApp.terminate(self)
            }
            
        }
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
            fetchData()
          
          
        }
        .onAppear {
            viewModel.subscribeToService()
            fetchData()
           
        }
    }
    func getCurrentTime() -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            return dateFormatter.string(from: Date())
        }

        func getCurrentUnixTimestamp() -> TimeInterval {
            return Date().timeIntervalSince1970
        }

    func getUnixTimestampAgo() -> TimeInterval {
        let timeInterval = selectedDuration.timeInterval
        let agoDate = Date().addingTimeInterval(-timeInterval)
        return agoDate.timeIntervalSince1970
    }

    func fetchData() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/\(viewModel.title.count == 0 ? "bitcoin": viewModel.title.lowercased() )/market_chart/range?vs_currency=usd&from=\(getUnixTimestampAgo())&to=\(getCurrentUnixTimestamp())") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error fetching data: \(error.localizedDescription)")
                return
            }

            guard let data = data else {
                print("No data received")
                return
            }
            do {
                let response = try JSONDecoder().decode(PriceChart.self, from: data)
                DispatchQueue.main.async {
                    self.chartData = [response]
                }
            } catch {
                print("Error decoding JSON: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    print("Received data: \(dataString)")
                }
            }
        }.resume()
    }
}




func AnimatedChart(item: [Food]) -> some View {
    @State  var isLoading = true
    @State var select = "0"
    @State var isHovering = false
    @State  var selectedDate: Date?
    
    let prices = item.map { $0.price }
    let minPrice = prices.min() ?? 0
    let maxPrice = prices.max() ?? 0

    // Calculate average price
    let totalPrice = prices.reduce(0, +)
    let averagePrice = Double(totalPrice) / Double(prices.count)

    var formattedPrices: [String] = []
    
    item.forEach { food in
        let formattedPrice = String(format: "%.2f%%", food.price)
        formattedPrices.append(formattedPrice)
            }

    return VStack{
      
        GroupBox ( "BitCoin") {
            GeometryReader { geometry in
                Text("\(averagePrice)")
                                .foregroundColor(.white)
                                .position(x: 53, y: geometry.size.height * 44)
                        }
            
            Chart {
        
                ForEach(Array(item.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Hour", value.name),
                        y: .value("Price", value.price)
                    )
                    .interpolationMethod(.catmullRom)
                    
                    
                    AreaMark(
                        x: .value("Hour", value.name),
                        y: .value("Price", value.price)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(Color("Blue").opacity(0.1).gradient)
                  
//                    RuleMark(
//                        y: .value("Threshold", averagePrice+2)
//                    )
//                    .foregroundStyle(.red)
                  
                }
            }

            .padding()
            .chartYAxis() {
                AxisMarks(position: .leading)
            }
            .frame(height: 250)
            .chartYScale(domain: minPrice...maxPrice)
            .chartLegend(position: .overlay, alignment: .top)
        }
    }
}
//struct AxisValueLabel: View {
//    var price: Double
//    
//    var body: some View {
//        Text("$\(String(format: "%.2f", price))") // Displaying price with a "$" symbol
//    }
//}


struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverCoinView(viewModel: .init(title: "Bitcoin", subtitle: "$40,000"))
    }
}
