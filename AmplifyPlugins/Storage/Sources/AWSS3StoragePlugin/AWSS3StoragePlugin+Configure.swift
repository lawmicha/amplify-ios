//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@_spi(InternalAmplifyConfiguration) import Amplify
import AWSPluginsCore

extension AWSS3StoragePlugin {

    /// Configures AWSS3StoragePlugin with the specified configuration.
    ///
    /// This method will be invoked as part of the Amplify configuration flow. Retrieves the bucket, region, and
    /// default configuration values to allow overrides on plugin API calls.
    ///
    /// - Parameter configuration: The configuration specified for this plugin
    /// - Throws:
    ///   - `PluginError` is thrown if the AmplifyConfiguration is an invalid JSON, or AmplifyOutputsData's `storage` category is missing.
    ///   - `PluginError` is wrapped as the underlying error of a `StorageError` for other validation logic related to retrieving
    ///   configuration fields such as `region` and `bucket`.
    ///
    /// - Tag: AWSS3StoragePlugin.configure
    public func configure(using configuration: Any?) throws {
        let configClosures: ConfigurationClosures
        if let config = configuration as? AmplifyOutputsData {
            configClosures = try retrieveConfiguration(config)
        } else if let config = configuration as? JSONValue {
            configClosures = try retrieveConfiguration(config)
        } else {
            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.decodeConfigurationError.errorDescription,
                PluginErrorConstants.decodeConfigurationError.recoverySuggestion)
        }

