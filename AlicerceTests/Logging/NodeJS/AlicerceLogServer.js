//
//  AlicerceLogServer.swift
//  AlicerceTests
//
//  Simple Node.js server listening to HTTP POST requests being sent from the
//  Alicerce Node Log Destination.
//
//  Created by Meik Schutz on 03/04/17.
//  Copyright © 2017 Mindera. All rights reserved.
//
var http = require('http');

const PORT = 8080;

function handleRequest(request, response) {
    if (request.method == 'POST') {
        
        var body = "";
        request.on('readable', function() {
                   body += request.read();
                   });
        
        request.on('end', function() {
                   console.log(body);
                   response.write("OK");
                   response.end();
                   });
    }
}

var server = http.createServer(handleRequest);
server.listen(PORT, function() {
              console.log("Server listening on: http://localhost:%s", PORT);
              });
