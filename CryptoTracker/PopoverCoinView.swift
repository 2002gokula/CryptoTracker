//
//  PopoverCoinView.swift
//  CryptoTracker
//
//  Created by Alfian Losari on 03/02/22.
//

import SwiftUI
import Charts
struct MonthlyHoursOfSunshine {
    var date: Date
    var id = UUID()
    var hoursOfSunshine: Double


    init(month: Int, hoursOfSunshine: Double) {
        let calendar = Calendar.autoupdatingCurrent
        self.date = calendar.date(from: DateComponents(year: 2020, month: month))!
        self.hoursOfSunshine = hoursOfSunshine
    }
}


var data: [MonthlyHoursOfSunshine] = [
    MonthlyHoursOfSunshine(month: 1, hoursOfSunshine: 74),
    MonthlyHoursOfSunshine(month: 2, hoursOfSunshine: 99),
    
    MonthlyHoursOfSunshine(month: 12, hoursOfSunshine: 62),    MonthlyHoursOfSunshine(month: 12, hoursOfSunshine: 62),    MonthlyHoursOfSunshine(month: 12, hoursOfSunshine: 62),    MonthlyHoursOfSunshine(month: 12, hoursOfSunshine: 62),   MonthlyHoursOfSunshine(month: 12, hoursOfSunshine: 62)
]
struct PriceChart: Codable {
    let prices, marketCaps, totalVolumes: [[Double]]
    var id = UUID()
    enum CodingKeys: String, CodingKey {
        case prices
        case marketCaps = "market_caps"
        case totalVolumes = "total_volumes"
    }
}



struct PopoverCoinView: View {
    
    @ObservedObject var viewModel: PopoverCoinViewModel
    @State var currentTab: String = "7 Days"
    @State private var chartData: [PriceChart] = [] // Replace YourDataModel with your actual data model
//       var viewModel: YourViewModel
    
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
           
                
                AnimatedChart(item: chartData)
            }
           
            Button("Quit") {
                NSApp.terminate(self)
            }
              
        }
        .onChange(of: viewModel.selectedCoinType) { _ in
            viewModel.updateView()
            fetchData()
            print(chartData.enumerated().map { (index, item) in
                item
            }, "gokul121212121212")
        }
        .onAppear {
            viewModel.subscribeToService()
            fetchData()
            print(chartData.enumerated().map { (index, item) in
                item
            }, "gokul121212121212")
            
        }
        
    }
    
    func fetchData() {
           guard let url = URL(string: "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart?vs_currency=usd&days=1") else {
               return
           }

           URLSession.shared.dataTask(with: url) { data, response, error in
               guard let data = data, error == nil else {
                   return
               }

               do {
                   let decoder = JSONDecoder()
                   let result = try decoder.decode(PriceChart.self, from: data)
                   DispatchQueue.main.async {
                       self.chartData = result
                   }
               } catch {
                   print(error.localizedDescription)
               }
           }.resume()
       }}

@ViewBuilder
func AnimatedChart(item: [PriceChart]) -> some View {
    Chart {
               ForEach(Array(item.enumerated()), id: \.offset) { index, value in
                   LineMark(
                    x: .value("Index", value.prices[index][0]),
                       y: .value("Value", value.prices[index][0])
                   )
               }
           }
}
struct PopoverCoinView_Previews: PreviewProvider {
    static var previews: some View {
        PopoverCoinView(viewModel: .init(title: "Bitcoin", subtitle: "$40,000"))
    }
}
