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
  var path: String
  var environment: String
  var action: String
  var autoStart: Bool
  var status: ProcessStatus
  var pid: Int32?
  
  /// Saída capturada (stdout + stderr) — apenas runtime, não persistida.
  var output: String
  /// Razão humana do último término — apenas runtime, não persistida.
  var exitReason: String
  
  init(id: UUID = UUID(), name: String, command: String, arguments: String = "", path: String = "", environment: String = "", action: String = "", autoStart: Bool = false) {
    self.id = id
    self.name = name
    self.command = command
    self.arguments = arguments
    self.path = path
    self.environment = environment
    self.action = action
    self.autoStart = autoStart
    self.status = .stopped
    self.pid = nil
    self.output = ""
    self.exitReason = ""
  }
  
  // Persiste apenas a configuração — status, PID, output e exitReason são runtime
  enum CodingKeys: String, Codable, CodingKey {
    case id, name, command, arguments, path, environment, action, autoStart
  }
  
  init(from decoder: Decoder) throws {
    let c = try decoder.container(keyedBy: CodingKeys.self)
    id        = try c.decode(UUID.self,   forKey: .id)
    name      = try c.decode(String.self, forKey: .name)
    command   = try c.decode(String.self, forKey: .command)
    arguments = try c.decode(String.self, forKey: .arguments)
    path      = try c.decodeIfPresent(String.self, forKey: .path) ?? ""
    environment = try c.decodeIfPresent(String.self, forKey: .environment) ?? ""
    action    = try c.decodeIfPresent(String.self, forKey: .action) ?? ""
    autoStart = try c.decodeIfPresent(Bool.self, forKey: .autoStart) ?? false
    status    = .stopped
    pid       = nil
    output    = ""
    exitReason = ""
  }
  
  func encode(to encoder: Encoder) throws {
    var c = encoder.container(keyedBy: CodingKeys.self)
    try c.encode(id,        forKey: .id)
    try c.encode(name,      forKey: .name)
    try c.encode(command,   forKey: .command)
    try c.encode(arguments, forKey: .arguments)
    try c.encode(path,      forKey: .path)
    try c.encode(environment, forKey: .environment)
    try c.encode(action,    forKey: .action)
    try c.encode(autoStart, forKey: .autoStart)
  }
}
