//
//  WeatherManager.swift
//  Clima
//
//  Created by AtsushiAdachi on 2020/07/12.
//  Copyright © 2020 App Brewery. All rights reserved.
//

import Foundation
import CoreLocation

protocol WeatherManagerDelegate {
    func didUpdateWeather(_ weatherManager: WeatherManager, weather: WeatherModel)
    func didFailWithError(error: Error)
}

struct WeatherManager {
    // API呼び出し時に発行するURL
    let weatherURL = "https://api.openweathermap.org/data/2.5/weather?appid=f97dca5b9dfed64e9e83ee9a13dc5099&units=metric"
    
    var delegate: WeatherManagerDelegate?
    
    // URLの生成とネットワーキングの実行を担う
    func fetchWeather(cityName: String) {
        // URLの生成
        let urlString = "\(weatherURL)&q=\(cityName)"
        
        // ネットワーキングの実行
        performRequest(with: urlString)
    }
    
    func fetchWeather(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        let urlString = "\(weatherURL)&lat=\(latitude)&lon=\(longitude)"
        performRequest(with: urlString)
    }
    
    // URLの生成後、URLセッションを作成し
    func performRequest(with urlString: String) {
        // URLを生成できた場合
        if let url = URL(string: urlString) {
            // URLセッションの作成
            let session = URLSession(configuration: .default)
            
            // セッションにタスクを渡す
            let task = session.dataTask(with: url) { (data, responce, error) in
                if error != nil {
                    self.delegate?.didFailWithError(error: error!)
                    return
                }
                // データが存在する場合
                if let safeData = data {
                    // 気象情報が存在した場合
                    if let weather = self.parseJSON(safeData) {
                        self.delegate?.didUpdateWeather(self, weather: weather)
                    }
                }
            }
            // タスクの実行
            task.resume()
        }
    }
    
    func parseJSON(_ weatherData: Data) -> WeatherModel? {
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(WeatherData.self, from: weatherData)
            let id = decodedData.weather[0].id
            let temp = decodedData.main.temp
            let name = decodedData.name
            
            // 気象情報モデルを生成
            let weather = WeatherModel(conditionId: id, cityName: name, temperature: temp)
            return weather
        } catch {
            delegate?.didFailWithError(error: error)
            return nil
        }
    }
}
