using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Azure;
using Azure.AI.TextAnalytics;
using Newtonsoft.Json.Linq;
using System.Text;

namespace TranslateText.Pages;

public class IndexModel : PageModel
{
    private readonly IConfiguration _configuration;
    private readonly string _cognitiveServicesKey;

    public IndexModel(IConfiguration configuration)
    {
        _configuration = configuration;
        _cognitiveServicesKey = _configuration.GetValue<string>("CognitiveServiceKey") ?? "KEY NOT SET";;
    }

    public async Task<IActionResult> OnPostProcessInputAsync(string InputText, string submit)
    {
        // Process the input text
        string originalText = InputText;

        // Set the original text to output
        ViewData["OriginalText"] = originalText;

        // Set up the Text Analytics client
        string cognitiveServicesEndpoint = _configuration.GetValue<string>("CognitiveServiceEndpoint") ?? "ENDPOINT NOT SET";

        // SDK
        if(submit == "SDK")
        {
            AzureKeyCredential credentials = new (_cognitiveServicesKey);
            Uri endpoint = new(cognitiveServicesEndpoint);
            TextAnalyticsClient client = new(endpoint, credentials);

            // Get language
            DetectedLanguage language = client.DetectLanguage(originalText);

            // Set the language information to output
            ViewData["Language"] = language.Name;
            ViewData["LanguageConfidence"] = language.ConfidenceScore;

            // Get sentiment
            DocumentSentiment sentiment = client.AnalyzeSentiment(originalText);

            // Set the sentiment information to output
            ViewData["Sentiment"] = sentiment.Sentiment;
            ViewData["SentimentPositive"] = sentiment.ConfidenceScores.Positive;
            ViewData["SentimentNeutral"] = sentiment.ConfidenceScores.Neutral;
            ViewData["SentimentNegative"] = sentiment.ConfidenceScores.Negative;

            // Get key phrases
            KeyPhraseCollection keyPhrases = client.ExtractKeyPhrases(originalText);
            string phrases = null;
            if(keyPhrases.Count > 0)
            {
                phrases = string.Join(", ", keyPhrases);
            }
            else
            {
                Console.WriteLine("No key phrases were detected.");
            }
            ViewData["KeyPhrases"] = phrases;

            // Get entities
            CategorizedEntityCollection entities = client.RecognizeEntities(originalText);
            List<CategorizedEntity> entitiesList = new();
            if(entities.Count > 0)
            {
                foreach (CategorizedEntity entity in entities)
                {
                    entitiesList.Add(entity);
                }
            }
            else
            {
                Console.WriteLine("No entities were detected.");
                entitiesList = null;
            }
            ViewData["Entities"] = entitiesList;

            // Get linked entities
            LinkedEntityCollection linkedEntities = client.RecognizeLinkedEntities(originalText);
            List<LinkedEntity> linkedEntitiesList = new();
            if(linkedEntities.Count > 0)
            {
                foreach (LinkedEntity linkedEntity in linkedEntities)
                {
                    linkedEntitiesList.Add(linkedEntity);
                }
            }
            else
            {
                Console.WriteLine("No linked entities were detected.");
                linkedEntitiesList = null;
            }
            ViewData["LinkedEntities"] = linkedEntitiesList;    

            // Get summary
            if(Request.Form["Summarise"].Contains("on"))
            {
                List<string> document = new()
                {
                    originalText
                };
                AbstractiveSummarizeOperation operation = client.AbstractiveSummarize(WaitUntil.Completed, document);

                // View summary operation result
                foreach (AbstractiveSummarizeResultCollection docsInPage in operation.GetValues())
                {
                    foreach(AbstractiveSummarizeResult docResult in docsInPage)
                    {
                        if(docResult.HasError)
                        {
                            Console.WriteLine("Error!");
                            Console.WriteLine($"  Document error: {docResult.Error.ErrorCode}.");
                            Console.WriteLine($"  Message: {docResult.Error.Message}.");
                            continue;
                        }

                        foreach(AbstractiveSummary summary in docResult.Summaries)
                        {
                            ViewData["Summary"] = summary.Text.Replace("\n", " ");
                        }
                    }
                }
            }

            // PII detection
            if(Request.Form["DetectPII"].Contains("on"))
            {
                Response<PiiEntityCollection> piiResponse = client.RecognizePiiEntities(originalText, "en", new RecognizePiiEntitiesOptions { CategoriesFilter = { PiiEntityCategory.Email, PiiEntityCategory.PhoneNumber } });
                PiiEntityCollection piiEntities = piiResponse.Value;
                if(piiEntities.Count > 0)
                {
                    ViewData["RedactedText"] = piiEntities.RedactedText;
                }
                else
                {
                    Console.WriteLine("No PII entities were detected.");
                }
            }
        }
        
        // REST
        else if(submit == "REST")
        {

            string languageEndpoint = $"{cognitiveServicesEndpoint}language/:analyze-text?api-version=2023-04-01";
            
            // Get language
            RestResponse result = await RestRequest(languageEndpoint, originalText, "LanguageDetection");

            // Parse the JSON response and get the language
            JObject json = JObject.Parse(result.Result);
            
            string? language = json["results"]?["documents"]?[0]?["detectedLanguage"]?["name"]?.ToString();
            string? languageConfidence = json["results"]?["documents"]?[0]?["detectedLanguage"]?["confidenceScore"]?.ToString();

            // Set the language information to output
            ViewData["Language"] = language;
            ViewData["LanguageConfidence"] = languageConfidence;
            ViewData["LanguageMethod"] = result.Method;
            ViewData["LanguageUri"] = result.Uri;
            ViewData["LanguageBody"] = JToken.Parse(result.Body);
            ViewData["LanguageResponse"] = json;

            // Get sentiment
            RestResponse sentimentResult = await RestRequest(languageEndpoint, originalText, "SentimentAnalysis");
            
            // Parse the JSON response and get the sentiment
            JObject sentimentJson = JObject.Parse(sentimentResult.Result);
            string? sentiment = sentimentJson["results"]?["documents"]?[0]?["sentiment"]?.ToString();
            string? sentimentPositive = sentimentJson["results"]?["documents"]?[0]?["confidenceScores"]?["positive"]?.ToString();
            string? sentimentNeutral = sentimentJson["results"]?["documents"]?[0]?["confidenceScores"]?["neutral"]?.ToString();
            string? sentimentNegative = sentimentJson["results"]?["documents"]?[0]?["confidenceScores"]?["negative"]?.ToString();

            // Set the sentiment information to output
            ViewData["Sentiment"] = sentiment;
            ViewData["SentimentPositive"] = sentimentPositive;
            ViewData["SentimentNeutral"] = sentimentNeutral;
            ViewData["SentimentNegative"] = sentimentNegative;
            ViewData["SentimentMethod"] = sentimentResult.Method;
            ViewData["SentimentUri"] = sentimentResult.Uri;
            ViewData["SentimentBody"] = JToken.Parse(sentimentResult.Body);
            ViewData["SentimentResponse"] = sentimentJson;

            // Get key phrases
            RestResponse keyPhrasesResult = await RestRequest(languageEndpoint, originalText, "KeyPhraseExtraction");

            // Parse the JSON response and get the key phrases
            JObject keyPhrasesJson = JObject.Parse(keyPhrasesResult.Result);
            string? phrases = null;
            if(keyPhrasesJson["results"]?["documents"]?[0]?["keyPhrases"]?.Count() > 0)
            {
                phrases = string.Join(", ", keyPhrasesJson["results"]?["documents"]?[0]?["keyPhrases"]);
            }
            else
            {
                Console.WriteLine("No key phrases were detected.");
            }
            ViewData["KeyPhrases"] = phrases;
            ViewData["keyPhrasesMethod"] = keyPhrasesResult.Method;
            ViewData["keyPhrasesUri"] = keyPhrasesResult.Uri;
            ViewData["keyPhrasesBody"] = JToken.Parse(keyPhrasesResult.Body);
            ViewData["keyPhrasesResponse"] = keyPhrasesJson;

            // Get entities
            RestResponse entitiesResult = await RestRequest(languageEndpoint, originalText, "EntityRecognition");

            // Parse the JSON response and get the entities
            JObject entitiesJson = JObject.Parse(entitiesResult.Result);
            var entities = entitiesJson["results"]?["documents"]?[0]?["entities"]?.ToString();
            List<RestEntity> entitiesList = new();
            if(entitiesJson["results"]?["documents"]?[0]?["entities"]?.Count() > 0)
            {
                entitiesList.AddRange(from JObject entity in entitiesJson["results"]?["documents"]?[0]?["entities"]!
                                      let restEntity = new RestEntity
                                      {
                                          Text = entity["text"]?.ToString() ?? "N/A",
                                          Category = entity["category"]?.ToString() ?? "N/A",
                                          SubCategory = entity["subcategory"]?.ToString() ?? "N/A",
                                          ConfidenceScore = entity["confidenceScore"]?.ToString() ?? "N/A"
                                      }
                                      select restEntity);
            }
            else
            {
                Console.WriteLine("No entities were detected.");
                entitiesList = null;
            }

            ViewData["Entities"] = entitiesList;
            ViewData["EntitiesMethod"] = entitiesResult.Method;
            ViewData["EntitiesUri"] = entitiesResult.Uri;
            ViewData["EntitiesBody"] = JToken.Parse(entitiesResult.Body);
            ViewData["EntitiesResponse"] = entitiesJson;

            // Get linked entities
            RestResponse linkedEntitiesResult = await RestRequest(languageEndpoint, originalText, "EntityLinking");

            // Parse the JSON response and get the linked entities
            JObject linkedEntitiesJson = JObject.Parse(linkedEntitiesResult.Result);
            var linkedEntities = linkedEntitiesJson["results"]?["documents"]?[0]?["entities"]?.ToString();
            List<LinkedRestEntity> linkedEntitiesList = new();
            if(linkedEntitiesJson["results"]?["documents"]?[0]?["entities"]?.Count() > 0)
            {
                linkedEntitiesList.AddRange(from JObject linkedEntity in linkedEntitiesJson["results"]?["documents"]?[0]?["entities"]!
                                            let linkedRestEntity = new LinkedRestEntity
                                            {
                                                Name = linkedEntity["name"]?.ToString() ?? "N/A",
                                                Url = linkedEntity["url"]?.ToString() ?? "N/A"
                                            }
                                            select linkedRestEntity);
            }
            else
            {
                Console.WriteLine("No linked entities were detected.");
                linkedEntitiesList = null;
            }

            ViewData["LinkedEntities"] = linkedEntitiesList;
            ViewData["LinkedEntitiesMethod"] = linkedEntitiesResult.Method;
            ViewData["LinkedEntitiesUri"] = linkedEntitiesResult.Uri;
            ViewData["LinkedEntitiesBody"] = JToken.Parse(linkedEntitiesResult.Body);
            ViewData["LinkedEntitiesResponse"] = linkedEntitiesJson;
        }

        return Page();
    }
   
