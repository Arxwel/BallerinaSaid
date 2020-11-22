import ballerina/config;
import ballerina/http;
import ballerina/io;
import wso2/twitter;

//Fonction qui va tweeter la chaine de caractères passée en paramètre
public function postTweet(string quote) {
        // Création du client Twitter qui va poster le tweet
        // On récupère les données depuis le fichier de configuration
        twitter:Client twitterClient = new ({
            clientId: config:getAsString("clientId"),
            clientSecret: config:getAsString("clientSecret"),
            accessToken: config:getAsString("accessToken"),
            accessTokenSecret: config:getAsString("accessTokenSecret"),
            clientConfig: {}
        });

        //On essaye d'envoyer le Tweet
        var result = twitterClient->tweet(quote + " #Ballerina");

        //Si l'envoie a réussi, le résultat a pour type un statut Twitter
        if (result is twitter:Status) {
            // On affiche l'ID du tweet créé ainsi que son contenu dans le terminal
            io:println("Tweet ID : ", result.id);
            io:println("Tweet : ", result.text);
        } else {
        // Si l'envoie est un echec, on affiche le message d'erreur dans le terminal
            io:println("Erreur : ", result);
        }
    } 

//Fonction qui récupère une citation depuis le connecteur c et l'envoie au demandeur caller
public function getQuote(http:Client c, http:Caller caller) {
    //On effectue une requête API au endpoint "/" commun à nos deux APIs
    var response = c->get("/");

    //Si la requête a abouti
    if(response is http:Response) {
        //On récupère le résultat au format JSON
        var msg = response.getJsonPayload();
        //Si msg n'est pas de type JSON c'est que la réponse n'était pas au format JSON, ce que l'on ne traite pas ici
        if (msg is json) {
            //On récupère la citation au format string
            string quote = <string> msg.quote;
            //On envoie le Tweet
            postTweet(quote);
            //On renvoie la citation comme réponse HTTP au demandeur
            var responseRes = caller->respond(<@untainted> quote);
        }
    } else {
        io:println("Erreur lors de la communication avec l'API : ", response.detail()?.message);
    }
}


//Création de notre microservice 
// Qui se situera au endpoint "/" et au port 9000
@http:ServiceConfig {
  basePath: "/"
}
service quote on new http:Listener(9000) {
    //Création de la ressource "Taylor" pour récupérer des citations de Taylor Swift
    //Qui se situera au endpoint "/taylor"
    @http:ResourceConfig {
      path: "/taylor",
      methods: ["GET"]
    } 
    resource function taylorQuote (http:Caller caller, http:Request request) returns @tainted error? {
        //On créé un connecteur à l'API de citation
        http:Client clientE = new ("https://api.taylor.rest");
        getQuote(clientE, caller);
    }

     //Création de la ressource "Kanye" pour récupérer des citations de Kanye West
    //Qui se situera au endpoint "/kanye"
    @http:ResourceConfig {
      path: "/kanye",
      methods: ["GET"]
    } 
    resource function kanyeQuote (http:Caller caller, http:Request request) returns @tainted error? {
        http:Client clientE = new ("https://api.kanye.rest");
        getQuote(clientE, caller);
    }
