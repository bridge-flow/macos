import Foundation

enum BridgeFlowResources {
    static let bundle: Bundle = {
        let packagedBundle = Bundle.main.resourceURL?.appendingPathComponent("BridgeFlow_BridgeFlow.bundle")

        if let packagedBundle, let bundle = Bundle(url: packagedBundle) {
            return bundle
        }

        return .module
    }()
}
