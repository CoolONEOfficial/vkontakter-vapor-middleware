//
//  File.swift
//  
//
//  Created by Givi on 18.02.2020.
//

import Vapor
import Vkontakter

public protocol VkontakterMiddleware: Middleware {
    var dispatcher: Dispatcher { get }
    var path: String { get }
    var bot: Bot { get }
}

public extension VkontakterMiddleware {
    func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        guard request.url.path == "/\(path)" else {
            return next.respond(to: request)
        }
        guard let body = request.body.data else {
            request.logger.critical("Received empty request from Vk Server")
            return next.respond(to: request)
        }

        dispatcher.enqueue(bytebuffer: body)

        return request.eventLoop.makeSucceededFuture(Response())
    }

    func setWebhooks() throws -> EventLoopFuture<Bool> {
        guard let config = bot.settings.webhooksConfig else {
            throw CoreError(
                type: .internal,
                reason: "Initialization parameters wasn't found in enviroment variables"
            )
        }

        let params = Bot.SetWebhookParams(url: config.url)
        return try bot.setWebhook(params: params)
    }
}
