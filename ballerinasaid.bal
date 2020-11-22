import ballerina/config;
import ballerina/http;
import ballerina/io;
import wso2/twitter;

public function postTweet(string quote) {
        twitter:Client twitterClient = new ({
            clientId: config:getAsString("clientId"),
            clientSecret: config:getAsString("clientSecret"),
            accessToken: config:getAsString("accessToken"),
            accessTokenSecret: config:getAsString("accessTokenSecret"),
            clientConfig: {}
        });

        var result = twitterClient->tweet(quote + " #Ballerina");
        io:println(result);

        if (result is twitter:Status) {
        // If successful, print the tweet ID and text.
            io:println("Tweet ID: ", result.id);
            io:println("Tweet: ", result.text);
        } else {
        // If unsuccessful, print the error returned.
            io:println("Error: ", result);
        }
    } 

public function postQuote(http:Client c, http:Caller caller) {
    var response = c->get("/");

    if(response is http:Response) {
        var msg = response.getJsonPayload();
        if (msg is json) {
            string quote = <string> msg.quote;
            io:println("Quote: " + quote);
            postTweet(quote);
            var responseRes = caller->respond(<@untainted> quote);
        }
    } else {
        io:println("Error when calling the backend: ",
                                    response.detail()?.message);
    }
}

@http:ServiceConfig {
  basePath: "/"
}
service quote on new http:Listener(9000) {

    @http:ResourceConfig {
      path: "/taylor",
      methods: ["GET"]
    } 
    resource function taylorQuote (http:Caller caller, http:Request request) returns @tainted error? {
        http:Client clientE = new ("https://api.taylor.rest");
        postQuote(clientE, caller);
    }

    @http:ResourceConfig {
      path: "/kanye",
      methods: ["GET"]
    } 
    resource function kanyeQuote (http:Caller caller, http:Request request) returns @tainted error? {
        http:Client clientE = new ("https://api.kanye.rest");
        postQuote(clientE, caller);
    }

}


public function main() {
   io:println("coucou");
}