
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Azure;
using Azure.AI.TextAnalytics;

namespace AnalyseText.Pages;

public class IndexModel : PageModel
{
    private readonly IConfiguration _configuration;

    public IndexModel(IConfiguration configuration)
    {
        _configuration = configuration;
    }

    public IActionResult OnPostProcessInput(string InputText)
    {
        // Process the input text
        string originalText = InputText;

        // Set the original text to output
        Console.WriteLine($"Original text: \n{originalText}\n");
        ViewData["OriginalText"] = originalText;

        // Set up the Text Analytics client
        string cognitiveServicesEndpoint = _configuration.GetValue<string>("CognitiveServicesEndpoint") ?? "ENDPOINT NOT SET";
        string cognitiveServicesKey = _configuration.GetValue<string>("CognitiveServicesKey") ?? "KEY NOT SET";
        AzureKeyCredential credentials = new (cognitiveServicesKey);
        Uri endpoint = new(cognitiveServicesEndpoint);
        TextAnalyticsClient client = new(endpoint, credentials);

        // Get language
        DetectedLanguage language = client.DetectLanguage(originalText);
        Console.WriteLine($"Detected language: {language.Name}, with confidence score {language.ConfidenceScore}");

        // Set the language information to output
        ViewData["Language"] = language.Name;
        ViewData["LanguageConfidence"] = language.ConfidenceScore;

        // Get sentiment
        DocumentSentiment sentiment = client.AnalyzeSentiment(originalText);
        Console.WriteLine($"Sentiment: {sentiment.Sentiment}, with confidence scores: Positive={sentiment.ConfidenceScores.Positive:0.00}; Neutral={sentiment.ConfidenceScores.Neutral:0.00}; Negative={sentiment.ConfidenceScores.Negative:0.00}");

        // Set the sentiment information to output
        ViewData["Sentiment"] = sentiment.Sentiment;
        ViewData["SentimentPositive"] = sentiment.ConfidenceScores.Positive;
        ViewData["SentimentNeutral"] = sentiment.ConfidenceScores.Neutral;
        ViewData["SentimentNegative"] = sentiment.ConfidenceScores.Negative;

        // Get key phrases
        KeyPhraseCollection keyPhrases = client.ExtractKeyPhrases(originalText);
        string phrases = "";
        if(keyPhrases.Count > 0)
        {
            phrases = string.Join(", ", keyPhrases);
            Console.WriteLine($"Key phrases:");
            Console.WriteLine($" {phrases}");
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
            Console.WriteLine($"Entities:");
            foreach (CategorizedEntity entity in entities)
            {
                Console.WriteLine($"  Text: {entity.Text}, Category: {entity.Category}, SubCategory: {entity.SubCategory ?? "N/A"}, Confidence score: {entity.ConfidenceScore:0.00}");
                entitiesList.Add(entity);
            }
        }
        else
        {
            Console.WriteLine("No entities were detected.");
        }
        ViewData["Entities"] = entitiesList;

        // Get linked entities
        LinkedEntityCollection linkedEntities = client.RecognizeLinkedEntities(originalText);
        List<LinkedEntity> linkedEntitiesList = new();
        if(linkedEntities.Count > 0)
        {
            Console.WriteLine($"Linked entities:");
            foreach (LinkedEntity linkedEntity in linkedEntities)
            {
                Console.WriteLine($"  Name: {linkedEntity.Name}, Url: {linkedEntity.Url}");
                linkedEntitiesList.Add(linkedEntity);
            }
        }
        else
        {
            Console.WriteLine("No linked entities were detected.");
        }
        ViewData["LinkedEntities"] = linkedEntitiesList;

        return Page();
    }
}
