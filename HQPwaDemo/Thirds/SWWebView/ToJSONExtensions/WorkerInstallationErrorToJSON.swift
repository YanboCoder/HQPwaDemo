import Foundation

extension WorkerInstallationError: ToJSON {
    func toJSONSuitableObject() -> Any {
        return [
            "error": String(describing: self.error),
            "worker": self.worker.toJSONSuitableObject()
        ]
    }
}
