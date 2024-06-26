//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore

class GraphQLRequestModelTest: XCTestCase {

    /// - Given: a `Model` instance
    /// - When:
    ///   - the model is a `Post`
    ///   - the mutation is of type `.create`
    /// - Then:
    ///   - check if the `GraphQLRequest` is valid:
    ///     - the `document` has the right content
    ///     - the `responseType` is correct
    ///     - the `variables` is non-nil
    func testCreateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .create))
        documentBuilder.add(decorator: ModelDecorator(model: post, mutationType: .create))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.create(post, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testUpdateMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .update))
        documentBuilder.add(decorator: ModelDecorator(model: post, mutationType: .update))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.update(post, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testDeleteMutationGraphQLRequest() {
        let post = Post(title: "title", content: "content", createdAt: .now())
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .mutation)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .delete))
        documentBuilder.add(decorator: ModelDecorator(model: post, mutationType: .delete))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.delete(post, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        XCTAssert(request.variables != nil)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testQueryByIdGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .get))
        documentBuilder.add(decorator: ModelIdDecorator(id: "id"))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.get(Post.self, byId: "id", authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post?.self)
        XCTAssert(request.variables != nil)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter))
        documentBuilder.add(decorator: PaginationDecorator())
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.list(Post.self, where: predicate, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == List<Post>.self)
        XCTAssertNotNil(request.variables)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testPaginatedListQueryGraphQLRequest() {
        let post = Post.keys
        let predicate = post.id.eq("id") && (post.title.beginsWith("Title") || post.content.contains("content"))

        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .query)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .list))
        documentBuilder.add(decorator: FilterDecorator(filter: predicate.graphQLFilter(for: Post.schema)))
        documentBuilder.add(decorator: PaginationDecorator(limit: 10))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.list(Post.self, where: predicate, limit: 10, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == List<Post>.self)
        XCTAssertNotNil(request.variables)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testOnCreateSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onCreate))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onCreate, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testOnUpdateSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onUpdate))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onUpdate, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    func testOnDeleteSubscriptionGraphQLRequest() {
        var documentBuilder = ModelBasedGraphQLDocumentBuilder(modelSchema: Post.schema, operationType: .subscription)
        documentBuilder.add(decorator: DirectiveNameDecorator(type: .onDelete))
        let document = documentBuilder.build()

        let request = GraphQLRequest<Post>.subscription(of: Post.self, type: .onDelete, authMode: .amazonCognitoUserPools)

        XCTAssertEqual(document.stringValue, request.document)
        XCTAssert(request.responseType == Post.self)
        assertEquals(actualAuthMode: request.authMode, expectedAuthMode: .amazonCognitoUserPools)
    }

    // MARK: - Helpers

    func assertEquals(actualAuthMode: AuthorizationMode?, expectedAuthMode: AWSAuthorizationType) {
        guard let authMode = actualAuthMode as? AWSAuthorizationType else {
            XCTFail("Missing authorizationMode on request")
            return
        }
        XCTAssertEqual(authMode, expectedAuthMode)
    }
}
