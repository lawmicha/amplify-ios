//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Amplify

/// Decorate the GraphQLDocument with the value of `Model.Identifier` for a "delete" mutation or "get" query.
public struct ModelIdDecorator: ModelBasedGraphQLDocumentDecorator {

    //private let id: Model.Identifier
    private let input: ModelIdDecoratorInput

    public enum ModelIdDecoratorInput {
        case delete(Model)
        case queryById(Model.Identifier)
        case query([String: Model.Identifier])
    }
    
    public init(_ input: ModelIdDecoratorInput) {
        self.input = input
    }
    
    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelType: Model.Type) -> SingleDirectiveGraphQLDocument {
        decorate(document, modelSchema: modelType.schema)
    }

    public func decorate(_ document: SingleDirectiveGraphQLDocument,
                         modelSchema: ModelSchema) -> SingleDirectiveGraphQLDocument {
        var inputs = document.inputs

        if case .delete(let model) = input {
        // if case .mutation = document.operationType {
            if let customPrimaryKeys = modelSchema.customPrimaryIndexFields {
                var objectMap = [String: Any?]()
                // let graphQLInput = model.graphQLInputForMutation(modelSchema)
                for key in customPrimaryKeys {
                    objectMap[key] = model[key]
                }
                //
                inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                       value: .object(objectMap))
                
                return document.copy(inputs: inputs)
            } else {
                inputs["input"] = GraphQLDocumentInput(type: "\(document.name.pascalCased())Input!",
                                                       value: .object(["id": model.id]))
            }
        } else if case .query(let id) = input {
        //else if case .query = document.operationType {
            if let customPrimaryKeys = modelSchema.customPrimaryIndexFields {
                

                if let first = customPrimaryKeys.first {
                    // Q. what is the type defiition? is it `\(first)!`
                    inputs[first] = GraphQLDocumentInput(type: "ID!", value: .scalar(id))
                }
                
            }
            inputs["id"] = GraphQLDocumentInput(type: "ID!", value: .scalar(id))
        }

        return document.copy(inputs: inputs)
    }
}