    public async Task<RestResponse> RestRequest(string endpoint, string originalText, string kind)
    {
        JObject jsonBody = new()
        {
            ["kind"] = $"{kind}",
            ["parameters"] = new JObject
            {
                ["modelVersion"] = "latest"
            },
            ["analysisInput"] = new JObject
            {
                ["documents"] = new JArray
                {
                    new JObject
                    {
                        ["id"] = "1",
                        ["text"] = originalText
                    }
                }
            }
        };
        var client = new HttpClient();
        var request = new HttpRequestMessage
        {
            Method = HttpMethod.Post,
            RequestUri = new Uri(endpoint),
            Content = new StringContent(jsonBody.ToString(), Encoding.UTF8, "application/json"),
            Headers = {
                { "Ocp-Apim-Subscription-Key", _cognitiveServicesKey },
            },
        };
        // Send the request and get the response
        HttpResponseMessage response = await client.SendAsync(request).ConfigureAwait(false);
        string result = await response.Content.ReadAsStringAsync();

        RestResponse restResponse = new()
        {
            Result = result,
            Method = request.Method.ToString(),
            Uri = request.RequestUri.ToString(),
            Body = request.Content.ReadAsStringAsync().Result.ToString()
        };

        return restResponse;
    }
    public class RestResponse
    {
        public string Result { get; set; }
        public string? Method { get; set; }
        public string? Uri { get; set; }
        public string? Body { get; set; }
    }
    public class RestEntity
    {
        public string Text { get; set; }
        public string Category { get; set; }
        public string SubCategory { get; set; }
        public string ConfidenceScore { get; set; }
    }
    public class LinkedRestEntity
    {
        public string Name { get; set; }
        public string Url { get; set; }
    }
}