        do {
            let authService = AWSAuthService()
            let storageService = try AWSS3StorageService(authService: authService,
                                                         region: configClosures.retrieveRegion(),
                                                         bucket: configClosures.retrieveBucket(),
                                                         httpClientEngineProxy: self.httpClientEngineProxy)
            storageService.urlRequestDelegate = self.urlRequestDelegate

            configure(storageService: storageService, 
                      authService: authService,
                      defaultAccessLevel: try configClosures.retrieveDefaultAccessLevel())
        } catch let storageError as StorageError {
            throw storageError
        } catch {
            let amplifyError = StorageError.configuration(
                "Error configuring \(String(describing: self))",
                """
                There was an error configuring the plugin. See the underlying error for more details.
                """,
                error)
            throw amplifyError
        }
    }

    // MARK: Internal

    /// Internal configure method to set the properties of the plugin
    ///
    /// Called from the configure method which implements the Plugin protocol. Useful for testing by passing in mocks.
    ///
    /// - Parameters:
    ///   - storageService: The S3 storage service object.
    ///   - authService: The authentication service object.
    ///   - defaultAccessLevel: The access level to be used for all API calls by default.
    ///   - queue: The queue which operations are stored and dispatched for asychronous processing.
    func configure(storageService: AWSS3StorageServiceBehavior,
                   authService: AWSAuthServiceBehavior,
                   defaultAccessLevel: StorageAccessLevel,
                   queue: OperationQueue = OperationQueue()) {
        self.storageService = storageService
        self.authService = authService
        self.queue = queue
        self.defaultAccessLevel = defaultAccessLevel
    }

    // MARK: Private helper methods

    private struct ConfigurationClosures {
        let retrieveRegion: () throws -> String
        let retrieveBucket: () throws -> String
        let retrieveDefaultAccessLevel: () throws -> StorageAccessLevel
    }

    private func retrieveConfiguration(_ configuration: AmplifyOutputsData) throws -> ConfigurationClosures {
        guard let storage = configuration.storage else {
            throw PluginError.pluginConfigurationError(
                PluginErrorConstants.missingStorageCategoryConfiguration.errorDescription,
                PluginErrorConstants.missingStorageCategoryConfiguration.recoverySuggestion)
        }

        let regionClosure = {
            try AWSS3StoragePlugin.validateRegionNonEmpty(storage.awsRegion)
            return storage.awsRegion
        }

        let bucketClosure = {
            try AWSS3StoragePlugin.validateBucketNonEmpty(storage.bucketName)
            return storage.bucketName
        }

        return ConfigurationClosures(retrieveRegion: regionClosure,
                                     retrieveBucket: bucketClosure,
                                     retrieveDefaultAccessLevel: { .guest })
    }

    private func retrieveConfiguration(_ configuration: JSONValue) throws -> ConfigurationClosures {
        guard case let .object(configObject) = configuration else {
            throw StorageError.configuration(
                PluginErrorConstants.configurationObjectExpected.errorDescription,
                PluginErrorConstants.configurationObjectExpected.recoverySuggestion)
        }

        let regionClosure = { try AWSS3StoragePlugin.getRegion(configObject) }
        let bucketClosure = { try AWSS3StoragePlugin.getBucket(configObject) }
        let defaultAccessLevelClosure = { try AWSS3StoragePlugin.getDefaultAccessLevel(configObject) }

        return ConfigurationClosures(retrieveRegion: regionClosure,
                                     retrieveBucket: bucketClosure,
                                     retrieveDefaultAccessLevel: defaultAccessLevelClosure)
    }

    /// Retrieves the region from configuration, validates, and returns it.
    private static func getRegion(_ configuration: [String: JSONValue]) throws -> String {
        guard let region = configuration[PluginConstants.region] else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.missingRegion.errorDescription,
                                                       PluginErrorConstants.missingRegion.recoverySuggestion)
        }

        guard case let .string(regionValue) = region else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.invalidRegion.errorDescription,
                                                       PluginErrorConstants.invalidRegion.recoverySuggestion)
        }

        try validateRegionNonEmpty(regionValue)

        return regionValue
    }

    private static func validateRegionNonEmpty(_ region: String) throws {
        if region.isEmpty {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.emptyRegion.errorDescription,
                                                       PluginErrorConstants.emptyRegion.recoverySuggestion)
        }
    }

    /// Retrieves the bucket from configuration, validates, and returns it.
    private static func getBucket(_ configuration: [String: JSONValue]) throws -> String {
        guard let bucket = configuration[PluginConstants.bucket] else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.missingBucket.errorDescription,
                                                       PluginErrorConstants.missingBucket.recoverySuggestion)
        }

        guard case let .string(bucketValue) = bucket else {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.invalidBucket.errorDescription,
                                                       PluginErrorConstants.invalidBucket.recoverySuggestion)
        }

        try validateBucketNonEmpty(bucketValue)

        return bucketValue
    }

    private static func validateBucketNonEmpty(_ bucket: String) throws {
        if bucket.isEmpty {
            throw PluginError.pluginConfigurationError(PluginErrorConstants.emptyBucket.errorDescription,
                                                       PluginErrorConstants.emptyBucket.recoverySuggestion)
        }
    }

    /// Checks if the access level is specified in the configurationand and retrieves it. Returns the default
    /// public access level if none is found in the configuration.
    private static func getDefaultAccessLevel(_ configuration: [String: JSONValue]) throws -> StorageAccessLevel {
        if let defaultAccessLevelConfig = configuration[PluginConstants.defaultAccessLevel] {
            guard case let .string(defaultAccessLevelString) = defaultAccessLevelConfig else {
                throw PluginError.pluginConfigurationError(
                    PluginErrorConstants.invalidDefaultAccessLevel.errorDescription,
                    PluginErrorConstants.invalidDefaultAccessLevel.recoverySuggestion)
            }

            let defaultAccessLevelOptional = StorageAccessLevel.init(rawValue: defaultAccessLevelString)
            guard let defaultAccessLevel = defaultAccessLevelOptional else {
                throw PluginError.pluginConfigurationError(
                    PluginErrorConstants.invalidDefaultAccessLevel.errorDescription,
                    PluginErrorConstants.invalidDefaultAccessLevel.recoverySuggestion)
            }

            return defaultAccessLevel
        }

        return .guest
    }
}
