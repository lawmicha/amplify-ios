// swiftlint:disable all
import Amplify
import Foundation

public struct Team1: Model {
  public let teamId: String
  public let name: String
  public var project: Project1?
  public var createdAt: Temporal.DateTime?
  public var updatedAt: Temporal.DateTime?
  
  public init(teamId: String,
      name: String,
      project: Project1? = nil) {
    self.init(teamId: teamId,
      name: name,
      project: project,
      createdAt: nil,
      updatedAt: nil)
  }
  internal init(teamId: String,
      name: String,
      project: Project1? = nil,
      createdAt: Temporal.DateTime? = nil,
      updatedAt: Temporal.DateTime? = nil) {
      self.teamId = teamId
      self.name = name
      self.project = project
      self.createdAt = createdAt
      self.updatedAt = updatedAt
  }
}