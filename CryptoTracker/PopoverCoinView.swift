
//  PopoverCoinView.swift
//  CryptoTracker
//
//  Created by Alfian Losari on 03/02/22.
//

import SwiftUI
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
    @State var currentTab: String = "7 Days"
    @State private var chartData: [PriceChart] = []
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
 
 
    var cheeseburgerCost: [Food] {
        var result: [Food] = []
      

        for (_, item) in chartData.enumerated() {
            for price in item.prices {
                let timestamp = price[0] / 1000 // Assuming the timestamp is in milliseconds
                       let date = Date(timeIntervalSince1970: timestamp)
                      

                let food = Food(name: dateFormatter.string(from: date), price: Double(price[1]), year: Int(price[0]))
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
                    
                    Picker("Duration", selection: $currentTab) {
                        Text("7 Days").tag("7 Days")
                        Text("Week").tag("Week")
                        Text("Month").tag("Month")
                    }
                    .pickerStyle(.segmented)
                }
                VStack(alignment: .leading) {
                    Text(viewModel.subtitle)
                        .padding(.leading)
                        .font(.title.bold())
                }
                

                AnimatedChart(item: cheeseburgerCost)
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

        func getUnixTimestampOneHourAgo() -> TimeInterval {
            let oneHourAgo = Date().addingTimeInterval(-3600) // 3600 seconds in 1 hour || 604800 Seconds in 1 week ||     86400 Seconds in day || 2629743 Seconds in Month || 31556926 Seconds in Year
            return oneHourAgo.timeIntervalSince1970
        }
    
    func fetchData() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart/range?vs_currency=usd&from=\(getUnixTimestampOneHourAgo())&to=\(getCurrentUnixTimestamp())") else { return }
        
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
    
    // Calculate min and max prices
    let minPrice = item.map { $0.price }.min() ?? 0
    let maxPrice = item.map { $0.price }.max() ?? 0
    
    return VStack{
        
        GroupBox ( "BitCoin") {
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
                    
                    RuleMark(
                        y: .value("Threshold", 400)
                    )
                    .foregroundStyle(.red)
                }
                
            }
            .padding()
            .chartYAxis() {
                AxisMarks(position: .leading)
            }
            .frame(height: 250)
            .chartYScale(domain: minPrice...maxPrice) // Set domain based on min and max prices
            .chartYAxis() {
                AxisMarks(position: .leading)
            }
            .chartLegend(position: .overlay, alignment: .top)
        }
    }
}

struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverCoinView(viewModel: .init(title: "Bitcoin", subtitle: "$40,000"))
    }
}
