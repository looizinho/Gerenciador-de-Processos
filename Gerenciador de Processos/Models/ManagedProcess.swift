import Foundation

enum ProcessStatus: String, Codable, Equatable {
    case running = "Running"
    case stopped = "Stopped"
}

struct ManagedProcess: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var command: String
    var arguments: String
    var status: ProcessStatus
    var pid: Int32?

    init(id: UUID = UUID(), name: String, command: String, arguments: String = "") {
        self.id = id
        self.name = name
        self.command = command
        self.arguments = arguments
        self.status = .stopped
        self.pid = nil
    }

    // Persiste apenas a configuração — status e PID são runtime
    enum CodingKeys: String, CodingKey {
        case id, name, command, arguments
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id        = try c.decode(UUID.self,   forKey: .id)
        name      = try c.decode(String.self, forKey: .name)
        command   = try c.decode(String.self, forKey: .command)
        arguments = try c.decode(String.self, forKey: .arguments)
        status    = .stopped
        pid       = nil
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(name,      forKey: .name)
        try c.encode(command,   forKey: .command)
        try c.encode(arguments, forKey: .arguments)
    }
}
