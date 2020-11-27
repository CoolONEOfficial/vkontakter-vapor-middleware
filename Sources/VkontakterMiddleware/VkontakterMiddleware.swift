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

        if let code = bot.confirmationCode {
            debugPrint("Returnong confirmationCode")
            return request.eventLoop.makeSucceededFuture(Response(
                status: .ok, version: request.version,
                headers: request.headers, body: .init(string: code)
            ))
        }
        
        return request.eventLoop.makeSucceededFuture(Response())
    }
    
    private func updateConfirmationCode(_ groupId: UInt64) throws -> EventLoopFuture<Bot.GetCallbackConfirmationCodeResp> {
        try bot.getCallbackConfirmationCode(params: .init(groupId: groupId)).flatMapThrowing { resp in
            bot.confirmationCode = resp.code
            return resp
        }
    }
    
    private func createServer(_ groupId: UInt64, _ serverUrl: String, serverName: String?) throws -> EventLoopFuture<Bot.AddCallbackServerResp> {
        var serverName = serverName
        if serverName == nil {
            print("Enter name for new VK callback API server: ")
            serverName = readLine()!
        }
        
        return try bot.addCallbackServer(params: .init(
            groupId: groupId, url: serverUrl,
            title: serverName!, secretKey: "testsecret"
        ))
    }
    
    private func setServerSettings(_ groupId: UInt64, _ serverUrl: String, _ serverId: UInt64) throws -> EventLoopFuture<VkFlag> {
        try bot.setCallbackSettings(params: .init(
            groupId: groupId, serverId: serverId,
            apiVersion: .v5_126, messageNew: .on
        ))
    }

    func setWebhooks(_ serverName: String?) throws -> EventLoopFuture<Void> {
        guard let config = bot.settings.webhooksConfig, let groupId = config.groupId else {
            throw CoreError(
                type: .internal,
                reason: "Initialization parameters (with groupId) wasn't found in enviroment variables"
            )
        }

        return try bot.getCallbackServers(params: .init(groupId: groupId)).flatMapThrowing { serversResp in
            let servers = serversResp.items
            let serverUrl = config.url + "/" + path

            let allSteps: (() throws -> Void) = {
                try updateConfirmationCode(groupId).flatMapThrowing { resp in
                    try createServer(groupId, serverUrl, serverName: serverName).flatMapThrowing { resp in
                        try setServerSettings(groupId, serverUrl, resp.serverId)
                    }
                }
            }

            if let matchServer = servers.first(where: { $0.url == serverUrl }) {
                if matchServer.status != .ok {
                    debugPrint("Server founded but status is \(matchServer.status.rawValue) on Callback API")
                    try bot.deleteCallbackServer(params: .init(groupId: groupId, serverId: matchServer.id)).flatMapThrowing { flag in
                        assert(flag.bool)
                        try allSteps()
                    }
                } else {
                    debugPrint("Server already configured on Callback API")
                }
            } else {
                debugPrint("Server not found on Callback API")
                try allSteps()
            }
        }
    }
}
