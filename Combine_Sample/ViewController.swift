//
//  ViewController.swift
//  Combine_Sample
//
//  Created by Padmaja Pathada on 12/12/23.
//

import UIKit
import Combine

class ViewController: UIViewController {
    var cancellable: AnyCancellable?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        callNetworkManager()
    }

    func fetchData(url: URL, httpMethod: HTTPMethod, bodyData: Data?) -> AnyPublisher<ProductsResponse, Error> {
        
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .handleEvents(receiveSubscription: { _ in
                print("Subscribed to data task publisher")
            }, receiveOutput: { data, response in
                print("Received data:", data)
                print("Received response:", response)
            }, receiveCompletion: { completion in
                print("Received completion:", completion)
            }, receiveCancel: {
                print("Cancelled data task publisher")
            })
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
            let decoder = JSONDecoder()
                return try decoder.decode(ProductsResponse.self, from: data)
            }
            .handleEvents(receiveSubscription: { _ in
                print("Subscribed to tryMap")
            }, receiveCompletion: { completion in
                print("Received completion from tryMap:", completion)
            })
            
            .mapError { error in
                print("Error during decoding:", error)
                return error
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveCompletion: { completion in
                print("Received completion after retry:", completion)
            })
            .eraseToAnyPublisher()
             
    }

    func callNetworkManager() {
        let url = URL(string: "https://dummyjson.com/products")!
        
        //https://www.themealdb.com/api/json/v1/1/categories.php
        //https://dummyjson.com/products

        print("url: \(url)")
        cancellable = fetchData(url: url, httpMethod: .get, bodyData: nil)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .finished:
                    print("API call completed successfully")
                    break
                case .failure(let error):
                    print("Error: \(error)")
                }
            }, receiveValue: { (decodedData: ProductsResponse) in
                // Handle the decoded data
                print("Handling decoded data:", decodedData.products.count)

            })
    }

}



enum HTTPMethod: String {
case get = "GET"
case post = "POST"
}

struct ProductsResponse: Decodable {
    
    let products: [ProductInfo?]
    
}

struct ProductInfo: Decodable {
    
    let title: String?
    let description: String?
    let price: Int?
    let thumbnail: String?
    //let images: [String?]
    
}
struct UserInfo: Codable {
    
    let userId: Int?
    let id: Int?
    let completed: Bool?
    let title: String?
    //let images: [String?]
    
}
struct CategoriesResponse: Decodable {
    
    let Categories: [CategoryInfo?]
    
}

struct CategoryInfo: Decodable {
    
    let idCategory: String?
    let strCategory: String?
    let strCategoryThumb: String?
    let strCategoryDescription: String?
    
}
