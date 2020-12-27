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
        
        let update = dispatcher.enqueue(bytebuffer: body)

        let bodyContent: String
        if update?.type == .confirmation, let code = bot.confirmationCode {
            bot.confirmationCode = nil
            request.logger.debug(.init(stringLiteral: "Returning confirmationCode"))
            bodyContent = code
        } else {
            bodyContent = "ok"
        }

        return request.eventLoop.makeSucceededFuture(Response.init(status: .ok, version: request.version, headers: .init(), body: .init(string: bodyContent)))
    }
    
    
}
