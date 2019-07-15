import BitcoinCore

class Configuration {
    static let shared = Configuration()

    let minLogLevel: Logger.Level = .error
    let testNet = true
    let mainNet = false
    let defaultWords = [
        "used ugly meat glad balance divorce inner artwork hire invest already piano",
        "clock economy moon breeze wood trust obtain scan sing gift frog else",
        "current force clump paper shrug extra zebra employ prefer upon mobile hire",
        "popular game latin harvest silly excess much valid elegant illness edge silk",
    ]

}
