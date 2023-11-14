
//  PopoverCoinView.swift
//  CryptoTracker
//
//  Created by Alfian Losari on 03/02/22.
//

import SwiftUI
import Charts
struct MonthlyHoursOfSunshine {
    var city: String
    var date: Date
    var hoursOfSunshine: Double


    init(city: String, month: Int, hoursOfSunshine: Double) {
        let calendar = Calendar.autoupdatingCurrent
        self.city = city
        self.date = calendar.date(from: DateComponents(year: 2020, month: month))!
        self.hoursOfSunshine = hoursOfSunshine
    }
}


var data: [MonthlyHoursOfSunshine] = [
    MonthlyHoursOfSunshine(city: "Seattle", month: 1, hoursOfSunshine: 74),
    MonthlyHoursOfSunshine(city: "Cupertino", month: 1, hoursOfSunshine: 196),
    MonthlyHoursOfSunshine(city: "Seattle", month: 12, hoursOfSunshine: 62),
    MonthlyHoursOfSunshine(city: "Cupertino", month: 12, hoursOfSunshine: 199)
]


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
//    var cheeseburgerCost: [Food] {
//            return chartData.enumerated().flatMap { (index, item) in
//                item.prices.map { price in
//                    Food(name: "Cheeseburger-\(index)", price: Double(price), year: 1 + index)
//                }
//            }
//        }
//    func printCheeseburgerCost() {
//        let cost = cheeseburgerCost
//        print(cost)
//    }

    // Or directly in your code where you need it:

  
//    let cheeseburgerCostByItem: [Food] = [
//        .init(name: "Burger", price: 0.07, year: 1960),
//        .init(name: "Cheese", price: 0.03, year: 1960),
//        .init(name: "Bun", price: 0.05, year: 1960),
//        .init(name: "Burger", price: 0.10, year: 1970),
//        .init(name: "Cheese", price: 0.04, year: 1970),
//        .init(name: "Bun", price: 0.06, year: 1970),
//        // ...
//        .init(name: "Burger", price: 0.60, year: 2020),
//        .init(name: "Cheese", price: 0.26, year: 2020),
//        .init(name: "Bun", price: 0.24, year: 2020)
//    ]
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
                
//                Chart {
//                    ForEach(cheeseburgerCost , id: \.id) { cost in
//                        AreaMark(
//                            x: .value("Date", cost.price),
//                            y: .value("Price", cost.date)
//                        )
//                        .foregroundStyle(Color.gray)
//                    }
//                }
//                List(cheeseburgerCost, id: \.name) { food in
//                               VStack(alignment: .leading) {
//                                   Text("Name: \(food.name)")
//                                   Text("Price: $\(food.price)")
//                                  
//                               }
//                           }
                AnimatedChart(item: cheeseburgerCost)
            }
            
            Button("Quit") {
                NSApp.terminate(self)
            }
            
        }
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
            fetchData()
            print(chartData.enumerated().map { (index, item) in
                item.prices
            }, "demo")
        }
        .onAppear {
            viewModel.subscribeToService()
            fetchData()
            print(chartData.enumerated().map { (index, item) in
                item.prices
            }, "gokul121212121212")
            
        }
        
    }
    
    func fetchData() {
        guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=1") else { return }
        
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

@ViewBuilder
func AnimatedChart(item: [Food]) -> some View {
    Chart {
        ForEach(Array(item.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Date", index),
                y: .value("Value", value.price)
           
            )
        }
    }
}
struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverCoinView(viewModel: .init(title: "Bitcoin", subtitle: "$40,000"))
    }
}
